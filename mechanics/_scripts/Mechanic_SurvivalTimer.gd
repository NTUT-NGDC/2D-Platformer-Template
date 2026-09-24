extends MechanicBase

# 存活計時：從掛上這張卡開始計時，存活到 target_seconds 就算過關，發出
# Events.level_cleared。倒數計時 UI 由組件自己生成 CanvasLayer，學員不用擺。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 存活幾秒後算過關
@export_range(5.0, 60.0) var target_seconds: float = 10.0

## 要不要在畫面上顯示倒數計時
@export var show_timer: bool = true

var _elapsed: float = 0.0
var _cleared: bool = false

var _hud: CanvasLayer = null
var _label: Label = null

# 視需要生成倒數計時的 UI
func _on_setup() -> void:
	if show_timer:
		_ensure_hud()
		_refresh_label()

# 累計存活時間，達標就發出過關事件，只觸發一次
func apply(ctx: MoveContext) -> void:
	if _cleared:
		return
	_elapsed = minf(target_seconds, _elapsed + ctx.delta)
	_refresh_label()
	if _elapsed >= target_seconds:
		_cleared = true
		Events.level_cleared.emit()
		Events.mechanic_event.emit("Mechanic_SurvivalTimer", "cleared")

# 重生時計時歸零重新開始
func on_respawn() -> void:
	_elapsed = 0.0
	_cleared = false
	_refresh_label()

# 建立倒數計時用的 CanvasLayer，畫面右上角，避免跟 Stats HUD（左上角）疊在一起
func _ensure_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.position = Vector2(-90, 4)
	_hud.add_child(box)
	_label = Label.new()
	box.add_child(_label)

# 把倒數計時文字同步成剩餘秒數
func _refresh_label() -> void:
	if _label == null:
		return
	var remaining: float = maxf(0.0, target_seconds - _elapsed)
	_label.text = "存活 %.1f" % remaining
