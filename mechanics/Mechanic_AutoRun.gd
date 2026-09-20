extends MechanicBase

## 角色會被強制往哪個方向走。
@export_enum("向右", "向左") var direction: int = 0
## 關閉時角色完全不能跳躍，只能一直往前走。
@export var can_jump: bool = true

# 每幀強制角色往固定方向移動，並決定要不要一併鎖住跳躍
func apply(ctx: MoveContext) -> void:
	ctx.auto_run_dir = 1 if direction == 0 else -1
	ctx.jump_locked = not can_jump
