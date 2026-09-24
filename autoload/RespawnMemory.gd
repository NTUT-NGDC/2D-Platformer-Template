extends Node

# 重生記憶：記錄「存檔點」當下的數值與踩過的重生點，由重生處理者（RespawnHandler）在重生時叫用。
# 死亡不會重新載入場景，所以這裡只管數值要退回哪個時間點，零件復位由各零件自己的 reset() 負責。
# 存檔點：場景裡有房間時是「進入房間的那一刻」；完全沒有房間時是「踩到重生點的那一刻」。
# 見 documents/01a_shared_systems.md §5。

var _has_checkpoint: bool = false
var _checkpoint_position: Vector2 = Vector2.ZERO
var _has_save_point: bool = false
var _save_snapshot: Dictionary = {}         # kind(String) -> int，存檔點當下的數值
var _initial_snapshot: Dictionary = {}      # kind(String) -> int，這個種類第一次被動到之前的值
var _has_room: bool = false

# 接上存檔點、死亡、過關與數值變化的訊號
func _ready() -> void:
	Events.room_entered.connect(_on_room_entered)
	Events.checkpoint_reached.connect(_on_checkpoint_reached)
	Events.player_died.connect(_on_player_died)
	Events.level_cleared.connect(_on_level_cleared)
	Stats.value_changed.connect(_on_stats_value_changed)

# 記下某個數值種類第一次變動之前的樣子，當作「還沒有任何存檔點」或「整關重來」時要還原的基準。
# ValueSettings 把 reset_on_death 關掉的種類不記錄，死亡完全不影響它們（例如累計分數）。
func _on_stats_value_changed(kind: String, old_value: int, _new_value: int) -> void:
	if kind == Stats.HEALTH_KIND or _initial_snapshot.has(kind) or not Stats.is_reset_on_death(kind):
		return
	_initial_snapshot[kind] = old_value

# 進入房間：這一刻就是新的存檔點。房間裡的零件重生時會全部復位，
# 所以數值也退回進房間當下，才不會出現「金幣被扣掉但道具沒回來」或「同一枚金幣撿兩次」
func _on_room_entered(_room: Node) -> void:
	_has_room = true
	_save_values()

# 踩到重生點：記錄位置；沒有房間的場景才把這一刻當成數值的存檔點
func _on_checkpoint_reached(checkpoint: Node2D) -> void:
	_has_checkpoint = true
	_checkpoint_position = checkpoint.global_position
	if not _has_room:
		_save_values()

# 把目前所有「會被死亡重置」的數值（血量除外）記成存檔點
func _save_values() -> void:
	_has_save_point = true
	_save_snapshot.clear()
	for kind in Stats.get_known_kinds():
		if kind != Stats.HEALTH_KIND and Stats.is_reset_on_death(kind):
			_save_snapshot[kind] = Stats.get_value(kind)

# 玩家死了但場景裡沒有重生處理者：提醒學員，不然看起來像當機
func _on_player_died() -> void:
	if get_tree().get_first_node_in_group("respawn_handler") == null:
		print("[重生] 玩家死亡了，但場景裡沒有 RespawnHandler，所以不會重生。想要重生就把 blocks/RespawnHandler.tscn 拖進關卡")

# 到達終點：清空所有重生記憶
func _on_level_cleared() -> void:
	clear()

# 回到存檔點重生時呼叫：數值退回存檔點當下；存檔點之後才第一次出現的種類（或根本沒有存檔點）退回最初的狀態
func restore_values() -> void:
	var snapshot: Dictionary = _initial_snapshot.duplicate()
	if _has_save_point:
		snapshot.merge(_save_snapshot, true)
	for kind in snapshot:
		Stats.set_value(kind, snapshot[kind])

# 整關重來時呼叫：數值退回最一開始，清空踩過的重生點
func restart_level() -> void:
	for kind in _initial_snapshot:
		Stats.set_value(kind, _initial_snapshot[kind])
	clear()

# 清空所有記錄，過關、整關重來時用
func clear() -> void:
	_has_checkpoint = false
	_checkpoint_position = Vector2.ZERO
	_has_save_point = false
	_save_snapshot.clear()
	_initial_snapshot.clear()

# 查詢有沒有踩過重生點
func has_checkpoint() -> bool:
	return _has_checkpoint

# 查詢最後踩到的重生點位置，沒踩過就回傳 (0, 0)
func get_checkpoint_position() -> Vector2:
	return _checkpoint_position
