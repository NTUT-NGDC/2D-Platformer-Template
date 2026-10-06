@tool
extends JuiceBase

# 頓幀：觸發時整個遊戲停頓一下，讓打擊更有力。拖進 Player → Juice 底下就能用，預設是打中東西時頓幀。
# 實際改時間的是 HitStopManager，同一時間只會有一個頓幀，不會疊在一起越停越久。

## 停頓多久（秒），數值越大打擊感越重，太長會覺得卡卡的
@export_range(0.03, 0.3) var duration: float = 0.08

# 請求頓幀一次，落地時勾選「跟著落地力道」的話停頓長度會跟著變
func _on_play() -> void:
	Events.hitstop_requested.emit(duration * _trigger_power)
