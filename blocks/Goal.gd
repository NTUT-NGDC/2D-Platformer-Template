extends Area2D

# 終點：感應，玩家踩到時發出 reached，同步轉發 Events.level_cleared
#（重生記憶會訂閱這個事件清空所有記錄，見 autoload/RespawnMemory.gd）。
# 拖進場景就能用，不用連任何線。W1 玩具箱不使用這個。

## 踩到終點時發出，給學員自己接效果用（例如接特效或音效）
signal reached

var _cleared: bool = false

# 設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
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
