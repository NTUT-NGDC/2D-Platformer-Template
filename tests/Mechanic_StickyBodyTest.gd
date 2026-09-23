extends Node2D

# 手動驗證用：Mechanic_StickyBody 碰到任何表面就黏住不放、按跳躍鍵才能脫離；
# 黏在移動平台上要跟著移動。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 角色一落地就會直接黏在地板上、不能用方向鍵移動——這是設計好的行為")
	print("[測試] 按跳躍鍵脫離黏著（會往上噴一下），趁還在半空中時按方向鍵，才能一路「跳」過去")
	print("[測試] 往左邊跳過去撞牆，應該會黏在牆上；往上跳頂到天花板，應該也會黏住")
	print("[測試] 一路跳到右邊藍色的移動平台上，黏住之後角色應該跟著平台一起來回移動，")
	print("[測試] 不會被滑掉或穿過去")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
