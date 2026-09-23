extends MechanicBase

# 只能用滑鼠控制：鍵盤完全鎖住，只能用滑鼠左鍵拖曳瞄準，像彈弓一樣放開往反方向射出去。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 拖到最遠時發射的力道上限
@export_range(200.0, 1200.0) var max_launch_force: float = 700.0

## 拖曳超過這個距離，力道就不會再增加
@export_range(50.0, 300.0) var max_drag_distance: float = 150.0

## 開啟後只有站在地面上才能開始拖曳瞄準
@export var ground_only: bool = true

## 拖曳時要不要畫出瞄準線
@export var show_aim_line: bool = true

var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _aim_line: Line2D

# show_aim_line 開啟時，自己生成一條瞄準線，學員不用擺
func _on_setup() -> void:
	if not show_aim_line:
		return
	_aim_line = Line2D.new()
	_aim_line.width = 2.0
	_aim_line.default_color = Color(1.0, 1.0, 1.0, 0.8)
	_aim_line.visible = false
	add_child(_aim_line)

# 鍵盤全鎖住；按住滑鼠左鍵開始拖曳（ground_only 開啟時要先站在地面上），
# 拖曳中同步更新瞄準線，放開滑鼠左鍵才真的發射
func apply(ctx: MoveContext) -> void:
	ctx.input_locked = true

	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if pressed and not _dragging:
		if ground_only and not player.is_on_ground():
			return
		_dragging = true
		_drag_start = player.get_global_mouse_position()
	elif not pressed and _dragging:
		_release()

	if _dragging and _aim_line:
		var drag: Vector2 = player.get_global_mouse_position() - _drag_start
		drag = drag.limit_length(max_drag_distance)
		_aim_line.visible = true
		_aim_line.points = PackedVector2Array([Vector2.ZERO, -drag])

# 放開滑鼠：往拖曳的反方向發射，力道依拖曳距離比例縮放
func _release() -> void:
	_dragging = false
	if _aim_line:
		_aim_line.visible = false
	var drag: Vector2 = player.get_global_mouse_position() - _drag_start
	drag = drag.limit_length(max_drag_distance)
	var ratio := drag.length() / max_drag_distance
	if ratio <= 0.0:
		return
	var direction := -drag.normalized()
	player.add_impulse(direction * max_launch_force * ratio)
	Events.mechanic_event.emit("Mechanic_Slingshot", "launched")
