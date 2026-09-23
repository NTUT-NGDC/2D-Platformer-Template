extends Area2D

# 重生點：感應，玩家踩到時發出 reached，同步轉發 Events.checkpoint_reached(self)
# 給重生記憶系統用。拖進場景就能用，不用連任何線。

## 踩過一次之後，再踩還會不會再發出 reached；關閉的話只有第一次踩到才算數
@export var repeatable: bool = false

## 踩到時發出，給學員自己接效果用（例如接特效或音效）
signal reached

@onready var _visual: ColorRect = $Visual

var _touched: bool = false

# 設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
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
