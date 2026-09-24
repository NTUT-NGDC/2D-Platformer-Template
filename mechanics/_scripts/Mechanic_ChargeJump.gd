extends MechanicBase

# 蓄力青蛙跳：按住跳躍鍵蓄力，放開時依蓄力時間決定跳多高。手感參考 Jump King。
# 用比 Player 預設跳躍更高的優先權攔截跳躍鍵，攔截到之後 Player 自己的跳躍完全不會生效。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 最多可以蓄力幾秒
@export_range(0.2, 2.0) var max_charge_seconds: float = 1.0

## 完全沒蓄力時，跳躍力是滿力的多少倍
@export_range(0.3, 1.0) var min_jump_ratio: float = 0.4

## 蓄力的時候要不要禁止左右移動
@export var lock_move_while_charging: bool = true

const _PRIORITY := 100

## 是不是正在蓄力，外部（例如停下即死卡）可以讀這個決定要不要暫停自己的邏輯
var is_charging: bool = false

var _charge_seconds: float = 0.0

# 用比 Player 高的優先權攔截跳躍鍵的三個時機
func _on_setup() -> void:
	InputRouter.bind(self, "jump", InputRouter.PRESSED, _on_pressed, _PRIORITY)
	InputRouter.bind(self, "jump", InputRouter.HELD, _on_held, _PRIORITY)
	InputRouter.bind(self, "jump", InputRouter.RELEASED, _on_released, _PRIORITY)

# 蓄力的時候，lock_move_while_charging 開啟才鎖住左右移動，不影響跳躍鍵本身
func apply(ctx: MoveContext) -> void:
	if is_charging and lock_move_while_charging:
		ctx.input_locked = true

# 重生時取消蓄力中的狀態
func on_respawn() -> void:
	is_charging = false
	_charge_seconds = 0.0

# 按下跳躍鍵：站在地面上才開始蓄力，回傳 true 讓 Player 自己的跳躍不會再收到這次按鍵
func _on_pressed() -> bool:
	if not player.is_on_ground():
		return false
	is_charging = true
	_charge_seconds = 0.0
	Events.mechanic_event.emit("Mechanic_ChargeJump", "charge_start")
	return true

# 按著跳躍鍵：持續累積蓄力時間，夾在 max_charge_seconds 以內
func _on_held(seconds: float) -> bool:
	if not is_charging:
		return false
	_charge_seconds = minf(seconds, max_charge_seconds)
	return true

# 放開跳躍鍵：依蓄力比例算出跳躍力道，真正跳出去
func _on_released(_seconds: float) -> bool:
	if not is_charging:
		return false
	is_charging = false
	var charge_ratio := _charge_seconds / max_charge_seconds
	var power := lerpf(min_jump_ratio, 1.0, charge_ratio)
	player.force_jump(power)
	Events.mechanic_event.emit("Mechanic_ChargeJump", "charge_release")
	return true
