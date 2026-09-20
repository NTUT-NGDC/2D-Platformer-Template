extends CharacterBody2D

# Gym 專用的笨敵人：在固定範圍內左右走，碰到玩家會讓玩家扣血。
# 這不是機制卡，是關卡自己的道具，學員不會碰到這個腳本。

@export var patrol_speed: float = 60.0
@export var patrol_distance: float = 80.0
@export var contact_damage: float = 1.0

var _start_x: float = 0.0
var _dir: int = 1
var _hit_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	_start_x = position.x

func _physics_process(delta: float) -> void:
	velocity.x = patrol_speed * _dir
	velocity.y += 980.0 * delta
	move_and_slide()
	if absf(position.x - _start_x) >= patrol_distance:
		_dir *= -1
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	_check_player_contact()

# 檢查這一幀有沒有撞到玩家，有的話讓玩家扣血（有冷卻，避免每幀連續扣）
func _check_player_contact() -> void:
	if _hit_cooldown > 0.0:
		return
	for i in get_slide_collision_count():
		var collider: Object = get_slide_collision(i).get_collider()
		if collider is Node and collider.has_method("take_damage") and collider.is_in_group("player"):
			collider.take_damage(contact_damage)
			_hit_cooldown = 1.0
			return
