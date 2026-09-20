extends MechanicBase

## 存活滿幾秒就算過關。
@export_range(10.0, 120.0) var duration: float = 30.0
## 開啟時，畫面左上角會顯示倒數計時文字。
@export var show_timer: bool = true

var _elapsed: float = 0.0
var _cleared: bool = false
var _label: Label = null

# 視需要建立計時 UI，並在角色死亡時重算
func _on_setup() -> void:
	if show_timer:
		_spawn_ui()
	player.died.connect(_on_player_died)

# 累積存活時間，達標就發出過關事件
func apply(ctx: MoveContext) -> void:
	if _cleared:
		return
	_elapsed += ctx.delta
	if _label:
		_label.text = "存活計時：%.1f / %.1f 秒" % [minf(_elapsed, duration), duration]
	if _elapsed >= duration:
		_cleared = true
		Events.level_cleared.emit()
		if _label:
			_label.text = "過關！存活了 %.1f 秒" % duration

# 角色死亡後歸零重算，別讓玩家帶著舊進度復活
func _on_player_died() -> void:
	_elapsed = 0.0
	_cleared = false

# 建立一個獨立的 CanvasLayer 顯示計時文字，不需要學員手動擺 UI
func _spawn_ui() -> void:
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 20)
	layer.add_child(_label)
	get_tree().current_scene.add_child(layer)

# 卡片被移除時把自己生成的 UI 一併清掉
func _exit_tree() -> void:
	if _label and is_instance_valid(_label):
		var layer := _label.get_parent()
		if layer:
			layer.queue_free()
