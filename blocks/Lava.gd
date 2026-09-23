extends Node2D

# 岩漿：實心，站在上面會每秒扣血；instant_kill 開啟時站上去直接死亡。
# 拖進場景就能用，不用連任何線。

## 每秒扣血量，instant_kill 關閉時才有作用
@export_range(1.0, 50.0) var damage_per_second: float = 10.0

## 站上去直接死亡，不用慢慢扣血
@export var instant_kill: bool = false

const _TICK_INTERVAL := 1.0

@onready var _shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _detector: Area2D = $Detector

var _overlapping_players: Array[Node] = []
var _tick_elapsed: float = 0.0

# 加入 hazard／lava group，設定碰撞層／遮罩
func _ready() -> void:
	add_to_group("hazard")
	add_to_group("lava")
	_detector.collision_layer = 0
	_detector.collision_mask = 1 << 0  # 圖層 1「玩家」
	_detector.body_entered.connect(_on_detector_entered)
	_detector.body_exited.connect(_on_detector_exited)

# 玩家碰到：即死模式直接殺死，否則列入每秒扣血名單
func _on_detector_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if instant_kill:
		if body.has_method("kill"):
			body.kill()
		return
	_overlapping_players.append(body)

# 玩家離開，移出扣血名單
func _on_detector_exited(body: Node) -> void:
	_overlapping_players.erase(body)

# 每秒對站在上面的玩家扣一次血
func _physics_process(delta: float) -> void:
	if instant_kill or _overlapping_players.is_empty():
		_tick_elapsed = 0.0
		return
	_tick_elapsed += delta
	if _tick_elapsed < _TICK_INTERVAL:
		return
	_tick_elapsed -= _TICK_INTERVAL
	for body in _overlapping_players:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage_per_second)
