extends MechanicBase

# 黏黏身體：碰到任何表面（地板、牆壁，天花板依 ceiling_sticks）就黏住不放，重力歸零、
# 輸入鎖住；按跳躍鍵可以脫離。黏在會動的平台上會跟著平台一起移動。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 最多可以黏著幾秒，0 表示不限時間
@export_range(0.0, 5.0) var max_stick_seconds: float = 0.0

## 按跳躍脫離黏著時的力道
@export_range(200.0, 1000.0) var release_force: float = 500.0

## 天花板要不要也能黏住
@export var ceiling_sticks: bool = true

const _JUMP_PRIORITY := 100
const _RELEASE_COOLDOWN := 0.2
const _UP_BIAS := 0.3

# 跟哪些卡同時掛上會互相抵銷，key 是對方腳本路徑，value 是要印的中文說明
const _CONFLICT_SCRIPTS := {
	"res://mechanics/Mechanic_AutoRun.gd": "「只能往前」還在，黏住期間會暫停自動奔跑",
	"res://mechanics/Mechanic_BouncyWorld.gd": "「彈性宇宙」還在，黏黏身體優先，黏住期間不會反彈",
}

## 是不是正在黏著，外部可以讀這個決定要不要暫停自己的邏輯
var is_stuck: bool = false

var _stick_seconds: float = 0.0
var _release_cooldown_left: float = 0.0
var _stuck_normal: Vector2 = Vector2.ZERO
var _stuck_collider: Node2D = null
var _stuck_offset: Vector2 = Vector2.ZERO

# 綁跳躍鍵的攔截、檢查場上有沒有會打架的卡
func _on_setup() -> void:
	InputRouter.bind(self, "jump", InputRouter.PRESSED, _on_jump_pressed, _JUMP_PRIORITY)
	_warn_conflicts()

# 還沒黏住就檢查這一幀有沒有新的表面可以黏；已經黏住就跟著黏住的東西走、算逾時
func apply(ctx: MoveContext) -> void:
	if _release_cooldown_left > 0.0:
		_release_cooldown_left -= ctx.delta

	if is_stuck:
		_apply_stuck(ctx)
		return

	if _release_cooldown_left <= 0.0:
		_check_stick()

# 黏著中：凍結重力與輸入、跟著黏住的物體移動、逾時自動脫落
func _apply_stuck(ctx: MoveContext) -> void:
	ctx.gravity_scale = 0.0
	ctx.input_locked = true
	ctx.movement_frozen = true

	if _stuck_collider != null:
		if not is_instance_valid(_stuck_collider):
			_release(false)
			return
		player.global_position = _stuck_collider.global_position + _stuck_offset

	if max_stick_seconds > 0.0:
		_stick_seconds += ctx.delta
		if _stick_seconds >= max_stick_seconds:
			_release(false)

# 掃這一幀碰到的表面，找到第一個可以黏的就黏上去
func _check_stick() -> void:
	for i in player.get_slide_collision_count():
		var col: KinematicCollision2D = player.get_slide_collision(i)
		var normal: Vector2 = col.get_normal()
		if not ceiling_sticks and normal.dot(player.up_direction) < -0.7:
			continue
		_stick_to(col.get_collider(), normal)
		return

# 黏上一個表面：記法線、記碰撞物跟相對位置（要跟著它一起移動），速度交給 ctx 凍結
func _stick_to(collider: Object, normal: Vector2) -> void:
	is_stuck = true
	_stuck_normal = normal
	_stick_seconds = 0.0
	if collider is Node2D:
		_stuck_collider = collider
		_stuck_offset = player.global_position - collider.global_position
	else:
		_stuck_collider = null
	Events.mechanic_event.emit("Mechanic_StickyBody", "stuck")

# 按跳躍鍵脫離黏著：沒黏著就不處理，讓 Player 自己的跳躍照常運作
func _on_jump_pressed() -> bool:
	if not is_stuck:
		return false
	_release(true)
	return true

# 脫離黏著：with_impulse 為 true 時往法線加一點向上偏移噴出去，逾時自動脫落則不噴
func _release(with_impulse: bool) -> void:
	if with_impulse:
		var dir: Vector2 = (_stuck_normal + player.up_direction * _UP_BIAS).normalized()
		player.add_impulse(dir * release_force)
		Events.mechanic_event.emit("Mechanic_StickyBody", "released")
	is_stuck = false
	_stuck_collider = null
	_stick_seconds = 0.0
	_release_cooldown_left = _RELEASE_COOLDOWN

# 檢查場上有沒有「只能往前」「彈性宇宙」，有的話印中文警告說明會怎麼互相影響
func _warn_conflicts() -> void:
	if not player.has_node("Mechanics"):
		return
	for child in player.get_node("Mechanics").get_children():
		var script: Script = child.get_script()
		if script == null:
			continue
		if _CONFLICT_SCRIPTS.has(script.resource_path):
			push_warning("[黏黏身體] 組合衝突：%s" % _CONFLICT_SCRIPTS[script.resource_path])
