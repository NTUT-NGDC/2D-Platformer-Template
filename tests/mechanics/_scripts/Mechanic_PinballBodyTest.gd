extends Node2D

# 手動驗證用：Mechanic_PinballBody 碰到敵人／尖刺不受傷，反而被彈開，有短暫無敵時間。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 血量目前：%d/%d" % [Stats.get_value(Stats.HEALTH_KIND), Stats.get_max_value(Stats.HEALTH_KIND)])
	print("[測試] 走到 Enemy_Target（被兩面牆夾住）身上撞一下：應該被彈開，血量不會減少")
	print("[測試] 走到 Spike_Target（扣血模式，不是即死）上面：應該被彈開，血量一樣不會減少")
	print("[測試] 被彈開後的 0.3 秒內，就算還黏在對方旁邊也不會連續再彈一次")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s（血量：%d/%d）" % [
		card, event, Stats.get_value(Stats.HEALTH_KIND), Stats.get_max_value(Stats.HEALTH_KIND)
	])
