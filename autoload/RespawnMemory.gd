extends Node

# 重生記憶：記錄踩過的重生點，由重生處理者（RespawnHandler）決定重生位置時查詢。
# 數值不在這裡記：死掉時放回去的金幣、門會自己把當初加的／扣的數值倒回（rewind_values()），
# 物件跟數值永遠一起動，不會出現「同一枚金幣撿兩次」。見 documents/00b_rooms_and_soft_respawn.md §5。

var _has_checkpoint: bool = false
var _checkpoint_position: Vector2 = Vector2.ZERO
var _room_checkpoints: Dictionary = {}      # 房間的 instance id(int) -> 那個房間裡最後踩到的重生點位置(Vector2)

# 接上重生點、死亡、過關的訊號
func _ready() -> void:
	Events.checkpoint_reached.connect(_on_checkpoint_reached)
	Events.player_died.connect(_on_player_died)
	Events.level_cleared.connect(_on_level_cleared)

# 踩到重生點：記成全關卡最後踩到的，也記成它所在房間的重生點
func _on_checkpoint_reached(checkpoint: Node2D) -> void:
	_has_checkpoint = true
	_checkpoint_position = checkpoint.global_position
	for room in get_tree().get_nodes_in_group("room"):
		if room.has_point(_checkpoint_position):
			_room_checkpoints[room.get_instance_id()] = _checkpoint_position
			break

# 玩家死了但場景裡沒有重生處理者：提醒學員，不然看起來像當機
func _on_player_died() -> void:
	if get_tree().get_first_node_in_group("respawn_handler") == null:
		print("[重生] 玩家死亡了，但場景裡沒有 RespawnHandler，所以不會重生。想要重生就把 blocks/RespawnHandler.tscn 拖進關卡")

# 到達終點：清空所有重生記憶
func _on_level_cleared() -> void:
	clear()

# 整關重來時呼叫：清空踩過的重生點（數值由放回去的物件自己倒回）
func restart_level() -> void:
	clear()

# 清空所有記錄，過關、整關重來時用；場景裡的重生點也跟著變回沒踩過，才能再踩一次
func clear() -> void:
	_has_checkpoint = false
	_checkpoint_position = Vector2.ZERO
	_room_checkpoints.clear()
	get_tree().call_group("checkpoint", "forget")

# 查詢有沒有踩過重生點
func has_checkpoint() -> bool:
	return _has_checkpoint

# 查詢最後踩到的重生點位置，沒踩過就回傳 (0, 0)
func get_checkpoint_position() -> Vector2:
	return _checkpoint_position

# 查詢某個房間裡有沒有踩過的重生點
func has_checkpoint_in(room: Node) -> bool:
	return _room_checkpoints.has(room.get_instance_id())

# 查詢某個房間裡最後踩到的重生點位置，沒踩過就回傳 (0, 0)
func get_checkpoint_position_in(room: Node) -> Vector2:
	return _room_checkpoints.get(room.get_instance_id(), Vector2.ZERO)
