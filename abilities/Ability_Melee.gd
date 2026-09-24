extends AbilityBase

# 近戰：按下攻擊鍵（鍵盤或滑鼠）時，在玩家面向方向短暫生成一塊攻擊判定區，打到有 take_hit() 的
# 東西就呼叫，造成傷害跟擊退。拖進 Player → Abilities 底下就能用，不用連任何線。

## 用鍵盤按鍵還是滑鼠按鍵攻擊
@export_enum("鍵盤按鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type: int = 0

## 攻擊鍵（「按鍵種類」選鍵盤按鍵時才會顯示這一欄）
@export var key: Key = KEY_F

## 攻擊範圍，單位是格（1 格 = 16 像素）
@export_range(1, 5) var range_tiles: int = 1

## 冷卻秒數，這段時間內再按不會生效
@export_range(0.1, 3.0) var cooldown: float = 0.5

## 擊退力道
@export_range(0.0, 600.0) var knockback: float = 200.0

## 傷害
@export_range(1, 10) var damage: int = 1

const _TILE_SIZE := 16.0
const _HITBOX_HEIGHT := 16.0
const _HITBOX_DURATION := 0.15
const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

var _facing: int = 1
var _cooldown_left: float = 0.0
var _hitbox_time_left: float = 0.0
var _already_hit: Array = []
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D
var _hitbox_size: Vector2
var _visual: ColorRect

# 選滑鼠按鍵時隱藏 key 欄位
func _validate_property(property: Dictionary) -> void:
	if property.name == "key" and input_type != 0:
		property.usage = PROPERTY_USAGE_NONE

# 建立攻擊判定區、接玩家面向訊號、向 InputRouter 註冊攻擊鍵
func _on_setup() -> void:
	if input_type == 0:
		_warn_if_dangerous_key(key)
	if player.has_signal("direction_changed"):
		player.direction_changed.connect(func(dir): _facing = dir)
	_build_hitbox()
	InputRouter.bind_input(self, input_type, key, InputRouter.PRESSED, _on_attack_pressed)

# 建立一個平常關閉的 Area2D 當攻擊判定區，命中時呼叫對方的 take_hit()，
# 另外建一塊黃色閃光跟判定區同步開關，讓學員看得到攻擊有沒有揮出去
func _build_hitbox() -> void:
	_hitbox_size = Vector2(range_tiles * _TILE_SIZE, _HITBOX_HEIGHT)
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 1 << 5  # 圖層 6「攻擊」
	_hitbox.collision_mask = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4)  # 地形、箱子、敵人、感應
	_hitbox.monitoring = false
	_hitbox_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = _hitbox_size
	_hitbox_shape.shape = shape
	_hitbox.add_child(_hitbox_shape)
	add_child(_hitbox)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)

	_visual = ColorRect.new()
	_visual.size = _hitbox_size
	_visual.color = Color(1.0, 0.95, 0.3, 0.8)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.visible = false
	add_child(_visual)

# 按下攻擊鍵：冷卻中不生效，否則在面向方向短暫打開判定區，同步亮出閃光
func _on_attack_pressed() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown
	_already_hit.clear()
	var offset := Vector2(_facing * range_tiles * _TILE_SIZE * 0.5, 0)
	_hitbox.position = offset
	_hitbox.monitoring = true
	_visual.position = offset - _hitbox_size * 0.5
	_visual.visible = true
	_hitbox_time_left = _HITBOX_DURATION

# 判定區碰到東西：有 take_hit() 就打，一次攻擊對同一個目標只算一次
func _on_hitbox_body_entered(body: Node) -> void:
	if body in _already_hit or not body.has_method("take_hit"):
		return
	_already_hit.append(body)
	body.take_hit(damage, Vector2(_facing, 0) * knockback, player)

# 每一幀處理冷卻倒數，跟判定區開啟的時間到了要關掉
func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
	if _hitbox_time_left > 0.0:
		_hitbox_time_left -= delta
		if _hitbox_time_left <= 0.0:
			_hitbox.monitoring = false
			_visual.visible = false

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[近戰] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
