extends AbilityBase

# 遠程：按下攻擊鍵（鍵盤或滑鼠）時朝面向方向（或滑鼠游標方向）發射子彈，撞到地形或受擊物件即消失。
# 拖進 Player → Abilities 底下就能用，不用連任何線。

## 用鍵盤按鍵還是滑鼠按鍵攻擊
@export_enum("鍵盤按鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type: int = 0

## 攻擊鍵（「按鍵種類」選鍵盤按鍵時才會顯示這一欄）
@export var key: Key = KEY_G

## 子彈速度
@export_range(100.0, 900.0) var bullet_speed: float = 400.0

## 冷卻秒數，這段時間內再按不會生效
@export_range(0.1, 3.0) var cooldown: float = 0.4

## 子彈存在幾秒後自動消失
@export_range(0.2, 5.0) var lifetime: float = 2.0

## 子彈要不要受重力影響（像拋物線一樣往下墜）
@export var use_gravity: bool = false

## 開啟後子彈朝滑鼠游標的方向射，關閉時朝角色面向的方向射
@export var aim_at_mouse: bool = false

const _BULLET_SCENE := preload("res://abilities/Bullet.tscn")
const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

var _facing: int = 1
var _cooldown_left: float = 0.0

# 選滑鼠按鍵時隱藏 key 欄位
func _validate_property(property: Dictionary) -> void:
	if property.name == "key" and input_type != 0:
		property.usage = PROPERTY_USAGE_NONE

# 接玩家面向訊號，向 InputRouter 註冊攻擊鍵
func _on_setup() -> void:
	if input_type == 0:
		_warn_if_dangerous_key(key)
	if player.has_signal("direction_changed"):
		player.direction_changed.connect(func(dir): _facing = dir)
	InputRouter.bind_input(self, input_type, key, InputRouter.PRESSED, _on_shoot_pressed)

# 按下攻擊鍵：冷卻中不生效，否則從玩家位置朝面向方向（aim_at_mouse 開啟時朝滑鼠游標）發射一顆子彈
func _on_shoot_pressed() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown
	var bullet: Area2D = _BULLET_SCENE.instantiate()
	bullet.global_position = player.global_position
	bullet.velocity = _shoot_direction() * bullet_speed
	bullet.gravity_enabled = use_gravity
	bullet.lifetime_left = lifetime
	bullet.shooter = player
	get_tree().current_scene.add_child(bullet)

# 每一幀處理冷卻倒數
func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

# 子彈要飛的方向：aim_at_mouse 開啟時朝滑鼠游標，游標剛好在角色身上或沒開啟就朝面向方向
func _shoot_direction() -> Vector2:
	if aim_at_mouse:
		var to_mouse: Vector2 = player.get_global_mouse_position() - player.global_position
		if to_mouse.length() > 1.0:
			return to_mouse.normalized()
	return Vector2(_facing, 0.0)

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[遠程] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
