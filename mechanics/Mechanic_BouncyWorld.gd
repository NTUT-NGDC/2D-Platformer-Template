extends MechanicBase

## 碰撞後保留的速度比例，1.0 = 完全不損耗，數字愈大彈愈高。
@export_range(0.3, 1.5) var bounciness: float = 0.9
## 關閉時，踩在地上不會彈起來，只有牆壁跟天花板會彈。
@export var floor_bounces: bool = true

const MIN_BOUNCE_SPEED := 20.0

# 讀取上一幀 move_and_slide 留下的碰撞紀錄，沿法線方向把速度彈回去
func apply(_ctx: MoveContext) -> void:
	if player == null:
		return
	for i in player.get_slide_collision_count():
		var collision := player.get_slide_collision(i)
		var normal: Vector2 = collision.get_normal()
		var is_floor_like: bool = normal.dot(Vector2.UP) > 0.7
		if is_floor_like and not floor_bounces:
			continue
		if player.velocity.length() < MIN_BOUNCE_SPEED:
			continue
		var bounced: Vector2 = player.velocity.bounce(normal) * bounciness
		player.add_impulse(bounced - player.velocity)
