extends AbilityBase

# 遠程：按下 key 時朝面向方向發射子彈，撞到地形或受擊物件即消失。
# 拖進 Player → Abilities 底下就能用，不用連任何線。

## 攻擊鍵
@export var key: Key = KEY_G

## 子彈速度
@export_range(100.0, 900.0) var bullet_speed: float = 400.0

## 冷卻秒數，這段時間內再按不會生效
@export_range(0.1, 3.0) var cooldown: float = 0.4

## 子彈存在幾秒後自動消失
@export_range(0.2, 5.0) var lifetime: float = 2.0

## 子彈要不要受重力影響（像拋物線一樣往下墜）
@export var use_gravity: bool = false

const _BULLET_SCENE := preload("res://abilities/Bullet.tscn")
const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

var _facing: int = 1
var _cooldown_left: float = 0.0

# 接玩家面向訊號，向 InputRouter 註冊攻擊鍵
func _on_setup() -> void:
	_warn_if_dangerous_key(key)
	if player.has_signal("direction_changed"):
		player.direction_changed.connect(func(dir): _facing = dir)
	InputRouter.bind_key(self, key, InputRouter.PRESSED, _on_shoot_pressed)

# 按下攻擊鍵：冷卻中不生效，否則從玩家位置朝面向方向發射一顆子彈
func _on_shoot_pressed() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown
	var bullet: Area2D = _BULLET_SCENE.instantiate()
	bullet.global_position = player.global_position
	bullet.velocity = Vector2(_facing * bullet_speed, 0.0)
	bullet.gravity_enabled = use_gravity
	bullet.lifetime_left = lifetime
	bullet.shooter = player
	get_tree().current_scene.add_child(bullet)

# 每一幀處理冷卻倒數
func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[遠程] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
