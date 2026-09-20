extends MechanicBase

## 什麼時候要改變角色大小。
@export_enum("隨時間", "跳躍時切換", "受傷時") var trigger: int = 0
## 縮到最小時是原本大小的幾倍。
@export_range(0.3, 1.0) var min_size: float = 0.5
## 放到最大時是原本大小的幾倍。
@export_range(1.0, 2.5) var max_size: float = 1.8

const CYCLE_TIME := 2.0

var _elapsed: float = 0.0
var _grown: bool = false
var _target: float = 1.0

# 依觸發時機接對應的訊號
func _on_setup() -> void:
	_target = player.size_factor
	match trigger:
		1:
			player.jumped.connect(_toggle_size)
		2:
			player.hurt.connect(_toggle_size)

# 「隨時間」模式下用正弦波算出目前目標大小，其餘模式等待訊號切換
func apply(_ctx: MoveContext) -> void:
	if trigger == 0:
		_elapsed += _ctx.delta
		var t: float = (sin(_elapsed / CYCLE_TIME * TAU) + 1.0) / 2.0
		_target = lerpf(min_size, max_size, t)
	_try_apply_size()

# 在「跳躍時切換」「受傷時」模式下，於大小之間來回切換
func _toggle_size() -> void:
	_grown = not _grown
	_target = max_size if _grown else min_size

# 把目標大小套用到角色身上，變大前先確認不會卡進地形
func _try_apply_size() -> void:
	if is_equal_approx(player.size_factor, _target):
		return
	if _target > player.size_factor and _would_overlap(_target):
		return
	player.set_size_factor(_target)

# 用形狀查詢檢查角色以指定倍率放大後，是不是會卡進周圍的地形
func _would_overlap(factor: float) -> bool:
	var shape_node: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	if shape_node == null or shape_node.shape == null:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	var xform := Transform2D().scaled(Vector2.ONE * factor)
	xform.origin = player.global_position
	query.transform = xform
	query.exclude = [player.get_rid()]
	var space_state := player.get_world_2d().direct_space_state
	return space_state.intersect_shape(query, 1).size() > 0
