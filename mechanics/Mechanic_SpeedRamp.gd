extends MechanicBase

## 加速到最後，速度會變成原本的幾倍。
@export_range(1.0, 5.0) var max_speed: float = 3.0
## 從 1 倍加速到最高倍率，總共要花幾秒。
@export_range(1.0, 20.0) var ramp_time: float = 10.0
## 開啟時，角色一停下來速度倍率就會歸零重算。
@export var reset_on_stop: bool = true

var _elapsed: float = 0.0

# 依移動累積時間計算目前的速度倍率
func apply(ctx: MoveContext) -> void:
	var moving: bool = absf(player.get_move_input()) > 0.01 or ctx.auto_run_dir != 0
	if moving:
		_elapsed = minf(_elapsed + ctx.delta, ramp_time)
	elif reset_on_stop:
		_elapsed = 0.0
	ctx.speed_scale = lerpf(1.0, max_speed, _elapsed / ramp_time)
