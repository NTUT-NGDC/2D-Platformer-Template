extends MechanicBase

## 什麼時候要翻轉重力。
@export_enum("按下按鍵", "落地時", "撞牆時") var trigger: int = 0
## 兩次翻轉之間至少要間隔幾秒，避免連續翻轉頭暈。
@export_range(0.1, 1.0) var delay: float = 0.3

var _cooldown_left: float = 0.0

# 依觸發時機接對應的訊號
func _on_setup() -> void:
	match trigger:
		1:
			player.landed.connect(func(_f): _try_flip())
		2:
			player.wall_hit.connect(_try_flip)

# 每幀計時冷卻，並在「按下按鍵」模式下偵測輸入
func apply(ctx: MoveContext) -> void:
	_cooldown_left = maxf(_cooldown_left - ctx.delta, 0.0)
	if trigger == 0 and Input.is_action_just_pressed("interact"):
		_try_flip()

# 翻轉重力，並讓視覺節點同步上下翻面
func _try_flip() -> void:
	if not enabled or _cooldown_left > 0.0:
		return
	player.flip_gravity()
	if player.visual:
		player.visual.scale.y *= -1
	_cooldown_left = delay
