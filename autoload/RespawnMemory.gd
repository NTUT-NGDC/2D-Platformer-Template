extends Node

# 重生記憶：跨場景載入存活，記錄玩家踩到重生點當下的狀態，死亡重生時還原。
# 死亡＝重新載入場景（見 levels/_shared/Respawn.gd），這裡負責決定重生後：
# 玩家要出生在哪、數值要回到哪個時間點、哪些零件的狀態要維持。
# 見 documents/01a_shared_systems.md §5。

var _has_checkpoint: bool = false
var _checkpoint_position: Vector2 = Vector2.ZERO
var _checkpoint_snapshot: Dictionary = {}   # kind(String) -> int，踩到重生點當下的數值
var _initial_snapshot: Dictionary = {}      # kind(String) -> int，這個種類第一次被動到之前的值
var _persistent_states: Dictionary = {}     # 節點路徑(NodePath) -> 任意狀態，學員不用設定

func _ready() -> void:
	Events.checkpoint_reached.connect(_on_checkpoint_reached)
	Events.player_died.connect(_on_player_died)
	Events.level_cleared.connect(_on_level_cleared)
	Stats.value_changed.connect(_on_stats_value_changed)

# 記下某個數值種類第一次變動之前的樣子，當作「還沒踩過重生點」時死亡要還原的基準。
# ValueSettings 把 reset_on_death 關掉的種類不記錄，死亡完全不影響它們（例如累計分數）。
func _on_stats_value_changed(kind: String, old_value: int, _new_value: int) -> void:
	if kind == Stats.HEALTH_KIND or _initial_snapshot.has(kind) or not Stats.is_reset_on_death(kind):
		return
	_initial_snapshot[kind] = old_value

# 踩到重生點：記錄位置，以及目前所有「會被死亡重置」的數值（血量除外）
func _on_checkpoint_reached(checkpoint: Node2D) -> void:
	_has_checkpoint = true
	_checkpoint_position = checkpoint.global_position
	_checkpoint_snapshot.clear()
	for kind in Stats.get_known_kinds():
		if kind != Stats.HEALTH_KIND and Stats.is_reset_on_death(kind):
			_checkpoint_snapshot[kind] = Stats.get_value(kind)

# 死亡：數值退回重生點當下（沒踩過就退回最初的狀態），血量永遠補滿
func _on_player_died() -> void:
	var snapshot: Dictionary = _checkpoint_snapshot if _has_checkpoint else _initial_snapshot
	for kind in snapshot:
		Stats.set_value(kind, snapshot[kind])
	Stats.refill(Stats.HEALTH_KIND)

# 到達終點：清空所有重生記憶
func _on_level_cleared() -> void:
	clear()

# 清空所有記錄，切換場景、重新播放時用
func clear() -> void:
	_has_checkpoint = false
	_checkpoint_position = Vector2.ZERO
	_checkpoint_snapshot.clear()
	_initial_snapshot.clear()
	_persistent_states.clear()

# Player 自己在 _ready() 呼叫，把自己移動到重生點位置；沒踩過重生點就不動
func apply_position(player: Node2D) -> void:
	if _has_checkpoint:
		player.global_position = _checkpoint_position

# 記錄某個零件的狀態，key 用節點自己的路徑，學員不用設定
func remember(path: NodePath, value) -> void:
	_persistent_states[path] = value

# 查詢先前記錄的狀態，沒記過就回傳 default
func recall(path: NodePath, default = null):
	return _persistent_states.get(path, default)
