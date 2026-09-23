extends Area2D

# 尖刺：感應，玩家碰到時依 penalty 扣血或直接死亡，碰一次算一次（不像岩漿是持續扣血）。
# 拖進場景就能用，不用連任何線。

## 處罰方式：扣血、直接死亡
@export_enum("扣血", "即死") var penalty: int = 0

## 扣血量，penalty 是「即死」時不會用到
@export_range(1, 10) var damage: int = 1

const _PENALTY_HEALTH := 0

# 加入 hazard group，設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
	add_to_group("hazard")
	collision_layer = 1 << 4  # 圖層 5「感應」
	collision_mask = 1 << 0   # 圖層 1「玩家」
	body_entered.connect(_on_body_entered)

# 玩家碰到：依 penalty 扣血或直接死亡
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if penalty == _PENALTY_HEALTH:
		if body.has_method("take_damage"):
			body.take_damage(damage)
	else:
		if body.has_method("kill"):
			body.kill()
