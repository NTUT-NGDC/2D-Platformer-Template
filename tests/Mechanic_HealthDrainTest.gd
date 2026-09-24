extends Node2D

# 手動驗證用：Mechanic_HealthDrain 每秒自動扣血，撿到金幣補血，血量歸零死亡重來。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 左上角血條應該每秒掉一點，不用做任何事就會持續扣血")
	print("[測試] 走到右邊撿金幣，血量應該補回來（撿到會印 Stats.value_changed）")
	print("[測試] 放著不管，血量歸零應該直接死亡，0.8 秒後在原地重生、血量補滿")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
