extends Node2D

# 手動驗證用：Extra_TimeSlow 按鍵（預設 Q）讓世界慢下來幾秒，時間到自動恢復正常。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 按 Q 應該讓整個畫面（包含玩家自己的動作）慢下來，2 秒後自動恢復正常速度")
	print("[測試] 子彈時間進行中再按 Q 應該沒反應，要等結束才能再觸發一次")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
