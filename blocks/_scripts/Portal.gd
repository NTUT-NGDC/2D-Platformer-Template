@tool
extends Area2D
class_name Portal

# 傳送門：感應，站進去會被傳到配對的另一座。pair 是設定用的節點欄位，不是訊號連接，
# 只要在其中一座指定另一座，另一座會自動連回來，學員只需要接一邊。
# 見 documents/01c_blocks_and_abilities.md §1、§2.1。

## 另一座傳送門，只要指定其中一座，另一座會自動連回來
@export var pair: NodePath = ^""

## 傳送時要不要保留原本的速度方向與大小；關掉的話落地時速度會歸零
@export var keep_velocity: bool = true

## 箱子要不要也能被這座傳送門傳送
@export var allow_boxes: bool = false

## 傳送時發出，帶被傳送的物件，給學員自己接特效／音效用
signal teleported(body: Node)

const _COOLDOWN := 0.3
const _SIGNAL_LINE_COLOR := Color(1.0, 0.85, 0.2, 0.85)

var _pair_portal: Portal = null
var _cooldown_until: Dictionary = {}  # body(Node) -> 時間戳，避免傳送過去立刻被傳回來

# 場景一進樹就解析 pair 節點路徑，並互相補上配對，搶在雙方的 _ready() 檢查之前完成
func _enter_tree() -> void:
	if pair.is_empty():
		return
	var target := get_node_or_null(pair) as Portal
	if target == null:
		return
	_pair_portal = target
	if target._pair_portal == null:
		target._pair_portal = self

# 設定碰撞層／遮罩，箱子要不要能傳依 allow_boxes 決定
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	collision_layer = 1 << 4  # 圖層 5「感應」
	collision_mask = (1 << 0) | ((1 << 2) if allow_boxes else 0)  # 圖層 1「玩家」+ 圖層 3「箱子」（可選）
	body_entered.connect(_on_body_entered)
	if _pair_portal == null:
		var message := "「%s」沒有設定配對的傳送門，不會傳送任何東西，請在 Inspector 指定 pair" % name
		push_warning("[傳送門] %s" % message)
		printerr("⚠ [傳送門] %s" % message)

# 判斷這個 body 算不算「傳得動」：玩家一定行，箱子看 allow_boxes
func _is_valid(body: Node) -> bool:
	if body.is_in_group("player"):
		return true
	return allow_boxes and body.is_in_group("box")

# 有東西站進來：傳到配對的另一座，0.3 秒內不會再次觸發（不管是這座還是另一座）
func _on_body_entered(body: Node) -> void:
	if _pair_portal == null or not _is_valid(body):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _cooldown_until.get(body, 0.0) > now:
		return
	body.global_position = _pair_portal.global_position
	if body is CharacterBody2D and not keep_velocity:
		body.velocity = Vector2.ZERO
	var until := now + _COOLDOWN
	_cooldown_until[body] = until
	_pair_portal._cooldown_until[body] = until
	teleported.emit(body)

# 編輯畫面持續請求重畫，讓虛線跟著訊號連接的變化即時更新
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：幫這個零件自己發出的每個訊號的每條連接畫一條虛線到目標節點
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_draw_signal_lines(teleported)

# 畫某個訊號目前所有連接的虛線
func _draw_signal_lines(sig: Signal) -> void:
	for conn in sig.get_connections():
		var callable: Callable = conn["callable"]
		var target: Object = callable.get_object()
		if target is Node2D:
			var target_node: Node2D = target
			draw_dashed_line(Vector2.ZERO, to_local(target_node.global_position), _SIGNAL_LINE_COLOR, 2.0, 6.0)
