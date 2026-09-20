extends Camera2D

# 接 Events.shake_requested，執行螢幕震動。
# 垂直高度鎖死，只在水平方向緩慢跟隨玩家，避免跳躍時畫面上下抽動。
# 按住滑鼠右鍵拖曳可以自由平移鏡頭（左鍵留給後座力移動卡用），一旦拖曳過就切換成手動模式，不再自動跟隨。
# 掛在關卡場景裡（見 Gym.tscn / _Template.tscn），跟 Player 沒有父子關係。

## 水平自動跟隨的平滑速度，數字愈大跟得愈緊。
@export var follow_speed: float = 3.0

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_time_left: float = 0.0
var _dragging: bool = false
var _manual_mode: bool = false

func _ready() -> void:
	Events.shake_requested.connect(_on_shake_requested)

func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = maxf(duration, 0.0001)
	_shake_time_left = duration

# 偵測滑鼠右鍵拖曳，用來手動平移鏡頭
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging = event.pressed
		if event.pressed:
			_manual_mode = true
	elif event is InputEventMouseMotion and _dragging:
		position.x -= event.relative.x / zoom.x
		position.y -= event.relative.y / zoom.y

# 沒有進入手動模式時，水平方向緩慢跟隨玩家；同時處理螢幕震動
func _process(delta: float) -> void:
	if not _manual_mode:
		var target := _find_player()
		if target:
			position.x = lerpf(position.x, target.global_position.x, clampf(follow_speed * delta, 0.0, 1.0))
	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = maxf(_shake_time_left - delta, 0.0)
	var falloff: float = _shake_time_left / _shake_duration
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * falloff

# 找到場景裡的玩家節點
func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null
