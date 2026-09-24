extends MechanicBase

# 只用後座力移動：鍵盤不能直接控制方向，按方向鍵是往反方向噴一下（後座力）。
# 在地面上噴不限次數；在空中每次噴射消耗一次 air_charges，落地依 refill_on_land 決定
# 要不要補滿。拖進 Player → Mechanics 底下就能用，不用連任何線。

## 每次噴射的力道大小
@export_range(100.0, 800.0) var recoil_strength: float = 350.0

## 落地前最多能噴射幾次
@export_range(1, 5) var air_charges: int = 3

## 著地時要不要把噴射次數補滿
@export var refill_on_land: bool = true

## 每次噴射之後，多久才能再噴一次
@export_range(0.1, 1.0) var cooldown: float = 0.3

# 方向鍵對應噴射方向的「反方向」
const _DIRECTIONS := {
	"move_up": Vector2.DOWN,
	"move_down": Vector2.UP,
	"move_left": Vector2.RIGHT,
	"move_right": Vector2.LEFT,
}
const _FLASH_DURATION := 0.15

var _charges_left: int = 0
var _cooldown_left: float = 0.0
var _was_on_floor: bool = true

# 套用一開始的噴射次數
func _on_setup() -> void:
	_charges_left = air_charges

# 鍵盤鎖住方向控制，改成偵測四個方向鍵的按下瞬間；落地時視 refill_on_land 補滿次數
func apply(ctx: MoveContext) -> void:
	ctx.input_locked = true

	var on_floor: bool = player.is_on_ground()
	if on_floor and not _was_on_floor and refill_on_land:
		_charges_left = air_charges
	_was_on_floor = on_floor

	if _cooldown_left > 0.0:
		_cooldown_left -= ctx.delta

	# 先收集這一幀所有剛按下的方向疊加成一個向量，只噴射一次；不然同時按兩個方向鍵時，
	# 第一個方向噴射成功會立刻進入冷卻，同一幀第二個方向的呼叫馬上被冷卻擋掉，吃不到斜角
	var combined := Vector2.ZERO
	for action in _DIRECTIONS:
		if Input.is_action_just_pressed(action):
			combined += _DIRECTIONS[action]
	if combined != Vector2.ZERO:
		_try_fire(combined.normalized())

# 冷卻中不生效；在空中沒有次數了就發出 recoil_empty 並閃灰提示；否則往反方向噴出去
func _try_fire(direction: Vector2) -> void:
	if _cooldown_left > 0.0:
		return
	var in_air: bool = not player.is_on_ground()
	if in_air and _charges_left <= 0:
		Events.mechanic_event.emit("Mechanic_RecoilMove", "recoil_empty")
		_flash_empty()
		return
	if in_air:
		_charges_left -= 1
	_cooldown_left = cooldown
	player.add_impulse(direction * recoil_strength)
	Events.mechanic_event.emit("Mechanic_RecoilMove", "recoil_fired")

# 次數用完時短暫閃灰提示
func _flash_empty() -> void:
	if not player.visual:
		return
	player.visual.modulate = Color(0.5, 0.5, 0.5)
	get_tree().create_timer(_FLASH_DURATION).timeout.connect(func():
		if is_instance_valid(player) and player.visual:
			player.visual.modulate = Color.WHITE
	)
