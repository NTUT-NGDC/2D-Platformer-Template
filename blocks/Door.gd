extends Node2D

# 門：實心，關閉時擋住玩家，打開時碰撞消失、變半透明。
# 「由訊號控制」模式不會自動檢查任何東西，只能靠 activate/deactivate/toggle 這三個函式控制——
# 在「節點」面板把別的零件的訊號連過來（例如按鈕的 turned_on）就能組合出機關；
# 「鑰匙」「金幣數量」模式則是玩家碰到門的時候自動檢查 Stats。

## 開門方式：由其他零件的訊號控制、玩家帶著足夠的鑰匙、玩家帶著足夠的金幣
@export_enum("由訊號控制", "鑰匙", "金幣數量") var open_mode: int = 0

## 鑰匙或金幣模式下，需要達到的數量
@export_range(1, 99) var required_amount: int = 1

## 打開時是否要消耗掉那些鑰匙／金幣
@export var consume: bool = true

## 一開始就是開著的
@export var start_open: bool = false

## 開啟時發出
signal opened
## 關閉時發出
signal closed

const _MODE_SIGNAL := 0
const _MODE_KEY := 1
const _MODE_COIN := 2

@onready var _shape: CollisionShape2D = $Body/CollisionShape2D
@onready var _visual: ColorRect = $Visual
@onready var _detector: Area2D = $Detector

var _is_open: bool = false

## 開啟
func activate() -> void:
	_set_open(true)

## 關閉
func deactivate() -> void:
	_set_open(false)

## 切換
func toggle() -> void:
	_set_open(not _is_open)

# 依 open_mode 決定要不要監聽玩家碰門，並套用一開始的開關狀態
func _ready() -> void:
	add_to_group("signal_source")
	if open_mode != _MODE_SIGNAL:
		_detector.body_entered.connect(_on_detector_entered)
	_is_open = start_open
	_apply_state()

# 鑰匙／金幣模式下，玩家碰到門時檢查 Stats 夠不夠，夠了就開門
func _on_detector_entered(body: Node) -> void:
	if _is_open or not body.is_in_group("player"):
		return
	var kind := "鑰匙" if open_mode == _MODE_KEY else "金幣"
	if not Stats.has_at_least(kind, required_amount):
		return
	if consume:
		Stats.consume(kind, required_amount)
	activate()

# 真正切換開關狀態，狀態沒變就不重複處理
func _set_open(is_open: bool) -> void:
	if is_open == _is_open:
		return
	_is_open = is_open
	_apply_state()
	if is_open:
		opened.emit()
	else:
		closed.emit()

# 把目前的開關狀態套用到碰撞與外觀上
func _apply_state() -> void:
	_shape.disabled = _is_open
	_visual.modulate.a = 0.35 if _is_open else 1.0
