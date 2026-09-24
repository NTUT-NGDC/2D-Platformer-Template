extends Area2D

# 子彈：往發射方向飛行，撞到地形或有 take_hit() 的東西就消失；gravity_enabled 開啟時
# 會像拋物線一樣往下墜；存在超過 lifetime_left 秒、或飛超過 max_distance 像素（0 代表不限制）也會自動消失。
# 由 Ability_Ranged 產生，不是拖進場景用的零件。

const _GRAVITY := 980.0
const _DAMAGE := 1
const _KNOCKBACK_FORCE := 150.0

var velocity: Vector2 = Vector2.ZERO
var gravity_enabled: bool = false
var lifetime_left: float = 2.0
var max_distance: float = 0.0
var _traveled: float = 0.0
var shooter: Node = null

# 設定碰撞層／遮罩，監聽撞到東西
func _ready() -> void:
	collision_layer = 1 << 5  # 圖層 6「攻擊」
	collision_mask = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4)  # 地形、箱子、敵人、感應
	body_entered.connect(_on_body_entered)

# 每個物理幀往飛行方向移動，開啟重力就持續往下加速，存在時間到了或飛太遠就消失
func _physics_process(delta: float) -> void:
	if gravity_enabled:
		velocity.y += _GRAVITY * delta
	global_position += velocity * delta
	_traveled += velocity.length() * delta
	lifetime_left -= delta
	if lifetime_left <= 0.0 or (max_distance > 0.0 and _traveled >= max_distance):
		queue_free()

# 撞到東西：有 take_hit() 就打，不管有沒有打到都消失
func _on_body_entered(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(_DAMAGE, velocity.normalized() * _KNOCKBACK_FORCE, shooter)
	queue_free()
