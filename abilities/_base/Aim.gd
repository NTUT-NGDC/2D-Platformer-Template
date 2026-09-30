class_name Aim

# 共用的瞄準方向工具：玩家的遠程、後座力卡、敵人射擊都從這裡算「要朝哪裡」，
# 以後要加新的瞄準方式（例如朝最近的敵人）只改這一份。
# 每個函式都回傳長度為 1 的方向；目標太近或找不到時回傳 fallback。

const _MIN_DISTANCE := 1.0

# 從 from 指向滑鼠游標的方向
static func toward_mouse(from: Node2D, fallback: Vector2) -> Vector2:
	return toward_point(from, from.get_global_mouse_position(), fallback)

# 從 from 指向玩家的方向，場景裡沒有活著的玩家就回傳 fallback
static func toward_player(from: Node2D, fallback: Vector2) -> Vector2:
	var target := find_player(from)
	if target == null:
		return fallback
	return toward_point(from, target.global_position, fallback)

# 從 from 指向某個世界座標的方向
static func toward_point(from: Node2D, point: Vector2, fallback: Vector2) -> Vector2:
	var offset: Vector2 = point - from.global_position
	if offset.length() <= _MIN_DISTANCE:
		return fallback
	return offset.normalized()

# 左右面向換成方向（-1 左、1 右）
static func facing(dir: int) -> Vector2:
	return Vector2(signf(dir) if dir != 0 else 1.0, 0.0)

# 找場景裡的玩家（player group），找不到就回傳 null
static func find_player(from: Node) -> Node2D:
	for n in from.get_tree().get_nodes_in_group("player"):
		if n is Node2D:
			return n
	return null
