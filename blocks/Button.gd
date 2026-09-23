@tool
extends Area2D

# 按鈕：踩到（或被攻擊）時發出 turned_on / turned_off，行為依「觸發方式」決定。
# 拖進場景就能用，不用連任何線；要讓它控制別的零件，在「節點」面板把這兩個訊號連過去即可
# （見 documents/01a_shared_systems.md §6，這是零連線鐵律在零件之間唯一的例外）。

## 觸發方式：踩住的時候算開著、踩一下就切換開關、踩一下之後永久開著（不會再關）、被攻擊時觸發
@export_enum("踩住才開", "踩一下切換", "踩一下永久開", "被攻擊觸發") var mode: int = 0

## 誰踩得動：玩家跟箱子都算、只有玩家、只有箱子
@export_enum("玩家與箱子", "只有玩家", "只有箱子") var pressed_by: int = 0

## 開啟時發出，依「觸發方式」決定時機
signal turned_on
## 關閉時發出（踩一下永久開模式不會用到這個）
signal turned_off

const _MODE_HOLD := 0
const _MODE_TOGGLE := 1
const _MODE_PERMANENT := 2
const _MODE_HIT := 3

const _WHO_PLAYER_ONLY := 1
const _WHO_BOX_ONLY := 2

const _SIGNAL_LINE_COLOR := Color(1.0, 0.85, 0.2, 0.85)

@onready var _visual: ColorRect = $Visual

var _overlapping: Array[Node] = []
var _is_on: bool = false
var _permanently_triggered: bool = false

# 設定碰撞層／遮罩，並依模式決定要不要監聽踩踏。
# 永久開模式被踩過一次之後，重生記憶會記住，死亡重生後要重新發出 turned_on，
# 讓連接的目標（例如門）也一起恢復狀態。
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	collision_layer = 1 << 4          # 圖層 5「感應」
	collision_mask = (1 << 0) | (1 << 2)  # 圖層 1「玩家」、圖層 3「箱子」
	if mode != _MODE_HIT:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	if mode == _MODE_PERMANENT:
		add_to_group("persistent")
		if RespawnMemory.recall(get_path(), false):
			_permanently_triggered = true
			turned_on.emit()
	_update_visual()

# 判斷這個 body 算不算「踩得動」，依 pressed_by 欄位過濾
func _is_valid(body: Node) -> bool:
	match pressed_by:
		_WHO_PLAYER_ONLY:
			return body.is_in_group("player")
		_WHO_BOX_ONLY:
			return body.is_in_group("box")
		_:
			return body.is_in_group("player") or body.is_in_group("box")

# 有東西踩上來：依模式決定要不要 emit turned_on
func _on_body_entered(body: Node) -> void:
	if not _is_valid(body):
		return
	_overlapping.append(body)
	if _overlapping.size() != 1:
		return
	match mode:
		_MODE_HOLD:
			turned_on.emit()
		_MODE_TOGGLE:
			_toggle()
		_MODE_PERMANENT:
			if not _permanently_triggered:
				_permanently_triggered = true
				RespawnMemory.remember(get_path(), true)
				turned_on.emit()
	_update_visual()

# 東西離開：踩住才開模式在完全沒人踩的時候才 emit turned_off
func _on_body_exited(body: Node) -> void:
	_overlapping.erase(body)
	if mode == _MODE_HOLD and _overlapping.is_empty():
		turned_off.emit()
	_update_visual()

# 被攻擊打到，被攻擊觸發模式下每打一次切換開關
func take_hit(_damage: int, _knockback: Vector2, source: Node) -> void:
	Events.hit.emit(self, source)
	if mode != _MODE_HIT:
		return
	_toggle()
	_update_visual()

# 切換開關狀態並 emit 對應訊號
func _toggle() -> void:
	_is_on = not _is_on
	if _is_on:
		turned_on.emit()
	else:
		turned_off.emit()

# 依目前開關狀態換顏色，讓學員看得出按鈕有沒有生效
func _update_visual() -> void:
	if _visual == null:
		return
	var is_lit := _permanently_triggered or _is_on or (mode == _MODE_HOLD and not _overlapping.is_empty())
	_visual.color = Color(0.3, 0.85, 0.35) if is_lit else Color(0.55, 0.55, 0.55)

# 編輯畫面持續請求重畫，讓虛線跟著訊號連接的變化即時更新
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：幫這個零件自己發出的每個訊號的每條連接畫一條虛線到目標節點
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	_draw_signal_lines(turned_on)
	_draw_signal_lines(turned_off)

# 畫某個訊號目前所有連接的虛線
func _draw_signal_lines(sig: Signal) -> void:
	for conn in sig.get_connections():
		var callable: Callable = conn["callable"]
		var target: Object = callable.get_object()
		if target is Node2D:
			var target_node: Node2D = target
			draw_dashed_line(Vector2.ZERO, to_local(target_node.global_position), _SIGNAL_LINE_COLOR, 2.0, 6.0)
