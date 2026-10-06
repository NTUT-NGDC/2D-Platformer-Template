extends RefCounted

# Player 內部使用的輔助類別：把各個 Juice 組件對外觀的請求（擠壓、顏色、傾斜）相乘合成，
# 套用在 Visual 底下的每個圖片子節點上。Visual 本身的 scale／modulate 留給機制卡用，兩邊疊加不互蓋。
# 請求依 source（發出請求的組件）分開記，撤掉一個只拿掉它自己那份。

var _visual: Node2D = null
var _foot: Vector2 = Vector2.ZERO
var _squash: Dictionary = {}   # source 的 instance id -> Vector2
var _tint: Dictionary = {}     # source 的 instance id -> Color
var _tilt: Dictionary = {}     # source 的 instance id -> float
var _originals: Dictionary = {} # 子節點的 instance id -> { node, position, scale, rotation, modulate }

# 記住要作用的 Visual 節點，以及腳底在 Visual 座標裡的位置（擠壓、傾斜以這裡為中心）
func _init(visual: Node2D, foot_y: float) -> void:
	_visual = visual
	_foot = Vector2(0.0, foot_y)

# 記下某個組件要的擠壓量，重新合成
func set_squash(source: Node, amount: Vector2) -> void:
	_squash[source.get_instance_id()] = amount
	_refresh()

# 記下某個組件要的顏色，重新合成
func set_tint(source: Node, color: Color) -> void:
	_tint[source.get_instance_id()] = color
	_refresh()

# 記下某個組件要的傾斜角度，重新合成
func set_tilt(source: Node, angle: float) -> void:
	_tilt[source.get_instance_id()] = angle
	_refresh()

# 撤掉某個組件的所有請求，重新合成（全部撤光時子節點還原成原本的樣子）
func clear(source: Node) -> void:
	var id := source.get_instance_id()
	_squash.erase(id)
	_tint.erase(id)
	_tilt.erase(id)
	_refresh()

# 把所有請求合成後套到 Visual 的子節點上；沒有任何請求時還原並忘掉記下的原始值
func _refresh() -> void:
	if not is_instance_valid(_visual):
		return
	_drop_freed_sources()
	if _squash.is_empty() and _tint.is_empty() and _tilt.is_empty():
		_restore_all()
		return
	var squash := Vector2.ONE
	for v in _squash.values():
		squash *= v
	var tint := Color.WHITE
	for c in _tint.values():
		tint *= c
	var tilt := 0.0
	for a in _tilt.values():
		tilt += a
	for child in _visual.get_children():
		if child is Node2D or child is Control:
			_apply_to(child, squash, tint, tilt)

# 對單一子節點套用合成結果：以腳底為中心先擠壓再傾斜，顏色乘在原本的顏色上
func _apply_to(child, squash: Vector2, tint: Color, tilt: float) -> void:
	var id: int = child.get_instance_id()
	if not _originals.has(id):
		_originals[id] = {
			"node": child,
			"position": child.position,
			"scale": child.scale,
			"rotation": child.rotation,
			"modulate": child.modulate,
		}
	var o: Dictionary = _originals[id]
	child.position = _foot + ((o.position - _foot) * squash).rotated(tilt)
	child.scale = o.scale * squash
	child.rotation = o.rotation + tilt
	child.modulate = o.modulate * tint

# 把記過原始值的子節點全部還原
func _restore_all() -> void:
	for o in _originals.values():
		var child = o.node
		if not is_instance_valid(child):
			continue
		child.position = o.position
		child.scale = o.scale
		child.rotation = o.rotation
		child.modulate = o.modulate
	_originals.clear()

# 清掉已經被刪除、卻沒來得及撤掉請求的組件，避免它的效果永遠卡在角色身上
func _drop_freed_sources() -> void:
	for d in [_squash, _tint, _tilt]:
		for id in d.keys():
			if not is_instance_id_valid(id):
				d.erase(id)
