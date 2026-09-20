extends MechanicBase

## 靜止不動最多可以撐幾秒。
@export_range(0.5, 5.0) var duration: float = 1.5
## 逾時之後怎麼懲罰角色。
@export_enum("直接死亡", "持續扣血") var penalty: int = 0
## 開啟時，快要逾時前角色會閃紅色警告。
@export var show_warning: bool = true

const WARNING_LEAD_TIME := 0.6
const DAMAGE_PER_SEC := 1.0

var _idle_time: float = 0.0
var _flash_time: float = 0.0

# 偵測角色是不是靜止在地面上，逾時就依懲罰方式處理
func apply(ctx: MoveContext) -> void:
	var moving: bool = absf(player.velocity.x) > 5.0 or not player.is_on_ground()
	if moving:
		_idle_time = 0.0
		_reset_flash()
		return
	_idle_time += ctx.delta
	var remaining: float = duration - _idle_time
	if show_warning and remaining <= WARNING_LEAD_TIME:
		_flash_time += ctx.delta
		if player.visual:
			player.visual.modulate = Color.RED if fmod(_flash_time, 0.2) < 0.1 else Color.WHITE
	if remaining <= 0.0:
		if penalty == 0:
			player.kill()
			_idle_time = 0.0
		else:
			player.take_damage(DAMAGE_PER_SEC * ctx.delta)

# 角色一動起來就把警告閃爍效果復原
func _reset_flash() -> void:
	_flash_time = 0.0
	if player.visual:
		player.visual.modulate = Color.WHITE
