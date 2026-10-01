extends Camera2D

# 接 Events.shake_requested，執行螢幕震動；接 Events.room_entered，依鏡頭模式處理換房間。
# 掛在關卡場景根節點底下，跟 Player 是平行關係。
# 鏡頭模式：
# - 瞬切：玩家進哪個房間，鏡頭就直接跳到那個房間中心，沒有平滑移動；場景裡沒有 Room 時維持原本擺的位置不動。
# - 房間內跟隨：跟著玩家跑，但畫面不會超出目前的房間；房間比畫面小的那一軸固定在房間中心，換房間時瞬切。
#   場景裡沒有 Room 時就是一般的跟著玩家跑。
# - 自由跟隨：忽略房間，一直跟著玩家跑（例如展示間那種一路橫向走的長場地）。
# 震動是疊加在鏡頭位置上的偏移（offset），不會改到鏡頭位置。

## 鏡頭模式：瞬切（每個房間一個固定畫面）、房間內跟隨（跟著玩家但不超出房間）、自由跟隨（不管房間，一直跟著玩家）
@export_enum("瞬切", "房間內跟隨", "自由跟隨") var mode: int = 0

const _MODE_SNAP := 0
const _MODE_ROOM_FOLLOW := 1
const _MODE_FREE_FOLLOW := 2

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0
var _follow_target: Node2D = null
var _room: Node = null

# 接上震動、房間、重生訊號；跟隨模式才開平滑，瞬切模式不平滑
func _ready() -> void:
	Events.shake_requested.connect(_on_shake_requested)
	Events.room_entered.connect(_on_room_entered)
	Events.player_respawned.connect(_on_player_respawned)
	position_smoothing_enabled = mode != _MODE_SNAP

# 玩家進入房間：記下目前房間；瞬切模式跳到房間中心，房間內跟隨模式換成這個房間的範圍並瞬間到位，自由跟隨不理會
func _on_room_entered(room: Node) -> void:
	_room = room
	if mode == _MODE_FREE_FOLLOW:
		return
	if mode == _MODE_SNAP:
		global_position = room.get_center()
	else:
		_follow_player()
	reset_smoothing()

# 玩家重生：跟隨模式直接跳到玩家身上，不要從死掉的地方一路滑過去
func _on_player_respawned(_player: Node) -> void:
	if mode == _MODE_SNAP:
		return
	_follow_player()
	reset_smoothing()

# 接到震動請求，記下強度與持續時間
func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = maxf(duration, 0.0001)
	_shake_time_left = duration

# 每幀更新跟隨與震動偏移
func _process(delta: float) -> void:
	if mode != _MODE_SNAP:
		_follow_player()

	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var falloff: float = _shake_time_left / _shake_duration
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * falloff

# 找到玩家並讓鏡頭跟著它（房間內跟隨模式再限制在房間範圍內），找不到（還沒進場）就下一幀再試
func _follow_player() -> void:
	if not is_instance_valid(_follow_target):
		_follow_target = get_tree().get_first_node_in_group("player")
		if _follow_target == null:
			return
	var target := _follow_target.global_position
	if mode == _MODE_ROOM_FOLLOW and is_instance_valid(_room):
		target = _clamp_to_room(target, _room.get_rect())
	global_position = target

# 把鏡頭中心限制在房間裡，讓畫面不超出房間；房間比畫面小的那一軸固定在房間中心
func _clamp_to_room(target: Vector2, room_rect: Rect2) -> Vector2:
	var half_view := get_viewport_rect().size / zoom / 2.0
	var result := target
	for axis in [0, 1]:
		var low: float = room_rect.position[axis] + half_view[axis]
		var high: float = room_rect.end[axis] - half_view[axis]
		if low >= high:
			result[axis] = room_rect.get_center()[axis]
		else:
			result[axis] = clampf(target[axis], low, high)
	return result
