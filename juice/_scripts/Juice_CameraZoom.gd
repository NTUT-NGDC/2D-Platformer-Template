@tool
extends JuiceBase

# 鏡頭推近：觸發時鏡頭快速放大再慢慢回到原本大小，畫面往玩家偏一點。拖進 Player → Juice 底下就能用，
# 預設是打倒敵人時推近。房間內跟隨模式下，推近時畫面也不會露出房間外。

## 放大多少，0.25 是放大到 1.25 倍
@export_range(0.05, 1.0) var strength: float = 0.25
## 整段推近再回來要多久（秒）
@export_range(0.1, 1.5) var duration: float = 0.4

# 請鏡頭推近一次，落地時勾選「跟著落地力道」的話放大程度會跟著變
func _on_play() -> void:
	Events.zoom_requested.emit(strength * _trigger_power, duration)
