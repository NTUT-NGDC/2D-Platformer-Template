extends MechanicBase

## 放開方向鍵後還剩下多少煞車力，0 = 完全滑不停，1 = 跟平常一樣立刻煞停。
@export_range(0.0, 1.0) var friction: float = 0.0

# 把摩擦力倍率交給 Player 的移動管線
func apply(ctx: MoveContext) -> void:
	ctx.friction_scale = friction
