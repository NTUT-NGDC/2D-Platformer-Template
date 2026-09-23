extends Camera2D

# 接 Events.shake_requested，執行螢幕震動。
# 預設固定視角，不跟隨玩家：掛在關卡場景根節點底下，跟 Player 是平行關係
# （見 levels/_shared/LevelBase.tscn，Gym.tscn 與 _Template.tscn 皆繼承自此）。
# 大部分關卡如果要對準不同的可視範圍，改這個節點的 position，不用開跟隨。
# 需要跟隨玩家的關卡（例如場地比一個畫面寬很多）才把 follow_player 打開。

## 開啟後鏡頭會跟著玩家跑，不開就維持原本固定不動的視角
@export var follow_player: bool = false

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0
var _follow_target: Node2D = null

func _ready() -> void:
	Events.shake_requested.connect(_on_shake_requested)
	if follow_player:
		position_smoothing_enabled = true

func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = maxf(duration, 0.0001)
	_shake_time_left = duration

func _process(delta: float) -> void:
	if follow_player:
		_follow_player()

	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var falloff: float = _shake_time_left / _shake_duration
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * falloff

# 找到玩家並讓鏡頭黏著它，找不到（還沒進場）就下一幀再試
func _follow_player() -> void:
	if _follow_target == null:
		_follow_target = get_tree().get_first_node_in_group("player")
		if _follow_target == null:
			return
	global_position = _follow_target.global_position
