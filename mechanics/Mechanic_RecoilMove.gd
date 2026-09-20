extends MechanicBase

## 每次點擊滑鼠左鍵，往反方向噴出的力道大小。
@export_range(100.0, 800.0) var strength: float = 350.0
## 兩次噴射之間至少要間隔幾秒，避免連點洗力道。
@export_range(0.1, 1.0) var delay: float = 0.3

var _cooldown_left: float = 0.0

# 鎖住方向鍵輸入，只計時冷卻，真正的推力在點擊時觸發
func apply(ctx: MoveContext) -> void:
	ctx.input_locked = true
	_cooldown_left = maxf(_cooldown_left - ctx.delta, 0.0)

# 偵測滑鼠左鍵點擊，往點擊位置的反方向噴出衝量
func _unhandled_input(event: InputEvent) -> void:
	if not enabled or player == null or _cooldown_left > 0.0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = player.get_global_mouse_position()
		var away_dir: Vector2 = (player.global_position - click_pos).normalized()
		if away_dir == Vector2.ZERO:
			away_dir = Vector2.UP
		player.add_impulse(away_dir * strength)
		_cooldown_left = delay
