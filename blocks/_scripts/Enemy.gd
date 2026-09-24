extends CharacterBody2D

# 笨敵人：會動，左右巡邏，撞牆自動轉身，turn_at_ledge 開啟時走到懸崖邊也會轉身。
# 被攻擊會扣血，歸零時消失並發出 defeated；碰到玩家會造成傷害。
# 拖進場景就能用，不用連任何線。

## 巡邏速度
@export_range(20.0, 200.0) var speed: float = 60.0

## 血量，扣到 0 就會消失
@export_range(1, 20) var health: int = 3

## 碰到玩家造成的傷害
@export_range(1, 10) var damage: int = 1

## 走到懸崖邊會不會轉身，關掉的話會直接走下去
@export var turn_at_ledge: bool = true

## 血量歸零消失時發出，給學員自己接特效／音效用
signal defeated

const _GRAVITY := 980.0
const _STUN_DURATION := 0.25

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _ledge_check_left: RayCast2D = $LedgeCheckLeft
@onready var _ledge_check_right: RayCast2D = $LedgeCheckRight

var _direction: int = 1
var _health_left: int = 0
var _stun_time_left: float = 0.0

# 被攻擊打到：扣血並被擊退一下，歸零時消失
func take_hit(hit_damage: int, knockback: Vector2, source: Node) -> void:
	Events.hit.emit(self, source)
	_health_left -= maxi(hit_damage, 1)
	velocity += knockback
	_stun_time_left = _STUN_DURATION
	if _health_left <= 0:
		defeated.emit()
		queue_free()

# 加入 enemy group，設定碰撞層／遮罩、Hurtbox，套用一開始的血量
func _ready() -> void:
	add_to_group("enemy")
	_health_left = health
	collision_layer = 1 << 3  # 圖層 4「敵人」
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2)  # 圖層 1「玩家」、圖層 2「地形」、圖層 3「箱子」
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 1 << 0  # 圖層 1「玩家」
	_hurtbox.body_entered.connect(_on_hurtbox_entered)

# 碰到玩家造成傷害，碰一次算一次
func _on_hurtbox_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

# 每個物理幀：套用重力、往目前方向移動，撞牆或走到懸崖邊就轉身；
# 被擊退期間（_stun_time_left > 0）先不控制水平速度，讓擊退看得出來
func _physics_process(delta: float) -> void:
	velocity.y += _GRAVITY * delta
	if _stun_time_left > 0.0:
		_stun_time_left -= delta
	else:
		velocity.x = _direction * speed
	move_and_slide()
	if _stun_time_left <= 0.0:
		if is_on_wall():
			_turn_around()
		elif turn_at_ledge and not _has_ground_ahead():
			_turn_around()

# 檢查目前前進方向的懸崖偵測線有沒有踩到地板
func _has_ground_ahead() -> bool:
	var ray := _ledge_check_right if _direction > 0 else _ledge_check_left
	ray.force_raycast_update()
	return ray.is_colliding()

# 反轉巡邏方向
func _turn_around() -> void:
	_direction *= -1
