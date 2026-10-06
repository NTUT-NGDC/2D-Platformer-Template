@tool
extends JuiceBase

# 擠壓拉伸：觸發時角色壓扁（或拉長）一下，再彈回原本的樣子。拖進 Player → Juice 底下就能用，
# 預設是落地時壓扁。以腳底為中心變形，跟忽大忽小、重力翻轉這類卡一起用也不會互相蓋掉。

## 壓扁＝變矮變寬（適合落地）、拉長＝變高變瘦（適合起跳）
@export_enum("壓扁", "拉長") var shape: int = 0
## 變形的程度，數值越大變形越誇張
@export_range(0.05, 0.6) var strength: float = 0.3
## 多久彈回原本的樣子（秒）
@export_range(0.05, 0.6) var duration: float = 0.2

const _SHAPE_SQUASH := 0
# 變形程度上限，避免跟著落地力道放大後變成負的
const _MAX_AMOUNT := 0.8

var _amount: float = 0.0
var _time: float = 0.0

# 平常不用每幀更新，播放時才開
func _on_setup() -> void:
	set_process(false)

# 從最大變形開始，接下來每幀慢慢彈回去
func _on_play() -> void:
	_amount = minf(strength * _trigger_power, _MAX_AMOUNT)
	_time = 0.0
	set_process(true)
	_apply(_amount)

# 停掉播到一半的變形
func _on_reset() -> void:
	_time = duration
	set_process(false)

# 每幀依經過的時間算出現在的變形量，有一點點彈過頭再回正
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if _time >= duration:
		set_process(false)
		player.clear_juice(self)
		return
	var t := _time / duration
	_apply(_amount * (1.0 - t) * exp(-3.0 * t) * cos(t * PI * 1.5))

# 把變形量換成擠壓比例交給 Player：壓扁是寬 1 + a、高 1 - a，拉長反過來
func _apply(a: float) -> void:
	if not is_instance_valid(player):
		return
	if shape == _SHAPE_SQUASH:
		player.set_juice_squash(self, Vector2(1.0 + a, 1.0 - a))
	else:
		player.set_juice_squash(self, Vector2(1.0 - a, 1.0 + a))
