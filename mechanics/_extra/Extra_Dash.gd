extends MechanicBase

## 衝刺瞬間噴出的速度。
@export_range(200.0, 1000.0) var strength: float = 500.0
## 兩次衝刺之間至少要間隔幾秒。
@export_range(0.2, 2.0) var delay: float = 0.8

var _cooldown_left: float = 0.0

# 計時冷卻，並偵測互動鍵按下時往目前面向的方向衝刺
func apply(ctx: MoveContext) -> void:
	_cooldown_left = maxf(_cooldown_left - ctx.delta, 0.0)
	if _cooldown_left > 0.0 or not Input.is_action_just_pressed("interact"):
		return
	var input_dir: float = player.get_move_input()
	var dash_dir: float = signf(input_dir) if input_dir != 0.0 else 1.0
	player.add_impulse(Vector2(dash_dir * strength, 0.0))
	_cooldown_left = delay
