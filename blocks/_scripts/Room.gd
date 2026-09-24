@tool
extends Area2D

# 房間：同一個場景裡切出一塊塊畫面大小的區域，玩家走進來時發出 Events.room_entered，
# 鏡頭與重生處理者訂閱它。碰撞框依格數自動產生，學員不用拉；節點原點 = 房間左上角。
# 想指定重生位置就在底下拖一個 Marker2D，沒放的話自動用「底部中央往上兩格」。

const _TILE_SIZE := 16
const _BORDER_COLOR := Color(0.35, 0.8, 1.0, 0.9)
const _SPAWN_COLOR := Color(1.0, 0.85, 0.2, 0.9)

@export_group("房間設定")
## 房間寬度，以格為單位（16px 一格，30 格 = 一個螢幕寬）
@export_range(16, 128) var width_in_tiles: int = 30:
	set(value):
		width_in_tiles = value
		_update_shape()
## 房間高度，以格為單位（17 格 ≈ 一個螢幕高，最下面半格會被畫面切掉）
@export_range(9, 64) var height_in_tiles: int = 17:
	set(value):
		height_in_tiles = value
		_update_shape()

# 目前玩家所在房間的 instance id；所有 Room 共用，用來避免重複發出 room_entered
static var _current_room_id: int = 0

var _collision: CollisionShape2D = null
var _player: Node2D = null

# 產生碰撞框；遊戲中設定只偵測玩家，並檢查重生點設定
func _ready() -> void:
	_ensure_collision()
	if Engine.is_editor_hint():
		child_entered_tree.connect(func(_n): queue_redraw())
		child_exiting_tree.connect(func(_n): queue_redraw())
		return
	collision_layer = 0       # 房間不需要被任何東西偵測到（子彈、近戰判定不會打到房間）
	collision_mask = 1 << 0   # 圖層 1「玩家」
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _count_markers() > 1:
		push_warning("[房間] %s 底下有不只一個 Marker2D，只會用第一個當重生點" % name)
		printerr("⚠ [房間] %s 底下有 %d 個 Marker2D，只會用第一個當重生點，其他的可以刪掉" % [name, _count_markers()])

# 回傳房間中心的全域座標，鏡頭切換用這個
func get_center() -> Vector2:
	return global_position + _get_size() / 2.0

# 回傳玩家在這個房間死掉時要回到的全域座標，重生處理者用這個
func get_spawn_point() -> Vector2:
	return to_global(_get_local_spawn_point())

# 回傳某個全域座標在不在這個房間範圍內，重生處理者找「房間裡的零件」用這個
func has_point(global_point: Vector2) -> bool:
	return Rect2(global_position, _get_size()).has_point(global_point)

# 玩家碰到房間邊界時開始追蹤；真正算「進入」要等玩家中心點跨進來
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body

# 玩家完全離開房間就停止追蹤
func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null

# 玩家中心點在房間內、而且目前記錄的房間不是自己時，宣告玩家進入這個房間。
# 用中心點判斷，玩家站在兩個房間交界來回走時，鏡頭才不會一直跳
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _player == null:
		return
	if _current_room_id == get_instance_id():
		return
	if not has_point(_player.global_position):
		return
	_current_room_id = get_instance_id()
	print("[房間] 玩家進入 %s" % name)
	Events.room_entered.emit(self)

# 房間的像素尺寸
func _get_size() -> Vector2:
	return Vector2(width_in_tiles, height_in_tiles) * _TILE_SIZE

# 重生點的區域座標：有 Marker2D 子節點就用它，沒有就用底部中央往上兩格
func _get_local_spawn_point() -> Vector2:
	for child in get_children():
		if child is Marker2D:
			return (child as Marker2D).position
	var size := _get_size()
	return Vector2(size.x / 2.0, size.y - _TILE_SIZE * 2)

# 數一下底下有幾個 Marker2D
func _count_markers() -> int:
	var count := 0
	for child in get_children():
		if child is Marker2D:
			count += 1
	return count

# 建立房間自己用的碰撞框節點（不存進場景檔，學員在場景樹裡看不到也改不到）
func _ensure_collision() -> void:
	if _collision != null:
		return
	_collision = CollisionShape2D.new()
	_collision.shape = RectangleShape2D.new()
	add_child(_collision, false, Node.INTERNAL_MODE_FRONT)
	_update_shape()

# 依格數更新碰撞框大小與位置，並重畫編輯器邊框
func _update_shape() -> void:
	queue_redraw()
	if _collision == null:
		return
	var size := _get_size()
	(_collision.shape as RectangleShape2D).size = size
	_collision.position = size / 2.0

# 編輯畫面持續重畫，Marker2D 被拖動時重生點標記才會跟著動
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：畫房間邊框、房間名稱、重生點標記
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var size := _get_size()
	draw_rect(Rect2(Vector2.ZERO, size), _BORDER_COLOR, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(4, 14), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, _BORDER_COLOR)
	var spawn := _get_local_spawn_point()
	draw_circle(spawn, 4.0, _SPAWN_COLOR)
	draw_string(ThemeDB.fallback_font, spawn + Vector2(6, -6), "重生點", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, _SPAWN_COLOR)
