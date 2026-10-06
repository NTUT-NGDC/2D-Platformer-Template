@tool
extends JuiceBase

# 螢幕震動：觸發時整個畫面晃一下。拖進 Player → Juice 底下就能用，預設是落地時震動。

## 震動幅度（像素），數值越大畫面晃得越大
@export_range(1.0, 16.0) var strength: float = 3.0
## 震動持續多久（秒）
@export_range(0.05, 1.0) var duration: float = 0.2

# 請鏡頭震動一次，落地時勾選「跟著落地力道」的話幅度會跟著變
func _on_play() -> void:
	Events.shake_requested.emit(strength * _trigger_power, duration)
