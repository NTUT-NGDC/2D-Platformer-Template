extends Area2D

# 尖刺：感應，玩家碰到時依 penalty 扣血或直接死亡，碰一次算一次（不像岩漿是持續扣血）。
# 拖進場景就能用，不用連任何線。

## 處罰方式：扣血、直接死亡
@export_enum("扣血", "即死") var penalty: int = 0

## 扣血量，penalty 是「即死」時不會用到
@export_range(1, 10) var damage: int = 1

## 扣血時把玩家彈開的力道，0 = 不彈開只扣血；penalty 是「即死」時不會用到
@export_range(0.0, 800.0) var knockback: float = 300.0

const _PENALTY_HEALTH := 0

# 加入 hazard group，設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
	add_to_group("hazard")
	collision_layer = Layers.SENSOR
	collision_mask = Layers.PLAYER
	body_entered.connect(_on_body_entered)

# 玩家碰到：依 penalty 打玩家一下（扣血＋把玩家往外、往上彈開）或直接死亡
func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if penalty == _PENALTY_HEALTH:
		var player := body as CharacterBody2D
		if player != null and player.has_method("take_hit"):
			var away := (player.global_position - global_position).normalized()
			var direction := (away + player.up_direction * 0.5).normalized()
			player.take_hit(damage, direction * knockback, self)
	else:
		if body.has_method("kill"):
			body.kill()
