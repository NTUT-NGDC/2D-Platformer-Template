extends Node2D

# 手動驗證用：Mechanic_BouncyWorld 撞牆／落地會反彈，速度太小時停止彈跳不會永遠抖動。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 角色一開始在半空中，應該掉下去撞到地板彈起來，一次比一次彈得低，")
	print("[測試] 最後穩穩停在地板上，不會永遠在原地抖動")
	print("[測試] 往左右邊牆壁跑過去撞撞看，應該會被反彈回來，不是直接卡住不動")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
