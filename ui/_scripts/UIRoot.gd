@tool
extends Control
class_name UIRoot

# 一整套 UI（HUD、暫停選單、過關畫面）的根節點：範本場景的最上層就是它。
# 依欄位建一份 Theme 套在自己身上，底下所有零件的字型、字的大小、配色自動跟著變，學員不用碰 Theme 編輯器。
# 編輯器裡改欄位馬上看得到。遊戲開始時如果不在 CanvasLayer 底下（例如直接拖進關卡），會自己移進一個，
# 才會固定在畫面上、不跟著鏡頭跑。暫停選單、過關畫面在遊戲暫停時也照樣能動。

## 這是哪一種畫面（範本已經選好，不用改）
@export_enum("HUD", "暫停選單", "過關畫面") var kind: int = KIND_HUD:
	set(value):
		kind = value
		_apply_process_mode()
## 這一整套 UI 用的字型，從檔案系統把字型檔拖進來；空白用專案預設的像素字
@export var font: Font:
	set(value):
		font = value
		_apply_theme()
## 字的大小（像素字型請用 12 的倍數）
@export_range(12, 48, 12) var font_size: int = 12:
	set(value):
		font_size = value
		_apply_theme()
## 配色：字、底色、按鈕、條的顏色一起換
@export_enum("預設", "暗色", "亮色", "復古綠", "糖果") var palette: int = PALETTE_DEFAULT:
	set(value):
		palette = value
		_apply_theme()

const KIND_HUD := 0
const KIND_PAUSE_MENU := 1
const KIND_CLEAR_SCREEN := 2

const PALETTE_DEFAULT := 0

# 每一種畫面放在哪一層：數字越大蓋在越上面（跟原本的預設 UI 一樣）
const _LAYERS := [1, 20, 10]

# 每套配色的顏色：text 字、dim 次要的字、panel 底色、button 按鈕、hover 滑過、pressed 按下、accent 條和拉桿、back 條的底
const _PALETTES := [
	{},
	{ "text": Color("e8e8f0"), "dim": Color("9a9ab0"), "panel": Color("1c1c28e6"), "button": Color("34344a"),
		"hover": Color("4a4a66"), "pressed": Color("26263a"), "accent": Color("7c8cff"), "back": Color("14141e") },
	{ "text": Color("2a2a33"), "dim": Color("6a6a78"), "panel": Color("f4f1eae6"), "button": Color("dedad0"),
		"hover": Color("cfcabd"), "pressed": Color("bdb7a8"), "accent": Color("3b82c4"), "back": Color("c8c3b6") },
	{ "text": Color("c8f0a0"), "dim": Color("7aa860"), "panel": Color("0f2410e6"), "button": Color("1e4220"),
		"hover": Color("2c5c2e"), "pressed": Color("153016"), "accent": Color("8ce060"), "back": Color("0a180b") },
	{ "text": Color("5a2a4a"), "dim": Color("9a6a88"), "panel": Color("fff0f6e6"), "button": Color("ffc8e0"),
		"hover": Color("ffb0d2"), "pressed": Color("f598c0"), "accent": Color("ff6fae"), "back": Color("ffe0ee") },
]

# 套用配色與字型、決定暫停時能不能動；遊戲中不在 CanvasLayer 底下的話移進一個
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_process_mode()
	_apply_theme()
	if not Engine.is_editor_hint() and not get_parent() is CanvasLayer:
		_move_to_layer.call_deferred()

# theme 由欄位自動產生：不存進場景檔、Inspector 也不顯示，學員改字型配色用上面的欄位
func _validate_property(property: Dictionary) -> void:
	if property.name == "theme":
		property.usage = PROPERTY_USAGE_NONE

# 讀目前配色裡某個角色的顏色（text、dim、panel、button、hover、pressed、accent、back），
# 配色是「預設」時回傳 fallback；顯示零件畫自己的預設樣式時用這個
func get_palette_color(role: String, fallback: Color) -> Color:
	return _PALETTES[palette].get(role, fallback)

# 依欄位建一份 Theme 套在自己身上，再通知底下的零件配色換了
func _apply_theme() -> void:
	if not is_inside_tree():
		return
	var t := Theme.new()
	if font != null:
		t.default_font = font
	t.default_font_size = font_size
	var colors: Dictionary = _PALETTES[palette]
	if not colors.is_empty():
		_add_palette(t, colors)
	theme = t
	_notify_children(self)

# 把一套配色寫進 Theme：字、按鈕、進度條、拉桿、面板
func _add_palette(t: Theme, c: Dictionary) -> void:
	t.set_color("font_color", "Label", c.text)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", c.text)
	t.set_color("font_disabled_color", "Button", c.dim)
	t.set_stylebox("normal", "Button", _box(c.button))
	t.set_stylebox("hover", "Button", _box(c.hover))
	t.set_stylebox("pressed", "Button", _box(c.pressed))
	t.set_stylebox("hover_pressed", "Button", _box(c.pressed))
	t.set_stylebox("disabled", "Button", _box(c.back))
	t.set_stylebox("focus", "Button", _outline(c.accent))
	t.set_color("font_color", "ProgressBar", c.text)
	t.set_stylebox("background", "ProgressBar", _box(c.back))
	t.set_stylebox("fill", "ProgressBar", _box(c.accent))
	t.set_stylebox("slider", "HSlider", _box(c.back, 2))
	t.set_stylebox("grabber_area", "HSlider", _box(c.accent, 2))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(c.accent, 2))
	t.set_stylebox("panel", "Panel", _box(c.panel))
	t.set_stylebox("panel", "PanelContainer", _box(c.panel))

# 純色的方框（像素風，不要圓角），margin 是內距
func _box(color: Color, margin: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin / 2.0
	box.content_margin_bottom = margin / 2.0
	return box

# 只有外框的方框，按鈕被選到（用鍵盤操作）時用
func _outline(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.set_border_width_all(1)
	box.border_color = color
	return box

# 往下找所有零件，有 _on_ui_root_changed 的就通知它配色或字型換了（零件不用往上找根節點）
func _notify_children(node: Node) -> void:
	for child in node.get_children():
		if child.has_method("_on_ui_root_changed"):
			child._on_ui_root_changed(self)
		_notify_children(child)

# 暫停選單、過關畫面在遊戲暫停時也要能動；HUD 跟著遊戲
func _apply_process_mode() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if kind == KIND_HUD else Node.PROCESS_MODE_ALWAYS

# 移進一個新的 CanvasLayer（擺在原本的位置），之後固定在畫面上、不跟著鏡頭跑
func _move_to_layer() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var layer := CanvasLayer.new()
	layer.name = "%sLayer" % name
	layer.layer = _LAYERS[kind]
	layer.process_mode = process_mode
	parent.add_child(layer)
	reparent(layer, false)
