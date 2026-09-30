extends Node2D

# 手動驗證用：子彈陣營與 Player.take_hit()。
# 按鍵從場景裡的發射點射出「敵方」子彈：1 打玩家、2 打可破壞方塊（hit_objects 關）、
# 3 打可破壞方塊（hit_objects 開）、4 打敵人。G 是玩家自己的遠程：穿過 block_bullets 關掉的
# Box_Pass，打到 Box_Solid。

const _BULLET_SPEED := 250.0

@onready var _player: CharacterBody2D = $Player
@onready var _muzzle_player: Marker2D = $Muzzle_Player
@onready var _muzzle_objects: Marker2D = $Muzzle_Objects
@onready var _muzzle_enemy: Marker2D = $Muzzle_Enemy
@onready var _breakable_safe: StaticBody2D = $Breakable_Safe
@onready var _breakable_hit: StaticBody2D = $Breakable_Hit
@onready var _enemy: CharacterBody2D = $Enemy_Target

var _safe_last_hit_by: Node = null

# 印出操作說明，接受擊事件印出誰打到誰
func _ready() -> void:
	Events.hit.connect(_on_hit)
	_breakable_safe.broken.connect(_on_safe_broken)
	_breakable_hit.broken.connect(func(): print("[測試] Breakable_Hit 碎了"))
	print("[測試] 按 1：敵方子彈朝玩家射，玩家被擊退、HUD 血量 -1；連打 3 發血量歸零會重生、血量補滿")
	print("[測試] 按 2：敵方子彈（hit_objects 關）打 Breakable_Safe（左邊方塊），子彈消失但方塊不會碎")
	print("[測試] 按 3：敵方子彈（hit_objects 開）打 Breakable_Hit（右邊方塊），方塊碎掉")
	print("[測試] 按 4：敵方子彈朝 Enemy_Target 射，子彈直接穿過敵人、不會印出「被打到」")
	print("[測試] 按 G（面向右）：子彈穿過左邊的 Box_Pass（block_bullets 關），打到右邊的 Box_Solid 把它往右推一下")

# 印出誰打到誰，順便記住最後一次打到 Breakable_Safe 的是誰
func _on_hit(target: Node, source: Node) -> void:
	print("[測試] %s 被 %s 打到" % [target.name, source.name])
	if target == _breakable_safe:
		_safe_last_hit_by = source

# Breakable_Safe 碎了：被玩家自己的子彈打碎是正常的，被敵方子彈（hit_objects 關）打碎才是錯
func _on_safe_broken() -> void:
	if _safe_last_hit_by == _player:
		print("[測試] Breakable_Safe 被玩家自己的子彈打碎（正常，3 秒後長回來）")
	else:
		print("[測試] ✗ Breakable_Safe 被敵方子彈打碎了（不應該，hit_objects 是關的）")

# 除錯按鍵：從對應發射點射出敵方子彈
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_1:
			_fire(_muzzle_player, Aim.toward_player(_muzzle_player, Vector2.LEFT), false)
		KEY_2:
			_fire(_muzzle_objects, Aim.toward_point(_muzzle_objects, _breakable_safe.global_position, Vector2.DOWN), false)
		KEY_3:
			_fire(_muzzle_objects, Aim.toward_point(_muzzle_objects, _breakable_hit.global_position, Vector2.DOWN), true)
		KEY_4:
			_muzzle_enemy.global_position.x = _enemy.global_position.x
			_fire(_muzzle_enemy, Vector2.DOWN, false)

# 從發射點射出一顆敵方子彈
func _fire(from: Node2D, direction: Vector2, hit_objects: bool) -> void:
	var bullet := Bullet.spawn(from, direction, _BULLET_SPEED, Bullet.TEAM_ENEMY)
	bullet.hit_objects = hit_objects
	print("[測試] 從 %s 射出敵方子彈（hit_objects %s），玩家血量目前 %d" % [from.name, "開" if hit_objects else "關", Stats.get_value(Stats.HEALTH_KIND)])
