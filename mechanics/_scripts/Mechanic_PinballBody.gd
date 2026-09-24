extends MechanicBase

# 彈珠台體質：碰到敵人或尖刺／岩漿不會受傷，反而會像彈珠一樣被彈開。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 碰到敵人或尖刺時被彈開的力道
@export_range(300.0, 1500.0) var knock_force: float = 800.0

## 碰到敵人時要不要被擊飛
@export var enemy_knocks: bool = true

## 碰到尖刺、岩漿時要不要被擊飛
@export var hazard_knocks: bool = true

## 被擊飛後幾秒內不會被同一次碰撞連續觸發
@export_range(0.1, 1.0) var invincible_seconds: float = 0.3

const _SENSOR_SIZE := Vector2(20.0, 36.0)

var _sensor: Area2D
var _invincible_left: float = 0.0

# 建立一個貼著玩家身體的感應區，偵測敵人（實體碰撞）跟尖刺／岩漿（感應區）
func _on_setup() -> void:
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = (1 << 3) | (1 << 4)  # 圖層 4「敵人」、圖層 5「感應」
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _SENSOR_SIZE
	shape.shape = rect
	_sensor.add_child(shape)
	add_child(_sensor)
	_sensor.body_entered.connect(_on_sensor_entered)
	_sensor.area_entered.connect(_on_sensor_entered)

# 每幀把傷害歸零，並倒數無敵時間
func apply(ctx: MoveContext) -> void:
	ctx.damage_scale = 0.0
	if _invincible_left > 0.0:
		_invincible_left -= ctx.delta

# 重生時無敵時間歸零
func on_respawn() -> void:
	_invincible_left = 0.0

# 碰到敵人或尖刺／岩漿：依開關決定要不要彈開
func _on_sensor_entered(other: Node) -> void:
	if _invincible_left > 0.0:
		return
	var is_enemy := other.is_in_group("enemy")
	var is_hazard := other.is_in_group("hazard")
	if (is_enemy and enemy_knocks) or (is_hazard and hazard_knocks):
		_knock_away(other)

# 沿著「從對方指向玩家」的方向加一點向上偏移，把玩家彈開
func _knock_away(other: Node) -> void:
	var away: Vector2 = player.global_position - other.global_position
	if away.length() < 1.0:
		away = Vector2.UP
	var direction := (away.normalized() + Vector2.UP * 0.5).normalized()
	player.add_impulse(direction * knock_force)
	_invincible_left = invincible_seconds
	Events.mechanic_event.emit("Mechanic_PinballBody", "knocked")
