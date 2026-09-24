@tool
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

const _SIGNAL_LINE_COLOR := Color(1.0, 0.85, 0.2, 0.85)

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
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	if open_mode != _MODE_SIGNAL:
		_detector.body_entered.connect(_on_detector_entered)
	_is_open = start_open
	_apply_state()

# 鑰匙／金幣門恢復到關卡開始時的狀態（用掉的鑰匙金幣由重生記憶退回，重生處理者呼叫）。
# 由訊號控制的門不重置：它的開關是別的零件決定的，重置了會跟控制它的按鈕對不上，可能卡關。
# 鑰匙／金幣設成「死亡不退回」時也不重置：付掉的拿不回來，門再關上就過不去了
func reset() -> void:
	if open_mode == _MODE_SIGNAL:
		return
	if consume and not Stats.is_reset_on_death(_get_kind()):
		return
	_is_open = start_open
	_apply_state()

# 鑰匙／金幣模式下，玩家碰到門時檢查 Stats 夠不夠，夠了就開門
func _on_detector_entered(body: Node) -> void:
	if _is_open or not body.is_in_group("player"):
		return
	var kind := _get_kind()
	if not Stats.has_at_least(kind, required_amount):
		return
	if consume:
		Stats.consume(kind, required_amount)
	activate()

# 這扇門要檢查的數值種類
func _get_kind() -> String:
	return "鑰匙" if open_mode == _MODE_KEY else "金幣"

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
	_shape.set_deferred("disabled", _is_open)
	_visual.modulate.a = 0.35 if _is_open else 1.0

# 編輯畫面持續請求重畫，讓虛線跟著訊號連接的變化即時更新
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：幫這個零件自己發出的每個訊號的每條連接畫一條虛線到目標節點
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_draw_signal_lines(opened)
	_draw_signal_lines(closed)

# 畫某個訊號目前所有連接的虛線
func _draw_signal_lines(sig: Signal) -> void:
	for conn in sig.get_connections():
		var callable: Callable = conn["callable"]
		var target: Object = callable.get_object()
		if target is Node2D:
			var target_node: Node2D = target
			draw_dashed_line(Vector2.ZERO, to_local(target_node.global_position), _SIGNAL_LINE_COLOR, 2.0, 6.0)
