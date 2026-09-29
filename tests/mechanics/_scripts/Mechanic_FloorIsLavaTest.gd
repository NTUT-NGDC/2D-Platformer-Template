extends Node2D

# 手動驗證用：Mechanic_FloorIsLava 依 scope 決定只有岩漿地板扣血，還是所有地板都扣血
#（safe 除外）。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 預設 scope＝只有岩漿地板：走一般地板不會扣血，走到中間那塊岩漿才會扣血")
	print("[測試] 想測「所有地板」模式：把 Inspector 的 scope 切成「所有地板」再進場玩，")
	print("[測試] 這時候一般地板也會扣血，只有最右邊標記 safe 的那塊平台不會扣血")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
