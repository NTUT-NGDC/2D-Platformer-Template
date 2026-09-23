extends Node2D

# 彈射台：實心，碰到會把玩家（或箱子）往指定方向彈出去。彈簧是固定彈出速度；
# 彈跳床依撞擊速度反彈，撞得越用力彈得越高，但最高不會超過 force。
# 拖進場景就能用，不用連任何線。

## 模式：彈簧（固定力道彈出）、彈跳床（依撞擊速度反彈）
@export_enum("彈簧", "彈跳床") var mode: int = 0

## 彈出的方向：上、左、右
@export_enum("上", "左", "右") var direction: int = 0

## 力道：彈簧是固定的彈出速度，彈跳床是彈出速度的上限
@export_range(100.0, 900.0) var force: float = 500.0

## 彈出時發出，帶被彈出的物件，給學員自己接特效／音效用
signal launched(body: Node)

const _MODE_SPRING := 0
const _DIRECTIONS := [Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
const _MIN_BOUNCE_RATIO := 0.5

@onready var _shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _detector: Area2D = $Detector

# 設定碰撞層／遮罩，只偵測玩家跟箱子
func _ready() -> void:
	add_to_group("signal_source")
	_detector.collision_layer = 0
	_detector.collision_mask = (1 << 0) | (1 << 2)  # 圖層 1「玩家」、圖層 3「箱子」
	_detector.body_entered.connect(_on_detector_entered)

# 有東西碰到：依模式算出彈出速度，把對方在彈出方向上的速度直接設成這個值
func _on_detector_entered(body: Node) -> void:
	if not body.has_method("add_impulse"):
		return
	var dir: Vector2 = _DIRECTIONS[direction]
	var current: Vector2 = body.get("velocity") if body.get("velocity") is Vector2 else Vector2.ZERO
	var launch_speed := force
	if mode != _MODE_SPRING:
		var impact_speed: float = maxf(current.dot(-dir), 0.0)
		launch_speed = clampf(impact_speed, force * _MIN_BOUNCE_RATIO, force)
	var current_along: float = current.dot(dir)
	body.add_impulse(dir * (launch_speed - current_along))
	launched.emit(body)
