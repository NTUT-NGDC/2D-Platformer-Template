extends Node2D

# 手動驗證用：Mechanic_GravityFlip 按 Shift 翻轉重力，角色視覺同步上下翻，有冷卻時間。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 按 Shift：重力應該立刻反過來，角色開始往天花板掉，貼圖也會上下翻轉")
	print("[測試] 落到天花板上之後再按一次 Shift：重力翻回來，角色掉回地板")
	print("[測試] 冷卻 0.3 秒內連按應該只有第一下生效")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
