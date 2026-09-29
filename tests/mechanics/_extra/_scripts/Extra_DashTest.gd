extends Node2D

# 手動驗證用：Extra_Dash 按鍵（預設 Shift）往目前方向瞬間衝出去，有冷卻時間。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 按著方向鍵，同時按 Shift 應該瞬間往那個方向衝出去")
	print("[測試] 站著不按方向鍵按 Shift，應該往目前面向的方向衝")
	print("[測試] 衝刺後短時間內再按 Shift 應該沒反應，要等冷卻結束才能再衝一次")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
