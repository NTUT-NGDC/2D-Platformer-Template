@tool
extends Label

# 換字的 Label：拖進選單、HUD 或關卡，在 Inspector 打好平常的字、換過的字，
# 再把按鈕、勾選框、零件的訊號連到這裡的 show_normal／show_active／toggle／set_on／next_text…，字就會換。
# 字型、大小、對齊照 Label 平常的欄位調；換顏色在「換字時的顏色」選。

## 平常顯示的字（一開始、show_normal 時）
@export var normal_text: String = "平常的字":
	set(value):
		normal_text = value
		_refresh_editor()
## 換過的字（show_active、toggle、勾選框勾著時）；空白的話 show_active 不會換
@export var active_text: String = "換過的字":
	set(value):
		active_text = value
		_refresh_editor()
## 更多段字：按「新增元素」再打字，next_text／previous_text 照 平常 → 換過 → 這裡 的順序換；空的格子跳過
@export var more_texts: Array[String] = []:
	set(value):
		more_texts = value
		update_configuration_warnings()
## next_text 換到最後一段之後回到第一段；不勾就停在最後一段（previous_text 也一樣停在第一段）
@export var loop_texts: bool = true
## 換字時要不要換顏色：不換（照 Label、UI 配色原本的顏色）、換（換過的字和更多段字用 active_color）
@export_enum("不換顏色", "換顏色") var color_style: int = 0:
	set(value):
		color_style = value
		notify_property_list_changed()
		update_configuration_warnings()
## 換過的字的顏色（「color_style」選換顏色時才出現）；平常的字照原本的顏色
@export var active_color: Color = Color(1.0, 0.85, 0.3):
	set(value):
		active_color = value
		update_configuration_warnings()

const COLOR_CHANGE := 1

var _index: int = 0   # 現在顯示第幾段（0 是平常的字）
var _own_color: Variant = null   # 學員自己在 Label 設的字顏色（Theme Overrides），換回平常的字時還原

# 遊戲開始先顯示平常的字；設定有問題就在輸出面板說
func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_editor()
		return
	if has_theme_color_override("font_color"):
		_own_color = get_theme_color("font_color")
	for problem in _get_configuration_warnings():
		_warn(problem)
	_show(0)

# Label 原本的 text 欄位藏起來（改用 normal_text），選換顏色以外的時候隱藏 active_color
func _validate_property(property: Dictionary) -> void:
	if property.name == "text":
		property.usage = PROPERTY_USAGE_STORAGE
	elif property.name == "active_color" and color_style != COLOR_CHANGE:
		property.usage = PROPERTY_USAGE_NONE

# 編輯器裡的黃色驚嘆號：沒有字可以換、更多段字有空格子、換的顏色看不到
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if active_text.strip_edges().is_empty() and _clean_more().is_empty():
		warnings.append("active_text 和 more_texts 都是空的，訊號連過來也沒有字可以換")
	if _clean_more().size() < more_texts.size():
		warnings.append("more_texts 有空的格子，遊戲中會跳過")
	if color_style == COLOR_CHANGE and active_color.a <= 0.0:
		warnings.append("active_color 的透明度是 0，換過的字會看不到：把取色器的 A 拉回來")
	return warnings

# 換回平常的字
func show_normal(..._args: Array) -> void:
	_show(0)

# 換成換過的字（active_text）；空白的話印警告、不換
func show_active(..._args: Array) -> void:
	if active_text.strip_edges().is_empty():
		_warn("show_active 被呼叫了，但 active_text 是空的，字沒有換")
		return
	_show(1)

# 平常的字和換過的字互換，按鈕的 pressed 連過來
func toggle(..._args: Array) -> void:
	if _index == 0:
		show_active()
	else:
		show_normal()

# 勾選框的 toggled 連過來：勾著顯示換過的字、取消勾顯示平常的字
func set_on(on: bool, ..._args: Array) -> void:
	if on:
		show_active()
	else:
		show_normal()

# 跟 set_on 相反：勾著顯示平常的字、取消勾顯示換過的字
func set_off(off: bool, ..._args: Array) -> void:
	set_on(not off)

# 換下一段；最後一段之後回到第一段（loop_texts 沒勾就停在最後一段）
func next_text(..._args: Array) -> void:
	var count := _texts().size()
	var next := _index + 1
	if next >= count:
		next = 0 if loop_texts else count - 1
	_show(next)

# 換上一段；第一段之前回到最後一段（loop_texts 沒勾就停在第一段）
func previous_text(..._args: Array) -> void:
	var count := _texts().size()
	var previous := _index - 1
	if previous < 0:
		previous = count - 1 if loop_texts else 0
	_show(previous)

# 換成第一段（平常的字）
func show_first(..._args: Array) -> void:
	_show(0)

# 換成最後一段
func show_last(..._args: Array) -> void:
	_show(_texts().size() - 1)

# 所有可以換的字，照順序：平常的字、換過的字（有填才算）、更多段字（空格子跳過）
func _texts() -> PackedStringArray:
	var texts := PackedStringArray([normal_text.strip_edges()])
	if not active_text.strip_edges().is_empty():
		texts.append(active_text.strip_edges())
	texts.append_array(_clean_more())
	return texts

# 更多段字去掉空格子、頭尾空白
func _clean_more() -> PackedStringArray:
	var clean := PackedStringArray()
	for item in more_texts:
		if not item.strip_edges().is_empty():
			clean.append(item.strip_edges())
	return clean

# 顯示第幾段字，照 color_style 換顏色（平常的字換回原本的顏色）
func _show(index: int) -> void:
	var texts := _texts()
	_index = clampi(index, 0, texts.size() - 1)
	text = texts[_index]
	if color_style == COLOR_CHANGE and _index > 0:
		add_theme_color_override("font_color", active_color)
	elif _own_color != null:
		add_theme_color_override("font_color", _own_color)
	else:
		remove_theme_color_override("font_color")

# 編輯器裡改了欄位：畫面上顯示平常的字、重算黃色驚嘆號
func _refresh_editor() -> void:
	if not is_inside_tree():
		return
	if Engine.is_editor_hint():
		text = normal_text.strip_edges()
	update_configuration_warnings()

# 在輸出面板印中文警告
func _warn(message: String) -> void:
	push_warning("[%s] %s" % [name, message])
	printerr("⚠ [%s] %s" % [name, message])
