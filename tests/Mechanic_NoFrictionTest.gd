extends Node2D

# 手動驗證用：Mechanic_NoFriction 放開方向鍵後依 remaining_friction 滑行，
# 滑行開始那一刻發出 Events.mechanic_event("Mechanic_NoFriction", "slide_start")。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 按著左右方向鍵跑一下再放開，角色應該像踩到冰面一樣繼續滑行，不會立刻停下")
	print("[測試] 放開按鍵、角色開始滑行的那一刻，應該印出一次 slide_start（不會每幀重複印）")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
