extends Node2D

# 手動驗證用：Mechanic_SpeedRamp 持續移動速度會越來越快、跳越來越高，停下來會歸零重來。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 這裡設定 ramp_seconds=3，方便快速測：往一個方向持續按著方向鍵跑滿 3 秒，")
	print("[測試] 應該感覺到角色越跑越快，中途跳一下應該比剛起步時跳得更高")
	print("[測試] 跑滿 3 秒應該印出 speed_max（達到最高倍率 3 倍）")
	print("[測試] 放開方向鍵讓角色停下來，應該印出 speed_reset，再跑一次應該又要重新加速")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
