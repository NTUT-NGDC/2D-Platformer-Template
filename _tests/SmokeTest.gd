extends Node

# 自動化煙霧測試。規格見 documents/00_foundation.md 第 7 節。
# 掃 mechanics/ 與 juice/ 資料夾，不需要手動維護清單。

const PLAYER_SCENE := preload("res://player/Player.tscn")

var _player: CharacterBody2D
var _mechanics_container: Node2D
var _juice_container: Node2D
var _failed := false

func _ready() -> void:
	_setup_player()
	await _run_all_steps()

func _fail(msg: String) -> void:
	_failed = true
	printerr("✗ 煙霧測試失敗：%s" % msg)

func _setup_player() -> void:
	var ground := StaticBody2D.new()
	var ground_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 32)
	ground_shape.shape = shape
	ground.add_child(ground_shape)
	ground.position = Vector2(0, 200)
	add_child(ground)

	_player = PLAYER_SCENE.instantiate()

	var visual := Node2D.new()
	visual.name = "Visual"
	visual.add_to_group("player_visual")
	_player.add_child(visual)

	_mechanics_container = Node2D.new()
	_mechanics_container.name = "Mechanics"
	_player.add_child(_mechanics_container)

	_juice_container = Node2D.new()
	_juice_container.name = "Juice"
	_player.add_child(_juice_container)

	add_child(_player)

func _run_all_steps() -> void:
	await get_tree().process_frame

	var mechanic_scenes := _scan_scenes("res://mechanics")
	var juice_scenes := _scan_scenes("res://juice")

	# 1. 逐一實例化每一張機制卡
	for path in mechanic_scenes:
		await _test_single(path, _mechanics_container)
	await _clear_container(_mechanics_container)
	await _assert_can_move("單一機制卡")

	# 2. 隨機組合 3 個機制卡同時掛載
	if mechanic_scenes.size() > 0:
		await _test_combo(mechanic_scenes, _mechanics_container, 3)
		await _clear_container(_mechanics_container)
		await _assert_can_move("機制卡組合")

	# 3. 逐一實例化每個 Juice 組件
	for path in juice_scenes:
		await _test_single(path, _juice_container)
	await _clear_container(_juice_container)
	await _assert_can_move("單一 Juice")

	# 4. 同時掛 6 個 Juice 組件
	if juice_scenes.size() > 0:
		await _test_combo(juice_scenes, _juice_container, 6)
		await _clear_container(_juice_container)
		await _assert_can_move("Juice 組合")

	# 5. 觸發頓幀 10 次
	await _test_hitstop()
	await _assert_can_move("頓幀測試")

	# 6. 連續 kill / revive 10 次，每次重生後狀態都要歸零
	await _test_kill_revive()
	await _assert_can_move("死亡重生測試")

	if _failed:
		print("SMOKE TEST FAILED")
		get_tree().quit(1)
	else:
		print("SMOKE TEST PASSED")
		get_tree().quit(0)

func _scan_scenes(root_path: String) -> Array[String]:
	var result: Array[String] = []
	_scan_dir(root_path, result)
	return result

func _scan_dir(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full_path := path.path_join(entry)
			if dir.current_is_dir():
				_scan_dir(full_path, result)
			elif entry.ends_with(".tscn"):
				result.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

func _wait_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _test_single(path: String, container: Node) -> void:
	var scene: PackedScene = load(path)
	var inst: Node = scene.instantiate()
	container.add_child(inst)
	await _wait_frames(60)
	if not is_instance_valid(_player):
		_fail("測試 %s 時 Player 消失了" % path)
	inst.queue_free()
	await get_tree().process_frame

func _test_combo(paths: Array[String], container: Node, count: int) -> void:
	var shuffled := paths.duplicate()
	shuffled.shuffle()
	var picked: Array = shuffled.slice(0, mini(count, shuffled.size()))
	var instances: Array[Node] = []
	for path in picked:
		var scene: PackedScene = load(path)
		var inst: Node = scene.instantiate()
		container.add_child(inst)
		instances.append(inst)
	await _wait_frames(60)
	if not is_instance_valid(_player):
		_fail("組合測試（%s）時 Player 消失了" % container.name)
	for inst in instances:
		inst.queue_free()
	await get_tree().process_frame

func _test_hitstop() -> void:
	for i in 10:
		Events.hitstop_requested.emit(0.05)
		await _wait_frames(3)
	await get_tree().create_timer(0.5, true, false, true).timeout
	if not is_equal_approx(Engine.time_scale, 1.0):
		_fail("頓幀結束後 Engine.time_scale 應為 1.0，實際為 %s" % Engine.time_scale)
		Engine.time_scale = 1.0

# 掛上重力翻轉、忽大忽小、越跑越快，每一輪先把狀態弄亂（翻轉、變大、扣血）再死亡、復活，
# 檢查重生後重力、角色圖方向、體型、血量、死亡狀態都回到正確的值
func _test_kill_revive() -> void:
	var flip: Node = load("res://mechanics/Mechanic_GravityFlip.tscn").instantiate()
	var size: Node = load("res://mechanics/Mechanic_SizeShift.tscn").instantiate()
	var ramp: Node = load("res://mechanics/Mechanic_SpeedRamp.tscn").instantiate()
	for card in [flip, size, ramp]:
		_mechanics_container.add_child(card)
	await _wait_frames(5)
	var respawned_count := [0]
	var on_respawned := func(_p): respawned_count[0] += 1
	Events.player_respawned.connect(on_respawned)
	var spawn := Vector2(0, 150)
	var visual: Node2D = _player.visual
	for i in 10:
		flip._try_flip()
		size._toggle()
		_player.take_damage(1.0)
		await _wait_frames(3)
		_player.kill()
		if not _player.is_dead():
			_fail("第 %d 輪 kill() 之後 is_dead() 應該是 true" % (i + 1))
		await _wait_frames(2)
		_player.revive(spawn)
		var round_name := "第 %d 輪重生後" % (i + 1)
		if _player.is_dead():
			_fail("%s is_dead() 應該是 false" % round_name)
		if not _player.global_position.is_equal_approx(spawn):
			_fail("%s 位置應該是 %s，實際是 %s" % [round_name, spawn, _player.global_position])
		if _player.up_direction != Vector2.UP:
			_fail("%s 重力方向沒有復位" % round_name)
		if visual != null and visual.scale.y < 0.0:
			_fail("%s 角色圖還是上下顛倒" % round_name)
		if not is_equal_approx(_player.size_factor, size.small_scale):
			_fail("%s 體型應該是 %s，實際是 %s" % [round_name, size.small_scale, _player.size_factor])
		if Stats.get_value(Stats.HEALTH_KIND) != Stats.get_max_value(Stats.HEALTH_KIND):
			_fail("%s 血量沒有補滿" % round_name)
		await _wait_frames(3)
	if respawned_count[0] != 10:
		_fail("player_respawned 應該發出 10 次，實際 %d 次" % respawned_count[0])
	Events.player_respawned.disconnect(on_respawned)
	await _clear_container(_mechanics_container)
	_player.set_size_factor(1.0)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
	await get_tree().process_frame

func _assert_can_move(stage_name: String) -> void:
	_player.position = Vector2.ZERO
	_player.velocity = Vector2.ZERO
	var start_x: float = _player.position.x
	Input.action_press("move_right")
	await _wait_frames(30)
	Input.action_release("move_right")
	if is_equal_approx(_player.position.x, start_x):
		_fail("「%s」階段後，拔除組件時 Player 無法移動" % stage_name)
