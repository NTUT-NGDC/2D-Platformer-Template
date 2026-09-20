extends MechanicBase

## 開啟時，碰到敵人會立刻死亡。
@export var die_on_enemy: bool = true
## 開啟時，碰到箱子會立刻死亡。
@export var die_on_box: bool = true
## 開啟時，碰到牆壁會立刻死亡。
@export var die_on_wall: bool = false

# 檢查上一幀的碰撞對象所屬的 group，符合條件就讓角色死亡
func apply(_ctx: MoveContext) -> void:
	if player == null:
		return
	for i in player.get_slide_collision_count():
		var collider: Object = player.get_slide_collision(i).get_collider()
		if not (collider is Node):
			continue
		if die_on_enemy and collider.is_in_group("enemy"):
			player.kill()
			return
		if die_on_box and collider.is_in_group("box"):
			player.kill()
			return
		if die_on_wall and collider.is_in_group("wall"):
			player.kill()
			return
