extends Node2D

# 手動驗證用：Extra_DoubleJump 離地後可以再按一次跳躍鍵在空中多跳一次，落地補滿次數。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 跳起來之後在空中再按一次跳躍鍵，應該可以再跳一次（二段跳）")
	print("[測試] 落地後再跳應該又能二段跳一次，不會因為用過一次就沒了")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
