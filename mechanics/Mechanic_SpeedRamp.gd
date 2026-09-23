extends MechanicBase

# 越跑越快：持續移動的時間越長，速度倍率越高，最多加到 max_multiplier 倍。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 速度最多可以加到原本的幾倍
@export_range(1.0, 5.0) var max_multiplier: float = 3.0

## 從最低速加到最高倍率要花幾秒
@export_range(1.0, 20.0) var ramp_seconds: float = 10.0

## 目前的速度倍率會讓跳躍力增加多少，0 表示跳躍不受影響
@export_range(0.0, 1.0) var speed_affects_jump: float = 0.5

## 停下來時倍率要不要歸零重新累積
@export var reset_on_stop: bool = true

const _NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const _MAX_SPEED_COLOR := Color(1.0, 0.4, 0.2)

var _multiplier: float = 1.0
var _reached_max: bool = false

# 用實際水平速度判斷有沒有在動（不直接讀輸入），這樣搭配任何主限制卡都成立；
# 持續移動就累加倍率，停下來依 reset_on_stop 決定要不要歸零
func apply(ctx: MoveContext) -> void:
	var is_moving := not is_zero_approx(player.velocity.x)
	if is_moving:
		var rate := (max_multiplier - 1.0) / ramp_seconds
		_multiplier = minf(_multiplier + rate * ctx.delta, max_multiplier)
		if _multiplier >= max_multiplier and not _reached_max:
			_reached_max = true
			Events.mechanic_event.emit("Mechanic_SpeedRamp", "speed_max")
	elif reset_on_stop:
		if _multiplier > 1.0:
			Events.mechanic_event.emit("Mechanic_SpeedRamp", "speed_reset")
		_multiplier = 1.0
		_reached_max = false

	ctx.speed_scale = _multiplier
	ctx.jump_scale = 1.0 + (_multiplier - 1.0) * speed_affects_jump
	_sync_visual()

# 角色貼圖顏色依目前倍率從正常色漸變成偏紅，越快越紅，不用看數字也感覺得出差異
func _sync_visual() -> void:
	if not player.visual:
		return
	var ratio := (_multiplier - 1.0) / maxf(max_multiplier - 1.0, 0.001)
	player.visual.modulate = _NORMAL_COLOR.lerp(_MAX_SPEED_COLOR, ratio)
