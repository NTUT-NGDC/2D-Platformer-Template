extends MechanicBase

## 踩到黏地板時的效果。
@export_enum("變慢", "黏住不能動") var mode: int = 0
## 「變慢」模式下，踩在黏地板上速度剩下幾成。
@export_range(0.1, 0.8) var speed: float = 0.3

# 踩在 sticky 群組的地板上時，套用變慢或鎖死移動
func apply(ctx: MoveContext) -> void:
	if not player.is_on_ground() or not _standing_on_sticky():
		return
	if mode == 0:
		ctx.speed_scale = speed
	else:
		ctx.input_locked = true
		ctx.jump_locked = true

# 檢查上一幀的碰撞對象裡有沒有 sticky 群組的地形
func _standing_on_sticky() -> bool:
	for i in player.get_slide_collision_count():
		var collider: Object = player.get_slide_collision(i).get_collider()
		if collider is Node and collider.is_in_group("sticky"):
			return true
	return false
