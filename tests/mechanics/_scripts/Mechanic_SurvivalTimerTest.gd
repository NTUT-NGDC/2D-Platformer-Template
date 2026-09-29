extends Node2D

# 手動驗證用：Mechanic_SurvivalTimer 存活到 target_seconds 秒會轉發 Events.level_cleared。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	Events.level_cleared.connect(_on_level_cleared)
	print("[測試] target_seconds 設成 5 秒，右上角倒數計時應該邊跑邊減")
	print("[測試] 倒數到 0 應該印出 Events.level_cleared，不用刻意做任何事，等就好")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])

func _on_level_cleared() -> void:
	print("[測試] Events.level_cleared 已觸發")
