extends Node2D

# 手動驗證用：Mechanic_StopDeath 靜止超過 max_idle_seconds 依 penalty_mode 死亡或扣血；
# 跟蓄力青蛙跳一起掛時，蓄力中應該暫停計時。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] max_idle_seconds 設成 2 秒，站著不動應該先閃紅警告，超時直接死亡重來")
	print("[測試] 移動或跳躍會重新計時；按住跳躍鍵蓄力（蓄力青蛙跳）的時候站著不動")
	print("[測試] 不應該觸發停下即死——這是兩張卡的自動處理")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
