extends RigidBody2D

# 箱子：會動，玩家撞上去可以推著走；被攻擊時只會被擊退，不會受傷、沒有耐久。
# 拖進場景就能用，不用連任何線。

## 重量：輕的比較好推、重的比較不好推
@export_enum("輕", "重") var weight: int = 0

const _LIGHT_MASS := 1.0
const _HEAVY_MASS := 4.0

# 依重量套用質量，鎖住旋轉讓箱子不會被撞得團團轉，加入 box group 讓其他系統辨識
func _ready() -> void:
	add_to_group("box")
	mass = _LIGHT_MASS if weight == 0 else _HEAVY_MASS
	lock_rotation = true
	collision_layer = 1 << 2  # 圖層 3「箱子」
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2)  # 圖層 1「玩家」、圖層 2「地形」、圖層 3「箱子」

# 被攻擊打到：只受擊退，不扣血、沒有耐久
func take_hit(_damage: int, knockback: Vector2, source: Node) -> void:
	Events.hit.emit(self, source)
	apply_central_impulse(knockback)
