@tool
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
const _SIGNAL_LINE_COLOR := Color(1.0, 0.85, 0.2, 0.85)

@onready var _shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _detector: Area2D = $Detector

# 設定碰撞層／遮罩，只偵測玩家跟箱子
func _ready() -> void:
	if Engine.is_editor_hint():
		return
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

# 編輯畫面持續請求重畫，讓虛線跟著訊號連接的變化即時更新
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：幫這個零件自己發出的每個訊號的每條連接畫一條虛線到目標節點
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_draw_signal_lines(launched)

# 畫某個訊號目前所有連接的虛線
func _draw_signal_lines(sig: Signal) -> void:
	for conn in sig.get_connections():
		var callable: Callable = conn["callable"]
		var target: Object = callable.get_object()
		if target is Node2D:
			var target_node: Node2D = target
			draw_dashed_line(Vector2.ZERO, to_local(target_node.global_position), _SIGNAL_LINE_COLOR, 2.0, 6.0)
