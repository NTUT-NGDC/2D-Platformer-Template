extends AnimatableBody2D

# Gym 專用的來回平台，在起點與偏移後的終點之間固定速度往返。
# 這不是機制卡，是關卡自己的道具，學員不會碰到這個腳本。

@export var offset: Vector2 = Vector2(150, 0)
@export var speed: float = 60.0

var _start_pos: Vector2
var _target_pos: Vector2
var _going_forward: bool = true

func _ready() -> void:
	_start_pos = position
	_target_pos = position + offset

func _physics_process(delta: float) -> void:
	var dest: Vector2 = _target_pos if _going_forward else _start_pos
	position = position.move_toward(dest, speed * delta)
	if position.distance_to(dest) < 1.0:
		_going_forward = not _going_forward
