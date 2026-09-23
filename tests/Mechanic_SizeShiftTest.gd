extends Node2D

# 手動驗證用：Mechanic_SizeShift 按 Shift 在小／大體型間切換，變大時卡進低矮天花板
# 會延後套用，走出來後才真的變大；跳躍高度應該隨體型改變。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 角色一開始很小，站在左邊的低矮通道裡")
	print("[測試] 按 Shift：因為頭上是低矮天花板，應該先維持小的狀態，不會卡進天花板")
	print("[測試] 往右走出通道到開闊區域，應該看到角色自動變大（不用再按一次 Shift）")
	print("[測試] 在開闊區域再按一次 Shift 縮小、跳一下，比較大跟小的跳躍高度差異")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
