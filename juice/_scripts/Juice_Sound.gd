@tool
extends JuiceBase

# 音效：觸發時播放一個音效。拖進 Player → Juice 底下就能用，預設是跳躍時播跳躍聲。
# 想用自己的音檔：sound 選「自訂」，把音檔（.wav／.ogg／.mp3，建議放在 _my/ 底下）從檔案系統拖進 custom_sound。
# 音效不受頓幀影響，頓幀時照常播完。

## 要播哪一種內建音效；選「自訂」可以放自己的音檔
@export_enum("跳躍", "落地", "受傷", "爆炸", "撿東西", "金幣", "雷射", "嗶", "自訂") var sound: int = 0:
	set(value):
		sound = value
		notify_property_list_changed()
		update_configuration_warnings()
## 自己的音檔：從檔案系統把 .wav／.ogg／.mp3 拖進來
@export var custom_sound: AudioStream = null:
	set(value):
		custom_sound = value
		update_configuration_warnings()
## 音量，1 是原本的大小
@export_range(0.0, 1.0) var volume: float = 0.8
## 每次播放時音高隨機變化的程度，0 是每次都一樣；有一點變化連續播才不會覺得很機械
@export_range(0.0, 0.5) var pitch_random: float = 0.1

const _SOUND_CUSTOM := 8
const _SOUNDS := [
	preload("res://sfx/jump.wav"),
	preload("res://sfx/land.wav"),
	preload("res://sfx/hurt.wav"),
	preload("res://sfx/explosion.wav"),
	preload("res://sfx/pickup.wav"),
	preload("res://sfx/coin.wav"),
	preload("res://sfx/laser.wav"),
	preload("res://sfx/beep.wav"),
]
# 同一個組件最多同時疊幾個聲音（連續觸發時前一個還沒播完）
const _MAX_OVERLAP := 4

var _audio: AudioStreamPlayer = null

# 建立播放器、決定要播哪個音效；選「自訂」卻沒放音檔就警告並改播跳躍聲
func _on_setup() -> void:
	if _audio == null:
		_audio = AudioStreamPlayer.new()
		_audio.max_polyphony = _MAX_OVERLAP
		add_child(_audio)
	if sound == _SOUND_CUSTOM and custom_sound == null:
		push_warning("[%s] sound 選了「自訂」，但 custom_sound 是空的，請把音檔拖進來；先改播跳躍聲" % name)
		printerr("⚠ [%s] sound 選了「自訂」，但 custom_sound 是空的，請把音檔拖進來；先改播跳躍聲" % name)
	_audio.stream = _get_stream()

# 播放一次，音量照設定、音高隨機變化一點
func _on_play() -> void:
	_audio.volume_db = linear_to_db(maxf(volume * minf(_trigger_power, 1.5), 0.0001))
	_audio.pitch_scale = 1.0 + randf_range(-pitch_random, pitch_random)
	_audio.play()

# 停掉還在播的聲音
func _on_reset() -> void:
	if _audio:
		_audio.stop()

# 回傳要播的音效：自訂而且有放音檔就用學員的，否則用內建的（自訂但空白時用跳躍聲）
func _get_stream() -> AudioStream:
	if sound == _SOUND_CUSTOM:
		return custom_sound if custom_sound else _SOUNDS[0]
	return _SOUNDS[sound]

# 只有選「自訂」時才顯示 custom_sound
func _validate_property(property: Dictionary) -> void:
	super(property)
	if property.name == "custom_sound" and sound != _SOUND_CUSTOM:
		property.usage &= ~PROPERTY_USAGE_EDITOR

# 編輯器裡就看得到設定錯誤：選了「自訂」卻沒放音檔
func _get_configuration_warnings() -> PackedStringArray:
	if sound == _SOUND_CUSTOM and custom_sound == null:
		return PackedStringArray(["sound 選了「自訂」，但 custom_sound 是空的，請把音檔從檔案系統拖進來；沒放之前先播跳躍聲"])
	return PackedStringArray()
