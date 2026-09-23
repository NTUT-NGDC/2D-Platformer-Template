extends MechanicBase

# 地板是岩漿：scope 決定只有踩到岩漿地板扣血，還是任何地板都扣血（標記 safe 的除外）。
# 血量走 Stats 既有流程，這張卡不自帶血量上限（上限由場景的 ValueSettings 設定）。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 站在扣血地板上時每秒扣多少血
@export_range(0.5, 10.0) var damage_per_second: float = 2.0

## 扣血地板的判定範圍
@export_enum("只有岩漿地板", "所有地板") var scope: int = 0

## 要不要在畫面上顯示血條
@export var show_health_bar: bool = true

const _SCOPE_LAVA_ONLY := 0
const _FLOOR_NORMAL_MIN := 0.7
# Stats 只認整數，累積滿一秒才扣一次整份傷害，理由同 Mechanic_HealthDrain（每幀扣一點點
# 會被 take_damage() 內部的 roundi() 捨去成 0）
const _TICK_INTERVAL := 1.0

var _elapsed: float = 0.0

# show_health_bar 關閉時把血量那一列從 HUD 藏起來
func _on_setup() -> void:
	if not show_health_bar:
		Stats.configure(Stats.HEALTH_KIND, Stats.get_value(Stats.HEALTH_KIND),
			Stats.get_max_value(Stats.HEALTH_KIND), false, Stats.is_reset_on_death(Stats.HEALTH_KIND))

# 站在扣血地板上才累積時間，離開就歸零；累積滿一秒扣一次血
func apply(ctx: MoveContext) -> void:
	if not _standing_on_damaging_floor():
		_elapsed = 0.0
		return
	_elapsed += ctx.delta
	if _elapsed < _TICK_INTERVAL:
		return
	_elapsed -= _TICK_INTERVAL
	player.take_damage(damage_per_second)

# 掃這一幀的地板碰撞（法線接近 up_direction），依 scope 判斷腳下算不算扣血地板
func _standing_on_damaging_floor() -> bool:
	for i in player.get_slide_collision_count():
		var col: KinematicCollision2D = player.get_slide_collision(i)
		if col.get_normal().dot(player.up_direction) <= _FLOOR_NORMAL_MIN:
			continue
		var collider: Object = col.get_collider()
		if not (collider is Node):
			continue
		var node: Node = collider
		if scope == _SCOPE_LAVA_ONLY:
			if _is_lava(node):
				return true
		elif not node.is_in_group("safe"):
			return true
	return false

# Lava.gd 把 "lava" group 加在自己的根節點，玩家實際踩到的是它底下的 Body 子節點，
# 所以連父節點也要一起檢查，不然永遠偵測不到
func _is_lava(node: Node) -> bool:
	if node.is_in_group("lava"):
		return true
	var parent: Node = node.get_parent()
	return parent != null and parent.is_in_group("lava")
