@tool
extends JuiceBase

# 殘影：角色移動夠快時，在身後留下一串半透明的分身，慢慢淡掉。拖進 Player → Juice 底下就一直作用（持續型）。
# 分身複製角色圖當下的樣子（朝向、體型、擠壓、顏色），留在關卡裡不跟著角色走；同時最多 12 個。

## 速度超過這個值（像素／秒）才會出現殘影；一般走路大約是 200
@export_range(50.0, 800.0) var min_speed: float = 250.0
## 每隔多少像素留一個分身，數值越小殘影越密
@export_range(4.0, 48.0) var spacing: float = 12.0
## 每個分身多久淡掉（秒）
@export_range(0.1, 1.0) var duration: float = 0.3
## 分身的顏色，選「跟著角色」就是角色原本的顏色
@export_enum("跟著角色", "白", "黃", "紅", "藍", "綠") var color: int = 0

const _MAX_GHOSTS := 12
const _START_ALPHA := 0.5
const _COLORS := [Color.WHITE, Color(1.0, 0.9, 0.3), Color(1.0, 0.3, 0.25), Color(0.35, 0.6, 1.0), Color(0.35, 0.9, 0.4)]

var _ghosts: Array = []   # 還在場上的分身（WeakRef），舊的在前面
var _last_spawn: Vector2 = Vector2.INF

# 持續型：拖進來就一直作用
func _is_continuous() -> bool:
	return true

# 每個物理幀檢查速度與距離，夠快又離上一個分身夠遠就再留一個
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(player) or player.visual == null:
		return
	if not _is_juice_on() or player.is_dead() or player.velocity.length() < min_speed:
		_last_spawn = Vector2.INF
		return
	if _last_spawn != Vector2.INF and player.global_position.distance_to(_last_spawn) < spacing:
		return
	_last_spawn = player.global_position
	_spawn_ghost()

# 清掉場上所有分身
func _on_reset() -> void:
	for w in _ghosts:
		var g = w.get_ref()
		if g:
			g.queue_free()
	_ghosts.clear()
	_last_spawn = Vector2.INF

# 複製角色圖當下的樣子做成一個分身，留在關卡裡慢慢淡掉；超過上限就先刪掉最舊的
func _spawn_ghost() -> void:
	var level := get_tree().current_scene
	if level == null:
		return
	var ghost := Node2D.new()
	ghost.z_index = -1
	level.add_child(ghost)
	for child in player.visual.get_children():
		var copy := _copy_sprite(child)
		if copy:
			ghost.add_child(copy)
			copy.global_transform = child.global_transform
	if ghost.get_child_count() == 0:
		ghost.queue_free()
		return
	ghost.modulate.a = _START_ALPHA
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, duration)
	tween.tween_callback(ghost.queue_free)
	_ghosts = _ghosts.filter(func(w): return w.get_ref() != null)
	_ghosts.append(weakref(ghost))
	while _ghosts.size() > _MAX_GHOSTS:
		var oldest = _ghosts.pop_front().get_ref()
		if oldest:
			oldest.queue_free()

# 把一張角色圖（Sprite2D 或 AnimatedSprite2D 當下那一格）複製成靜止的 Sprite2D（位置由呼叫的人設），其他種類的節點不複製
func _copy_sprite(source: Node) -> Sprite2D:
	var copy: Sprite2D
	if source is Sprite2D:
		if source.texture == null or not source.visible:
			return null
		copy = Sprite2D.new()
		copy.texture = source.texture
		copy.region_enabled = source.region_enabled
		copy.region_rect = source.region_rect
		copy.hframes = source.hframes
		copy.vframes = source.vframes
		copy.frame = source.frame
	elif source is AnimatedSprite2D:
		if source.sprite_frames == null or not source.visible:
			return null
		copy = Sprite2D.new()
		copy.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	else:
		return null
	copy.centered = source.centered
	copy.offset = source.offset
	copy.flip_h = source.flip_h
	copy.flip_v = source.flip_v
	var tint: Color = source.modulate * player.visual.modulate if color == 0 else _COLORS[color - 1]
	copy.modulate = Color(tint.r, tint.g, tint.b, 1.0)
	return copy
