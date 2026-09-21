extends Camera2D

# 接 Events.shake_requested，執行螢幕震動。
# 固定視角，不跟隨玩家：掛在關卡場景根節點底下，跟 Player 是平行關係
# （見 levels/_shared/LevelBase.tscn，Gym.tscn 與 _Template.tscn 皆繼承自此）。
# 每個關卡如果要對準不同的可視範圍，改這個節點的 position，不要改成跟隨玩家。

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0

func _ready() -> void:
	Events.shake_requested.connect(_on_shake_requested)

func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = maxf(duration, 0.0001)
	_shake_time_left = duration

func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var falloff: float = _shake_time_left / _shake_duration
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * falloff
