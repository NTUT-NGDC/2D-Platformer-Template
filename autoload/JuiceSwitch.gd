extends Node

# Juice 總開關：按 0 一次關掉／打開全部 Juice，畫面右上角顯示「Juice：開」／「Juice：關」兩秒。
# 教學用的前後對照工具。JuiceBase 自己會來問 is_on()、聽 toggled，這裡不用知道有哪些 Juice。

# 總開關切換時發出，on = 現在是不是開著
signal toggled(on: bool)

const _KEY := KEY_0
# 不搶別人的輸入：用很低的優先權，而且永遠回傳「沒處理掉」
const _PRIORITY := -1000
const _SHOW_MS := 2000
const _FONT_SIZE := 12

var _on: bool = true
var _label: Label = null
var _hide_at_ms: int = 0

# 註冊總開關按鍵，建立右上角的提示文字
func _ready() -> void:
	InputRouter.bind_key(self, _KEY, InputRouter.PRESSED, _on_key_pressed, _PRIORITY)
	_create_label()

# 回傳 Juice 現在是不是開著，Juice 組件播放效果前用這個檢查
func is_on() -> bool:
	return _on

# 打開或關掉全部 Juice
func set_on(on: bool) -> void:
	if on == _on:
		return
	_on = on
	toggled.emit(_on)
	_show_label()
	print("[Juice 總開關] %s" % ("開" if _on else "關"))

# 按下總開關按鍵：切換開關，但不擋住其他也用這個鍵的人
func _on_key_pressed() -> bool:
	set_on(not _on)
	return false

# 建立右上角的提示文字，平常藏起來
func _create_label() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", _FONT_SIZE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.offset_right = -4
	_label.offset_top = 4
	_label.visible = false
	layer.add_child(_label)

# 顯示目前的開關狀態兩秒（用真實時間，不受頓幀影響）
func _show_label() -> void:
	_label.text = "Juice：%s" % ("開" if _on else "關")
	_label.visible = true
	_hide_at_ms = Time.get_ticks_msec() + _SHOW_MS

# 時間到就把提示文字藏起來
func _process(_delta: float) -> void:
	if _label.visible and Time.get_ticks_msec() >= _hide_at_ms:
		_label.visible = false
