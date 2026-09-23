@tool
extends Area2D

# 終點：感應，玩家踩到時發出 reached，同步轉發 Events.level_cleared
#（重生記憶會訂閱這個事件清空所有記錄，見 autoload/RespawnMemory.gd）。
# 拖進場景就能用，不用連任何線。W1 玩具箱不使用這個。

## 踩到終點時發出，給學員自己接效果用（例如接特效或音效）
signal reached

const _SIGNAL_LINE_COLOR := Color(1.0, 0.85, 0.2, 0.85)

var _cleared: bool = false

# 設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	collision_layer = 1 << 4  # 圖層 5「感應」
	collision_mask = 1 << 0   # 圖層 1「玩家」
	body_entered.connect(_on_body_entered)

# 玩家踩到終點：發出訊號並轉發 Events.level_cleared，只算第一次
func _on_body_entered(body: Node) -> void:
	if _cleared or not body.is_in_group("player"):
		return
	_cleared = true
	reached.emit()
	Events.level_cleared.emit()

# 編輯畫面持續請求重畫，讓虛線跟著訊號連接的變化即時更新
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：幫這個零件自己發出的每個訊號的每條連接畫一條虛線到目標節點
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_draw_signal_lines(reached)

# 畫某個訊號目前所有連接的虛線
func _draw_signal_lines(sig: Signal) -> void:
	for conn in sig.get_connections():
		var callable: Callable = conn["callable"]
		var target: Object = callable.get_object()
		if target is Node2D:
			var target_node: Node2D = target
			draw_dashed_line(Vector2.ZERO, to_local(target_node.global_position), _SIGNAL_LINE_COLOR, 2.0, 6.0)
