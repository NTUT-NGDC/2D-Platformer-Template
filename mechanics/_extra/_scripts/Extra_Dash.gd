extends MechanicBase

# 衝刺：按下衝刺鍵（鍵盤或滑鼠）往目前輸入方向（沒按方向鍵就往面向方向）瞬間衝出去，衝刺中重力歸零、
# 速度固定不受摩擦力影響。備品庫卡，不在抽卡池裡，學員許願才拖給他。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 用鍵盤按鍵還是滑鼠按鍵衝刺
@export_enum("鍵盤按鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type: int = 0

## 按哪一鍵衝刺（「按鍵種類」選鍵盤按鍵時才會顯示這一欄）
@export var key: Key = KEY_SHIFT

## 衝刺的速度
@export_range(200.0, 1000.0) var dash_speed: float = 500.0

## 衝刺可以持續多久
@export_range(0.05, 0.5) var dash_duration: float = 0.15

## 衝刺之間的冷卻時間
@export_range(0.2, 3.0) var cooldown: float = 1.0

const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

var _dash_time_left: float = 0.0
var _cooldown_left: float = 0.0
var _facing: int = 1
var _dash_dir: int = 1

# 選滑鼠按鍵時隱藏 key 欄位
func _validate_property(property: Dictionary) -> void:
	if property.name == "key" and input_type != 0:
		property.usage = PROPERTY_USAGE_NONE

# 綁衝刺鍵、記住角色面向方向（沒按方向鍵時要往這個方向衝）
func _on_setup() -> void:
	if input_type == 0:
		_warn_if_dangerous_key(key)
	InputRouter.bind_input(self, input_type, key, InputRouter.PRESSED, _on_key_pressed)
	player.direction_changed.connect(func(dir: int): _facing = dir)

# 衝刺中：固定速度往 _dash_dir 方向移動、重力歸零，不受摩擦力影響
func apply(ctx: MoveContext) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= ctx.delta
	if _dash_time_left <= 0.0:
		return
	_dash_time_left -= ctx.delta
	ctx.auto_run_dir = _dash_dir
	ctx.speed_scale = dash_speed / player.move_speed
	ctx.gravity_scale = 0.0

# 冷卻中或正在衝刺就不處理；否則往目前輸入方向（沒按方向鍵就往面向方向）衝出去
func _on_key_pressed() -> bool:
	if _cooldown_left > 0.0 or _dash_time_left > 0.0:
		return false
	var input_dir: float = player.get_move_input()
	_dash_dir = int(sign(input_dir)) if input_dir != 0.0 else _facing
	_dash_time_left = dash_duration
	_cooldown_left = cooldown
	Events.mechanic_event.emit("Extra_Dash", "dashed")
	return true

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[衝刺] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
