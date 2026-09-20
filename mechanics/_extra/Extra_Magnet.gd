extends MechanicBase

## 磁力吸附範圍半徑。
@export_range(50.0, 400.0) var radius: float = 200.0
## 吸附的力道大小。
@export_range(50.0, 500.0) var strength: float = 200.0

# 找出範圍內所有 box 群組的物件，往玩家方向施加拉力
func apply(_ctx: MoveContext) -> void:
	for box in get_tree().get_nodes_in_group("box"):
		if not (box is RigidBody2D):
			continue
		var to_player: Vector2 = player.global_position - box.global_position
		var dist: float = to_player.length()
		if dist > radius or dist < 1.0:
			continue
		box.apply_central_force(to_player.normalized() * strength)
