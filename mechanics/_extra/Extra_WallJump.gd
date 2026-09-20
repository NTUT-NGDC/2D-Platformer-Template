extends MechanicBase

## 蹬牆跳的力道，跟一般跳躍力的比例。
@export_range(0.5, 1.5) var power: float = 1.0
## 蹬牆時往牆的反方向推開多強。
@export_range(100.0, 600.0) var push_strength: float = 300.0

# 撞牆時按跳躍鍵，就往牆的反方向跳開
func apply(_ctx: MoveContext) -> void:
	if player.is_on_wall() and Input.is_action_just_pressed("jump"):
		var wall_normal: Vector2 = player.get_wall_normal()
		player.force_jump(power)
		player.add_impulse(wall_normal * push_strength)
