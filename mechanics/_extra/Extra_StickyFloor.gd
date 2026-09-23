extends MechanicBase

# 黏黏地板：踩在地板上時變慢或完全黏住走不動（還是可以跳出去），離地立刻恢復正常。
# 備品庫卡，不在抽卡池裡，學員許願才拖給他。拖進 Player → Mechanics 底下就能用，
# 不用連任何線。

## 踩在地板上時的效果
@export_enum("變慢", "黏住走不動") var effect: int = 0

## 變慢模式下，速度剩下多少倍
@export_range(0.1, 0.8) var slow_scale: float = 0.4

const _EFFECT_SLOW := 0

# 站在地板上就套用變慢或走不動；離地這一幀完全不碰 speed_scale，立刻恢復正常
func apply(ctx: MoveContext) -> void:
	if not player.is_on_ground():
		return
	ctx.speed_scale = slow_scale if effect == _EFFECT_SLOW else 0.0
