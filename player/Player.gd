extends CharacterBody2D

# 唯一的物理腳本，學員禁區。
# 不要在這裡寫任何具名機制卡的邏輯 —— 機制卡透過 MoveContext 影響這裡的計算。

signal jumped
signal landed(impact_force: float)   # impact_force = 落地瞬間的 velocity.y 絕對值
signal hurt
signal died
signal direction_changed(dir: int)   # -1 左, 1 右
signal wall_hit
signal started_moving
signal stopped_moving

@export_group("移動參數")
## 水平移動速度，數值愈大角色跑得愈快。
@export_range(50.0, 500.0) var move_speed: float = 200.0
## 跳躍瞬間的初始速度，數值愈大跳得愈高。
@export_range(100.0, 800.0) var jump_force: float = 400.0
## 重力加速度，數值愈大角色下墜（或重力翻轉後上升）愈快。
@export_range(200.0, 2000.0) var gravity: float = 980.0
## 地面摩擦係數：0 = 像冰面一樣滑不停，1 = 放開方向鍵立刻煞停。
@export_range(0.0, 1.0) var ground_friction: float = 0.8

var visual: Node2D = null
var size_factor: float = 1.0

var _mechanics: Array[Node] = []
var _last_direction: int = 0
var _was_moving: bool = false
var _was_on_wall: bool = false
var _is_dead: bool = false
var _damage_scale: float = 1.0

# 啟動時找視覺節點，並掃描 Mechanics／Juice 底下現有的組件逐一註冊
func _ready() -> void:
	add_to_group("player")
	_find_visual()
	if has_node("Mechanics"):
		_register_children($Mechanics, true)
	if has_node("Juice"):
		_register_children($Juice, false)

# 尋找視覺節點：先找 player_visual 群組，找不到就退而找 Visual 子節點，都沒有就發警告
func _find_visual() -> void:
	for n in get_tree().get_nodes_in_group("player_visual"):
		if is_ancestor_of(n):
			visual = n
			break
	if visual == null and has_node("Visual"):
		visual = $Visual as Node2D
	if visual == null:
		push_warning("[Player] 找不到視覺節點，請在關卡場景裡幫 Player 加一個叫 Visual 的子節點（或加入 player_visual 群組）")
		printerr("⚠ [Player] player.visual 是 null，跟視覺相關的 Juice 組件不會生效")

# 把籃子裡現有的子節點逐一註冊，並監聽之後新增的子節點
func _register_children(container: Node, track_apply: bool) -> void:
	for child in container.get_children():
		_try_setup(child, track_apply)
	container.child_entered_tree.connect(func(n): _try_setup(n, track_apply))

# 幫單一子節點呼叫 setup()，沒有 setup() 就發警告表示它掛錯位置
func _try_setup(child: Node, track_apply: bool) -> void:
	if child.has_method("setup"):
		child.setup(self)
		if track_apply and child.has_method("apply"):
			_mechanics.append(child)
	else:
		push_warning("[Player] %s 沒有 setup()，可能不是合法的組件" % child.name)

# 每個物理幀的主流程：收集機制卡建議、套用移動與重力、處理跳躍與位移
func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	var ctx := MoveContext.new()
	ctx.delta = delta
	for m in _mechanics:
		if is_instance_valid(m) and m.enabled:
			m.apply(ctx)
	_damage_scale = ctx.damage_scale

	var pre_on_floor := is_on_floor()
	var pre_fall_speed: float = velocity.dot(-up_direction)

	_apply_horizontal(ctx, delta)
	_apply_vertical(ctx, delta)

	if pre_on_floor and not ctx.input_locked and Input.is_action_just_pressed("jump"):
		force_jump(ctx.jump_scale)

	move_and_slide()

	_emit_landing(pre_on_floor, pre_fall_speed)
	_emit_wall_hit()

# 依輸入或機制卡指定的方向計算水平速度
func _apply_horizontal(ctx: MoveContext, delta: float) -> void:
	var input_dir := 0.0
	if ctx.auto_run_dir != 0:
		input_dir = float(ctx.auto_run_dir)
	elif not ctx.input_locked:
		input_dir = Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		velocity.x = input_dir * move_speed * ctx.speed_scale
		_update_facing(input_dir)
		if not _was_moving:
			_was_moving = true
			started_moving.emit()
	else:
		var decel: float = move_speed * lerpf(2.0, 20.0, ground_friction) * ctx.friction_scale * delta
		velocity.x = move_toward(velocity.x, 0.0, decel)
		if _was_moving and is_zero_approx(velocity.x):
			_was_moving = false
			stopped_moving.emit()

# 把重力套用到垂直速度上
func _apply_vertical(ctx: MoveContext, delta: float) -> void:
	velocity += -up_direction * gravity * ctx.gravity_scale * delta

# 偵測角色朝向是否改變，改變就發出訊號
func _update_facing(input_dir: float) -> void:
	var dir := int(sign(input_dir))
	if dir != 0 and dir != _last_direction:
		_last_direction = dir
		direction_changed.emit(dir)

# 偵測這一幀是不是剛落地，是的話發出落地訊號
func _emit_landing(pre_on_floor: bool, pre_fall_speed: float) -> void:
	if is_on_floor() and not pre_on_floor and pre_fall_speed > 0.0:
		landed.emit(pre_fall_speed)
		Events.player_landed.emit(pre_fall_speed)

# 偵測這一幀是不是剛撞牆，是的話發出撞牆訊號
func _emit_wall_hit() -> void:
	if is_on_wall() and not _was_on_wall:
		wall_hit.emit()
	_was_on_wall = is_on_wall()

# ---- 提供給機制卡的公開 API（機制卡不得直接寫 velocity） ----

# 翻轉重力方向，重力翻轉卡用這個
func flip_gravity() -> void:
	up_direction = -up_direction

# 施加一次性衝量，擊退、彈跳這類卡用這個
func add_impulse(v: Vector2) -> void:
	velocity += v

# 縮放角色大小，變大變小卡用這個
func set_size_factor(f: float) -> void:
	size_factor = f
	scale = Vector2.ONE * f

# 讓角色受到傷害，內部委派給 Stats 扣血量；血量歸零時 Stats 會自動呼叫 kill()
func take_damage(amount: float = 1.0) -> void:
	if _is_dead:
		return
	Stats.add(Stats.HEALTH_KIND, -roundi(amount * _damage_scale))
	hurt.emit()
	Events.player_hurt.emit()

# 立刻讓角色死亡
func kill() -> void:
	if _is_dead:
		return
	_is_dead = true
	died.emit()
	Events.player_died.emit()

# 強制角色跳一次，倍率可以調跳多高，跳躍相關卡用這個
func force_jump(power_scale: float = 1.0) -> void:
	velocity -= velocity.project(up_direction)
	velocity += up_direction * jump_force * power_scale
	jumped.emit()
	Events.player_jumped.emit()

# 回傳角色現在是不是站在地面上
func is_on_ground() -> bool:
	return is_on_floor()

# 回傳玩家目前輸入的水平方向，範圍 -1 到 1
func get_move_input() -> float:
	return Input.get_axis("move_left", "move_right")
