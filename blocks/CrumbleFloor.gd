extends Node2D

# 崩塌地板：實心，踩上去後先抖動提示，過 break_delay 秒後碎裂消失；依 respawn_time
# 決定要不要重生（0 表示不重生）。拖進場景就能用，不用連任何線。

## 踩上去後幾秒碎裂
@export_range(0.1, 5.0) var break_delay: float = 0.6

## 碎裂後幾秒重生，0 表示不會重生
@export_range(0.0, 10.0) var respawn_time: float = 3.0

## 誰踩得動：只有玩家會觸發、任何物體（含箱子）都會觸發
@export_enum("只有玩家", "任何物體") var triggered_by: int = 0

## 開始碎裂時發出，給學員自己接特效／音效用
signal crumbled

const _WHO_PLAYER_ONLY := 0
const _SHAKE_AMOUNT := 2.0

@onready var _shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _visual: ColorRect = $Visual
@onready var _detector: Area2D = $Detector

var _visual_origin: Vector2
var _is_triggered: bool = false
var _is_broken: bool = false
var _shake_time_left: float = 0.0

# 設定碰撞層／遮罩，記住外觀原始位置
func _ready() -> void:
	add_to_group("signal_source")
	_visual_origin = _visual.position
	_detector.collision_layer = 0
	_detector.collision_mask = (1 << 0) | (1 << 2)  # 圖層 1「玩家」、圖層 3「箱子」
	_detector.body_entered.connect(_on_detector_entered)

# 判斷這個 body 算不算踩得動，依 triggered_by 過濾
func _is_valid(body: Node) -> bool:
	if triggered_by == _WHO_PLAYER_ONLY:
		return body.is_in_group("player")
	return body.is_in_group("player") or body.is_in_group("box")

# 有東西踩上來：開始倒數，過 break_delay 秒後碎裂
func _on_detector_entered(body: Node) -> void:
	if _is_triggered or _is_broken or not _is_valid(body):
		return
	_is_triggered = true
	_shake_time_left = break_delay
	get_tree().create_timer(break_delay).timeout.connect(_break)

# 倒數期間讓外觀小幅度隨機抖動，給玩家看得到的碎裂提示
func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		return
	_shake_time_left -= delta
	if _shake_time_left <= 0.0:
		_visual.position = _visual_origin
		return
	_visual.position = _visual_origin + Vector2(
		randf_range(-_SHAKE_AMOUNT, _SHAKE_AMOUNT),
		randf_range(-_SHAKE_AMOUNT, _SHAKE_AMOUNT)
	)

# 真正碎裂：關閉碰撞、隱藏外觀、發出訊號，依 respawn_time 決定要不要重生
func _break() -> void:
	if _is_broken:
		return
	_is_broken = true
	_shape.disabled = true
	_visual.visible = false
	crumbled.emit()
	if respawn_time > 0.0:
		get_tree().create_timer(respawn_time).timeout.connect(_respawn)

# 重生：恢復碰撞、外觀與觸發狀態
func _respawn() -> void:
	_is_broken = false
	_is_triggered = false
	_shape.disabled = false
	_visual.visible = true
	_visual.position = _visual_origin
