extends Node

# 重生處理者：聽到玩家死亡後，等一下再把玩家復活，不重新載入場景。
# 放在關卡場景裡，學員看得到、刪得掉、換得掉；刪掉的話玩家死了就不會回來（遊戲不會壞）。
# 重生位置：同一個房間裡踩過的重生點 > 目前房間的重生點 > 踩過的重生點（沒有房間時）> 玩家一開始的位置。

@export_group("重生設定")
## 死亡後隔多久重生（秒）
@export_range(0.0, 3.0) var delay: float = 0.8
## 死亡後要怎麼重來：回到目前房間，或是整關從頭開始
@export_enum("回到目前房間", "整關重來") var mode: int = 0
## 重生時把房間裡的箱子、敵人、平台等零件復位（整關重來時復位整個關卡）
@export var reset_room_objects: bool = true
## 每次重生都發出「關卡重新開始」事件，給想在重來時做事的組件聽
@export var send_restart_signal: bool = true

const _MODE_ROOM := 0
const _MODE_LEVEL := 1

var _current_room: Node2D = null
var _start_position: Vector2 = Vector2.ZERO
var _has_start_position: bool = false
var _warned_no_room: bool = false

# 加入群組、接上訊號，記住玩家一開始的位置
func _ready() -> void:
	add_to_group("respawn_handler")
	Events.room_entered.connect(_on_room_entered)
	Events.player_died.connect(_on_player_died)
	if not _remember_start_position():
		_remember_start_position.call_deferred()
	if not _is_active_handler():
		push_warning("[重生] 場景裡有不只一個 RespawnHandler，只有第一個會生效")
		printerr("⚠ [重生] 場景裡有不只一個 RespawnHandler，%s 不會生效，可以刪掉" % name)

# 記住玩家一開始的位置，找得到玩家就回傳 true
func _remember_start_position() -> bool:
	if _has_start_position:
		return true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	_start_position = player.global_position
	_has_start_position = true
	return true

# 只有群組裡的第一個重生處理者會真的處理死亡，避免放兩個時玩家被復活兩次
func _is_active_handler() -> bool:
	return get_tree().get_first_node_in_group("respawn_handler") == self

# 記住玩家目前在哪個房間
func _on_room_entered(room: Node) -> void:
	_current_room = room as Node2D

# 玩家死亡：等 delay 秒，復位零件、還原數值，再把玩家復活到重生位置
func _on_player_died() -> void:
	if not _is_active_handler():
		return
	await get_tree().create_timer(delay).timeout
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("revive"):
		return
	if player.has_method("is_dead") and not player.is_dead():
		return  # 等待期間已經被別人復活了
	if mode == _MODE_LEVEL:
		_restart_level(player)
	else:
		_respawn_in_room(player)
	if send_restart_signal:
		Events.level_restarted.emit()

# 回到目前房間：只復位這個房間的零件，數值退回進房間（或踩重生點）當下
func _respawn_in_room(player: Node) -> void:
	if reset_room_objects:
		_reset_objects(player, _current_room)
	RespawnMemory.restore_values()
	_revive(player, _get_room_spawn_position())

# 整關重來：復位整個關卡的零件，數值退回最一開始，清空踩過的重生點，玩家回到起點
func _restart_level(player: Node) -> void:
	if reset_room_objects:
		_reset_objects(player, null)
	RespawnMemory.restart_level()
	_revive(player, _start_position)

# 通知大家要重生了，再請玩家復活到指定位置
func _revive(player: Node, at_position: Vector2) -> void:
	Events.respawn_requested.emit(player)
	player.revive(at_position)

# 決定「回到目前房間」模式要重生在哪裡
func _get_room_spawn_position() -> Vector2:
	var has_checkpoint: bool = RespawnMemory.has_checkpoint()
	var checkpoint_position: Vector2 = RespawnMemory.get_checkpoint_position()
	if _current_room != null and is_instance_valid(_current_room):
		if has_checkpoint and _current_room.has_point(checkpoint_position):
			return checkpoint_position
		return _current_room.get_spawn_point()
	if not _warned_no_room:
		_warned_no_room = true
		push_warning("[重生] 場景裡沒有 Room，玩家會重生在一開始的位置（踩過重生點就在重生點）")
		print("[重生] 場景裡沒有任何房間（Room），玩家會重生在一開始的位置；踩過重生點的話就在重生點。想分房間重生，把 blocks/Room.tscn 拖進關卡")
	if has_checkpoint:
		return checkpoint_position
	return _start_position

# 對範圍內所有有 reset() 的零件逐一呼叫；room 是 null 代表整個關卡。玩家身上的組件不算。
# 會移動的零件（箱子、敵人）用它一開始的位置判斷屬於哪個房間，被推到別的房間也會回到自己的房間
func _reset_objects(player: Node, room: Node2D) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var targets: Array[Node] = []
	_collect_resettable(scene, player, room, targets)
	for target in targets:
		target.reset()

# 遞迴收集範圍內有 reset() 的節點
func _collect_resettable(node: Node, player: Node, room: Node2D, out: Array[Node]) -> void:
	if node == player:
		return
	if node is Node2D and node.has_method("reset"):
		var home: Vector2 = node.get_reset_position() if node.has_method("get_reset_position") else (node as Node2D).global_position
		if room == null or room.has_point(home):
			out.append(node)
	for child in node.get_children():
		_collect_resettable(child, player, room, out)
