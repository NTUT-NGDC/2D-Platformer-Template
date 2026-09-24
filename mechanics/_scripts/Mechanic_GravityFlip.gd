extends MechanicBase

# 重力翻轉：依觸發時機翻轉重力方向，角色視覺同步上下翻轉。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 什麼時候會翻轉重力
@export_enum("按下按鍵", "落地時", "撞牆時") var trigger_timing: int = 0

## 按下按鍵時用鍵盤按鍵還是滑鼠按鍵（只有「觸發時機」選按下按鍵時才會顯示這一欄）
@export_enum("鍵盤按鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type: int = 0

## 按下按鍵時要按哪一鍵翻轉（「觸發時機」選按下按鍵、「按鍵種類」選鍵盤按鍵時才會顯示這一欄）
@export var key: Key = KEY_SHIFT

## 翻轉之後多久內不能再翻轉
@export_range(0.1, 1.0) var cooldown: float = 0.3

const _TRIGGER_KEY := 0
const _TRIGGER_LAND := 1
const _TRIGGER_WALL := 2

const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

var _cooldown_left: float = 0.0

# 依 trigger_timing 決定要不要顯示按鍵欄位；選滑鼠按鍵時也隱藏 key 欄位
func _validate_property(property: Dictionary) -> void:
	if property.name == "input_type" and trigger_timing != _TRIGGER_KEY:
		property.usage = PROPERTY_USAGE_NONE
	elif property.name == "key" and (trigger_timing != _TRIGGER_KEY or input_type != 0):
		property.usage = PROPERTY_USAGE_NONE

# 依觸發時機接對應的按鍵或 Player 訊號
func _on_setup() -> void:
	match trigger_timing:
		_TRIGGER_KEY:
			if input_type == 0:
				_warn_if_dangerous_key(key)
			InputRouter.bind_input(self, input_type, key, InputRouter.PRESSED, _try_flip)
		_TRIGGER_LAND:
			player.landed.connect(func(_impact_force): _try_flip())
		_TRIGGER_WALL:
			player.wall_hit.connect(_try_flip)

# 每幀倒數冷卻
func apply(ctx: MoveContext) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= ctx.delta

# 冷卻中不生效，否則翻轉重力、同步視覺上下翻轉、進入冷卻、發出 flipped 事件
func _try_flip() -> void:
	if _cooldown_left > 0.0:
		return
	player.flip_gravity()
	if player.visual:
		player.visual.scale.y *= -1
	_cooldown_left = cooldown
	Events.mechanic_event.emit("Mechanic_GravityFlip", "flipped")

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[重力翻轉] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
