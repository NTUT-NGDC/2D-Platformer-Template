extends MechanicBase

## 站在岩漿地板上時，每秒扣多少血。
@export_range(0.5, 10.0) var damage_per_sec: float = 2.0
## 這張卡生效時，角色的總血量上限。
@export_range(1.0, 20.0) var max_health: float = 10.0
## 開啟時，畫面左上角會顯示血條。
@export var show_health_bar: bool = true

var _bar: ProgressBar = null

# 套用這張卡指定的總血量，並視需要建立血條 UI
func _on_setup() -> void:
	player.health = max_health
	if show_health_bar:
		_spawn_ui()

# 站在標記為 lava 群組的地形上時持續扣血，並同步更新血條
func apply(ctx: MoveContext) -> void:
	if player.is_on_ground() and _standing_on_lava():
		player.take_damage(damage_per_sec * ctx.delta)
	if _bar:
		_bar.value = clampf(player.health / max_health, 0.0, 1.0) * 100.0

# 檢查上一幀的碰撞對象裡有沒有 lava 群組的地形
func _standing_on_lava() -> bool:
	for i in player.get_slide_collision_count():
		var collider: Object = player.get_slide_collision(i).get_collider()
		if collider is Node and collider.is_in_group("lava"):
			return true
	return false

# 建立一個獨立的 CanvasLayer 顯示血條，不需要學員手動擺 UI
func _spawn_ui() -> void:
	var layer := CanvasLayer.new()
	_bar = ProgressBar.new()
	_bar.position = Vector2(16, 16)
	_bar.size = Vector2(160, 20)
	_bar.max_value = 100.0
	layer.add_child(_bar)
	get_tree().current_scene.add_child(layer)

# 卡片被移除時把自己生成的 UI 一併清掉
func _exit_tree() -> void:
	if _bar and is_instance_valid(_bar):
		var layer := _bar.get_parent()
		if layer:
			layer.queue_free()
