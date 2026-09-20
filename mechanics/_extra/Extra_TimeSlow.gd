extends MechanicBase

## 按下按鍵時，子彈時間持續幾秒（實際會被系統上限鎖在 0.3 秒內）。
@export_range(0.1, 0.3) var duration: float = 0.3
## 兩次子彈時間之間至少要間隔幾秒。
@export_range(0.3, 3.0) var delay: float = 1.0

var _cooldown_left: float = 0.0

# 計時冷卻，按下互動鍵時透過 HitStopManager 觸發一次頓幀式子彈時間
func apply(ctx: MoveContext) -> void:
	_cooldown_left = maxf(_cooldown_left - ctx.delta, 0.0)
	if _cooldown_left <= 0.0 and Input.is_action_just_pressed("interact"):
		Events.hitstop_requested.emit(duration)
		_cooldown_left = delay
