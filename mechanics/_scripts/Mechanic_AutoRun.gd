extends MechanicBase

# 只能往前：玩家不能自己控制方向，角色會自動往一邊跑，只能按跳躍。
# turn_at_wall 開啟時，撞到牆壁或箱子會自動轉向。拖進 Player → Mechanics 底下就能用。

## 遊戲開始時往哪個方向跑
@export_enum("向右", "向左") var start_direction: int = 0

## 撞到牆壁或箱子時要不要自動轉向
@export var turn_at_wall: bool = true

## 轉向後多久內不能再轉向，避免卡在角落抖動
@export_range(0.05, 0.5) var turn_cooldown: float = 0.15

const _DIR_RIGHT := 0

var _dir: int = 1
var _turn_cooldown_left: float = 0.0

# 套用一開始的方向，同步角色朝向
func _on_setup() -> void:
	_dir = 1 if start_direction == _DIR_RIGHT else -1
	_sync_visual()

# 強制水平方向，撞到正前方的牆（或箱子）就轉向
func apply(ctx: MoveContext) -> void:
	ctx.auto_run_dir = _dir
	if _turn_cooldown_left > 0.0:
		_turn_cooldown_left -= ctx.delta
		return
	if not turn_at_wall or not player.is_on_wall():
		return
	var normal: Vector2 = player.get_wall_normal()
	if normal.dot(Vector2(_dir, 0.0)) < 0.0:
		_turn_around()

# 反轉方向、進入轉向冷卻、同步角色朝向，發出 wall_turned 事件
func _turn_around() -> void:
	_dir *= -1
	_turn_cooldown_left = turn_cooldown
	_sync_visual()
	Events.mechanic_event.emit("Mechanic_AutoRun", "wall_turned")

# 依目前方向翻轉角色視覺
func _sync_visual() -> void:
	if player.visual:
		player.visual.scale.x = _dir
