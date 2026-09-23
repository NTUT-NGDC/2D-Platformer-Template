extends MechanicBase

# 純靠踩怪起飛：一般跳躍完全失效（跳躍力歸零），只能往下踩中敵人反彈起跳，同時對
# 敵人造成傷害。給想挑戰的老手，備品庫卡，不在抽卡池裡，學員許願才拖給他。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 踩中敵人時往上彈的力道
@export_range(200.0, 800.0) var bounce_force: float = 400.0

## 踩中敵人造成的傷害
@export_range(1, 10) var stomp_damage: int = 1

## 要判定成「踩到」，玩家下墜速度至少要多快
@export_range(20.0, 200.0) var min_fall_speed: float = 40.0

const _SENSOR_MASK := 1 << 3  # 圖層4「敵人」
const _SENSOR_SIZE := Vector2(16, 32)

var _sensor: Area2D = null

# 建立貼著玩家的偵測 Area2D 抓敵人的接觸（敵人不在玩家的碰撞遮罩內，
# move_and_slide 偵測不到，做法同 Mechanic_TouchDeath）
func _on_setup() -> void:
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = _SENSOR_MASK
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _SENSOR_SIZE
	shape.shape = rect
	_sensor.add_child(shape)
	add_child(_sensor)
	_sensor.body_entered.connect(_on_sensor_body_entered)

# 一般跳躍完全失效
func apply(ctx: MoveContext) -> void:
	ctx.jump_scale = 0.0

# 碰到敵人：要正在快速下墜、而且人在敵人上方，才算踩中——反彈起跳、對敵人造成傷害
func _on_sensor_body_entered(body: Node) -> void:
	if not body.is_in_group("enemy") or not (body is Node2D):
		return
	var fall_speed: float = player.velocity.dot(-player.up_direction)
	if fall_speed < min_fall_speed:
		return
	var enemy: Node2D = body
	if player.up_direction.dot(player.global_position - enemy.global_position) <= 0.0:
		return
	var current_up_speed: float = player.velocity.dot(player.up_direction)
	player.add_impulse(player.up_direction * (bounce_force - current_up_speed))
	if enemy.has_method("take_hit"):
		enemy.take_hit(stomp_damage, Vector2.ZERO, player)
	Events.mechanic_event.emit("Extra_StompOnly", "stomped")
