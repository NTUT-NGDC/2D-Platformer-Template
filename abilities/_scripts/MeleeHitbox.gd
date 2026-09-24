extends Area2D

# 近戰判定區：由 Ability_Melee 在攻擊時產生，跟著玩家移動，打到有 take_hit() 的東西就呼叫，
# 一次攻擊對同一個目標只算一次；存在 lifetime_left 秒後自動消失。
# 形狀跟外觀直接在 MeleeHitbox.tscn 裡改（預設畫成往右延伸），往左攻擊時會自動左右翻轉。
# 由 Ability_Melee 產生，不是拖進場景用的零件。

var damage: int = 1
var knockback: Vector2 = Vector2.ZERO
var lifetime_left: float = 0.15
var attacker: Node = null
var _already_hit: Array = []

# 設定碰撞層／遮罩，監聽撞到東西
func _ready() -> void:
	collision_layer = 1 << 5  # 圖層 6「攻擊」
	collision_mask = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4)  # 地形、箱子、敵人、感應
	body_entered.connect(_on_body_entered)

# 每個物理幀倒數存在時間，時間到就消失
func _physics_process(delta: float) -> void:
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()

# 碰到東西：有 take_hit() 就打，同一個目標只算一次
func _on_body_entered(body: Node) -> void:
	if body in _already_hit or not body.has_method("take_hit"):
		return
	_already_hit.append(body)
	body.take_hit(damage, knockback, attacker)
