extends MechanicBase

# 煞車失靈：放開方向鍵後角色不會立刻停下來，會依 remaining_friction 慢慢滑行。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 放開方向鍵後還剩多少摩擦力，0 表示完全不減速
@export_range(0.0, 1.0) var remaining_friction: float = 0.0

var _was_sliding: bool = false

# 把摩擦力改成 remaining_friction；放開方向鍵後如果角色還在滑，第一幀發出 slide_start 事件
func apply(ctx: MoveContext) -> void:
	ctx.friction_scale = remaining_friction
	var has_input := not is_zero_approx(player.get_move_input())
	var is_moving := not is_zero_approx(player.velocity.x)
	var sliding := not has_input and is_moving
	if sliding and not _was_sliding:
		Events.mechanic_event.emit("Mechanic_NoFriction", "slide_start")
	_was_sliding = sliding
