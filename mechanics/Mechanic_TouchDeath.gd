extends MechanicBase

# 碰觸即死：碰到敵人／箱子／垂直牆面就死，三種各自可以獨立開關。
# 敵人（圖層4）、箱子（圖層3）都在玩家的碰撞遮罩之外（玩家推得動箱子，但
# move_and_slide 不會回報箱子或敵人的碰撞），所以另外用一個貼著玩家的 Area2D
# 偵測；牆是地形（圖層2），本來就在玩家的碰撞遮罩內，直接用碰撞法線方向判斷。
# 尖刺、岩漿這類感應類機關本來就能各自設成「即死」，不用這張卡額外處理。
# 全部直接呼叫 kill()，不受彈珠台體質的傷害歸零影響。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 碰到 group enemy 的物件會不會死
@export var die_on_enemy: bool = true

## 碰到 group box 的物件會不會死
@export var die_on_box: bool = true

## 碰到 group wall 的物件會不會死
@export var die_on_wall: bool = false

# normal 跟 up_direction 的內積絕對值小於這個值，才算「垂直面」（牆），不是地板或天花板
const _WALL_NORMAL_LIMIT := 0.5
const _SENSOR_MASK := (1 << 2) | (1 << 3)  # 圖層3「箱子」、圖層4「敵人」
const _SENSOR_SIZE := Vector2(16, 32)

var _sensor: Area2D = null

# 建立貼著玩家的偵測 Area2D，抓敵人／箱子的接觸（牆用 apply() 裡的碰撞法線判斷）
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

# 敵人／箱子碰到玩家：依對應開關決定要不要直接殺死
func _on_sensor_body_entered(body: Node) -> void:
	if die_on_enemy and body.is_in_group("enemy"):
		_kill()
	elif die_on_box and body.is_in_group("box"):
		_kill()

# die_on_wall 開啟時，掃這一幀的物理碰撞找垂直牆面
func apply(_ctx: MoveContext) -> void:
	if not die_on_wall:
		return
	for i in player.get_slide_collision_count():
		var col: KinematicCollision2D = player.get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider is Node and ((collider as Node).is_in_group("enemy") or (collider as Node).is_in_group("box")):
			continue
		if absf(col.get_normal().dot(player.up_direction)) < _WALL_NORMAL_LIMIT:
			_kill()
			return

# 直接殺死玩家並發出事件，不走 take_damage()，所以不受傷害倍率影響
func _kill() -> void:
	player.kill()
	Events.mechanic_event.emit("Mechanic_TouchDeath", "touched")
