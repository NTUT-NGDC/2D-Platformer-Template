extends MechanicBase

## 按住跳躍鍵最多可以蓄力幾秒，超過就視為蓄滿。
@export_range(0.2, 2.0) var max_charge: float = 1.0
## 完全沒蓄力就放開時，至少會跳多高（跳躍力的比例）。
@export_range(0.3, 1.0) var min_power: float = 0.4
## 開啟時，蓄力過程中角色不能左右移動。
@export var lock_move: bool = true

var _charging: float = 0.0

# 接管跳躍輸入：按住蓄力、放開時依蓄力長短跳躍
func apply(ctx: MoveContext) -> void:
	ctx.jump_locked = true
	if not player.is_on_ground():
		_charging = 0.0
		return
	if Input.is_action_pressed("jump"):
		_charging = minf(_charging + ctx.delta, max_charge)
		if lock_move:
			ctx.input_locked = true
	if Input.is_action_just_released("jump"):
		var power: float = lerpf(min_power, 1.0, _charging / max_charge)
		player.force_jump(power)
		_charging = 0.0
