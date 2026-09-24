extends MechanicBase

# 彈性宇宙：撞到牆壁、天花板（或地板，看 floor_bounces）會反彈出去，不是撞到就停住。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 碰撞後反彈的速度保留比例，數值越大彈越高
@export_range(0.3, 1.5) var bounciness: float = 0.9

## 站在地板上時要不要也會彈起來
@export var floor_bounces: bool = true

# 反彈速度低於這個值就不再彈，不然速度會越彈越小、永遠在原地抖動
const _MIN_BOUNCE_SPEED := 40.0

# 撞牆反彈後，這段時間內暫時鎖住輸入，不然玩家還按著方向鍵朝牆的方向時，
# Player 自己的水平移動邏輯下一步就會把 velocity.x 直接蓋回「方向鍵 × 移動速度」，
# 剛加上去的反彈完全看不出來
const _WALL_BOUNCE_INPUT_LOCK := 0.15

var _last_velocity: Vector2 = Vector2.ZERO
var _was_touching_floor: bool = false
var _was_touching_other: bool = false
var _input_lock_left: float = 0.0

# CharacterBody2D 不吃 PhysicsMaterial 的彈性設定，只能自己判斷「這一刻是不是剛撞上」：
# 地板方向跟牆壁／天花板方向分開追蹤，只在剛接觸（前一幀還沒碰到）的那一刻才彈一次，
# 用撞上前量到的速度算反彈方向，用 add_impulse() 補上去；已經貼著不放開不會每幀重複觸發
func apply(ctx: MoveContext) -> void:
	var touching_floor := false
	var touching_other := false
	var floor_normal := Vector2.ZERO
	var other_normal := Vector2.ZERO
	for i in player.get_slide_collision_count():
		var normal: Vector2 = player.get_slide_collision(i).get_normal()
		if normal.dot(player.up_direction) > 0.7:
			touching_floor = true
			floor_normal = normal
		else:
			touching_other = true
			other_normal = normal

	if touching_floor and not _was_touching_floor and floor_bounces:
		_try_bounce(floor_normal)
	if touching_other and not _was_touching_other:
		if _try_bounce(other_normal):
			_input_lock_left = _WALL_BOUNCE_INPUT_LOCK

	_was_touching_floor = touching_floor
	_was_touching_other = touching_other
	_last_velocity = player.velocity

	if _input_lock_left > 0.0:
		_input_lock_left -= ctx.delta
		ctx.input_locked = true

# 重生時清掉上一條命留下的速度記錄與輸入鎖，避免一復活就被舊速度彈飛
func on_respawn() -> void:
	_last_velocity = Vector2.ZERO
	_was_touching_floor = false
	_was_touching_other = false
	_input_lock_left = 0.0

# 用撞上前量到的速度沿法線反彈，太慢就不彈；回傳有沒有真的彈成功
func _try_bounce(normal: Vector2) -> bool:
	if _last_velocity.length() < _MIN_BOUNCE_SPEED:
		return false
	var bounced := _last_velocity.bounce(normal) * bounciness
	player.add_impulse(bounced - player.velocity)
	Events.mechanic_event.emit("Mechanic_BouncyWorld", "bounced")
	return true
