extends Camera2D

# 接 Events.shake_requested，執行螢幕震動；接 Events.room_entered，瞬間切到房間中心。
# 掛在關卡場景根節點底下，跟 Player 是平行關係。
# 場景裡有 Room 時：玩家進哪個房間，鏡頭就直接跳到那個房間中心，沒有平滑移動。
# 場景裡沒有 Room 時：維持這個節點原本擺的位置不動；follow_player 打開的話改成跟著玩家跑
#（只當沒有房間時的備用，例如展示間那種一路橫向走的長場地）。
# 震動是疊加在鏡頭位置上的偏移（offset），不會改到房間中心。

## 場景裡沒有任何房間時，鏡頭要不要跟著玩家跑；有房間時一律以房間為準，這個設定不生效
@export var follow_player: bool = false

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0
var _follow_target: Node2D = null
var _has_room: bool = false

# 接上震動與房間訊號；只有跟隨模式才開平滑，房間切換要瞬切
func _ready() -> void:
	Events.shake_requested.connect(_on_shake_requested)
	Events.room_entered.connect(_on_room_entered)
	if follow_player:
		position_smoothing_enabled = true

# 玩家進入房間：直接把鏡頭放到房間中心，不做任何平滑。第一次進房間時順便關掉跟隨
func _on_room_entered(room: Node) -> void:
	if not _has_room:
		_has_room = true
		if follow_player:
			print("[鏡頭] 場景裡有房間，follow_player 不生效，改成跟著房間切換")
		position_smoothing_enabled = false
	global_position = room.get_center()
	reset_smoothing()

# 接到震動請求，記下強度與持續時間
func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = maxf(duration, 0.0001)
	_shake_time_left = duration

# 每幀更新跟隨與震動偏移
func _process(delta: float) -> void:
	if follow_player and not _has_room:
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
