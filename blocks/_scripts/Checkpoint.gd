@tool
extends Area2D

# 重生點：感應，玩家踩到時發出 reached，同步轉發 Events.checkpoint_reached(self)
# 給重生記憶系統用。拖進場景就能用，不用連任何線。

## 踩過一次之後，再踩還會不會再發出 reached；關閉的話只有第一次踩到才算數
@export var repeatable: bool = false

## 踩到時發出，給學員自己接效果用（例如接特效或音效）
signal reached

const _SIGNAL_LINE_COLOR := Color(1.0, 0.85, 0.2, 0.85)

@onready var _visual: ColorRect = $Visual

var _touched: bool = false

# 設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	collision_layer = 1 << 4  # 圖層 5「感應」
	collision_mask = 1 << 0   # 圖層 1「玩家」
	body_entered.connect(_on_body_entered)

# 玩家踩到時發出訊號，並轉發給重生記憶系統；不可重複觸發時，踩過一次之後就不再發出
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _touched and not repeatable:
		return
	_touched = true
	_update_visual()
	reached.emit()
	Events.checkpoint_reached.emit(self)

# 踩過一次之後外觀保持「已啟用」的顏色，之後再踩也不會變回去
func _update_visual() -> void:
	_visual.color = Color(0.3, 0.85, 0.35) if _touched else Color(0.5, 0.55, 0.85)

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
