extends MechanicBase

## 離地後還可以再跳幾次。
@export_range(1, 3) var extra_jumps: int = 1
## 二段跳的力道是一般跳躍的幾倍。
@export_range(0.5, 1.5) var power: float = 0.9

var _jumps_left: int = 0

# 每幀補滿在地上的跳躍次數，並偵測空中再次按跳躍鍵
func apply(_ctx: MoveContext) -> void:
	var on_ground: bool = player.is_on_ground()
	if on_ground:
		_jumps_left = extra_jumps
	elif _jumps_left > 0 and Input.is_action_just_pressed("jump"):
		_jumps_left -= 1
		player.force_jump(power)
