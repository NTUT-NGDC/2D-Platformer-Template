extends MechanicBase

# 只用後座力移動：鍵盤不能直接控制方向，按方向鍵是往反方向噴一下（後座力）；
# input_type 選滑鼠按鍵時，改成按滑鼠鍵往游標的反方向噴。
# 在地面上噴不限次數；在空中每次噴射消耗一次 air_charges，落地依 refill_on_land 決定
# 要不要補滿。拖進 Player → Mechanics 底下就能用，不用連任何線。

## 用方向鍵噴，還是按滑鼠鍵往游標的「反方向」噴
@export_enum("方向鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type: int = 0

## 每次噴射的力道大小
@export_range(100.0, 800.0) var recoil_strength: float = 350.0

## 落地前最多能噴射幾次
@export_range(1, 5) var air_charges: int = 3

## 著地時要不要把噴射次數補滿
@export var refill_on_land: bool = true

## 每次噴射之後，多久才能再噴一次
@export_range(0.1, 1.0) var cooldown: float = 0.3

## 噴射的那一刻發出，在推力之前（連到 Player 的 stop_motion 就是先歸零再噴）
signal fired
## 在空中已經沒有噴射次數、還按噴射鍵時發出
signal out_of_charges

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
var _pending_direction: Vector2 = Vector2.ZERO

# 套用一開始的噴射次數，向 InputRouter 註冊方向鍵或滑鼠鍵
func _on_setup() -> void:
	_charges_left = air_charges
	if input_type == 0:
		for action in _DIRECTIONS:
			InputRouter.bind(self, action, InputRouter.PRESSED, _on_direction_pressed.bind(action))
	else:
		InputRouter.bind_input(self, input_type, KEY_NONE, InputRouter.PRESSED, _on_mouse_pressed)

# 按下方向鍵：先記下要噴的方向，同一幀按的方向會疊加，等 apply() 再一次噴出去
func _on_direction_pressed(action: String) -> void:
	_pending_direction += _DIRECTIONS[action]

# 按下滑鼠鍵：記下游標的反方向，游標剛好在角色身上就不噴
func _on_mouse_pressed() -> void:
	_pending_direction += -Aim.toward_mouse(player, Vector2.ZERO)

# 鍵盤鎖住方向控制，把這一幀收到的噴射方向噴出去；落地時視 refill_on_land 補滿次數
func apply(ctx: MoveContext) -> void:
	ctx.input_locked = true

	var on_floor: bool = player.is_on_ground()
	if on_floor and not _was_on_floor and refill_on_land:
		_charges_left = air_charges
	_was_on_floor = on_floor

	if _cooldown_left > 0.0:
		_cooldown_left -= ctx.delta

	# 這一幀所有剛按下的方向已經疊加成一個向量，只噴射一次；不然同時按兩個方向鍵時，
	# 第一個方向噴射成功會立刻進入冷卻，同一幀第二個方向馬上被冷卻擋掉，吃不到斜角
	# （InputRouter 是自動載入，每一幀都比 Player 先派發輸入，所以這裡一定收得到）
	var combined := _pending_direction
	_pending_direction = Vector2.ZERO
	if combined != Vector2.ZERO:
		_try_fire(combined.normalized())

# 重生時噴射次數補滿、冷卻歸零、顏色還原
func on_respawn() -> void:
	_charges_left = air_charges
	_cooldown_left = 0.0
	_was_on_floor = true
	_pending_direction = Vector2.ZERO
	if player.visual:
		player.visual.modulate = Color.WHITE

# 冷卻中不生效；在空中沒有次數了就發出 recoil_empty 並閃灰提示；否則往反方向噴出去
func _try_fire(direction: Vector2) -> void:
	if _cooldown_left > 0.0:
		return
	var in_air: bool = not player.is_on_ground()
	if in_air and _charges_left <= 0:
		out_of_charges.emit()
		Events.mechanic_event.emit("Mechanic_RecoilMove", "recoil_empty")
		_flash_empty()
		return
	if in_air:
		_charges_left -= 1
	_cooldown_left = cooldown
	fired.emit()
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
