extends Node

# 暫停選單：每一關都有，學員不用擺任何東西。按 Esc 或 P 暫停／繼續。
# 選單裡可以調主音量、音效、音樂三條匯流排的音量（記在 user:// 的設定檔，下次開遊戲還是一樣），
# 也可以繼續遊戲、整關重來（關卡裡有 RespawnHandler 才有）、離開遊戲（網頁版沒有）。

const _SETTINGS_PATH := "user://settings.cfg"
# [匯流排名稱, 選單上顯示的名稱, 預設音量]
const _BUSES := [["Master", "主音量", 0.8], ["SFX", "音效", 1.0], ["BGM", "音樂", 0.8]]
const _KEYS := [KEY_ESCAPE, KEY_P]
const _FONT_SIZE := 12
const _TITLE_SIZE := 24
# 拉音效拉桿時播的試聽音效；拖著拉時最快隔這麼久才播一次（毫秒），免得疊成一團
const _PREVIEW_SOUND := preload("res://sfx/pickup.wav")
const _PREVIEW_GAP_MS := 120

var _layer: CanvasLayer = null
var _resume_button: Button = null
var _restart_button: Button = null
var _value_labels: Dictionary = {}   # 匯流排名稱 -> 顯示百分比的 Label
var _volumes: Dictionary = {}        # 匯流排名稱 -> 線性音量 0～1
var _open: bool = false
var _warned_p: bool = false
var _preview: AudioStreamPlayer = null
var _last_preview_ms: int = -_PREVIEW_GAP_MS

# 讀回上次的音量並套用，建立（先藏起來的）選單畫面；暫停時也要收得到按鍵
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_volumes()
	for bus in _BUSES:
		_apply_volume(bus[0])
	_build_ui()
	_preview = AudioStreamPlayer.new()
	_preview.stream = _PREVIEW_SOUND
	_preview.bus = &"SFX"
	add_child(_preview)

# 按 Esc 或 P：開著就關、關著就開
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = (event as InputEventKey).physical_keycode
	if key not in _KEYS:
		return
	if key == KEY_P and _is_p_taken():
		return
	get_viewport().set_input_as_handled()
	if _open:
		close()
	else:
		open()

# 打開暫停選單；過關畫面這類別人造成的暫停中就不開，免得關掉時把別人的暫停一起解除
func open() -> void:
	if _open or get_tree().paused:
		return
	_open = true
	_restart_button.visible = _find_respawn_handler() != null
	if not _restart_button.visible:
		print("[暫停選單] 關卡裡沒有 RespawnHandler，選單裡不會有「整關重來」。想要的話把 blocks/RespawnHandler.tscn 拖進關卡")
	_layer.visible = true
	get_tree().paused = true
	_resume_button.grab_focus()

# 關掉暫停選單，繼續遊戲
func close() -> void:
	if not _open:
		return
	_open = false
	_layer.visible = false
	get_tree().paused = false

# 回傳暫停選單現在是不是開著
func is_open() -> bool:
	return _open

# P 已經被學員或組件拿去當別的按鍵（例如按鍵觸發器、按鍵設定）時讓給它，只用 Esc 暫停，第一次提醒一下
func _is_p_taken() -> bool:
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and ((e as InputEventKey).physical_keycode == KEY_P or (e as InputEventKey).keycode == KEY_P):
				if not _warned_p:
					_warned_p = true
					print("[暫停選單] P 已經被別的東西用掉了（%s），暫停請按 Esc" % action)
				return true
	return false

# 整關重來：關掉選單，終點恢復成還沒踩過，請重生處理者整關重來
func _on_restart_pressed() -> void:
	var handler := _find_respawn_handler()
	close()
	if handler == null:
		return
	get_tree().call_group("goal", "reset")
	handler.restart_level_now()

# 離開遊戲（桌面版）
func _on_quit_pressed() -> void:
	get_tree().quit()

# 找出場景裡可以整關重來的重生處理者
func _find_respawn_handler() -> Node:
	var handler := get_tree().get_first_node_in_group("respawn_handler")
	if handler != null and handler.has_method("restart_level_now"):
		return handler
	return null

# ---- 音量

# 拉桿拉動：更新音量、百分比文字，存進設定檔
func _on_volume_changed(value: float, bus_name: String) -> void:
	_volumes[bus_name] = value
	_apply_volume(bus_name)
	_value_labels[bus_name].text = "%d%%" % roundi(value * 100.0)
	_save_volumes()
	if bus_name == "SFX":
		_play_preview()

# 播一下試聽音效，讓學員聽得到音效現在多大聲
func _play_preview() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_preview_ms < _PREVIEW_GAP_MS:
		return
	_last_preview_ms = now
	_preview.play()

# 把記下的音量套用到匯流排，拉到 0 就直接靜音
func _apply_volume(bus_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_warning("[暫停選單] 找不到「%s」匯流排，這條的音量沒辦法調；請確認 default_bus_layout.tres 還在" % bus_name)
		printerr("⚠ [暫停選單] 找不到「%s」匯流排，這條的音量沒辦法調" % bus_name)
		return
	var value: float = _volumes[bus_name]
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))

# 從設定檔讀回上次的音量，沒有就用預設值
func _load_volumes() -> void:
	var config := ConfigFile.new()
	config.load(_SETTINGS_PATH)
	for bus in _BUSES:
		_volumes[bus[0]] = clampf(float(config.get_value("audio", bus[0], bus[2])), 0.0, 1.0)

# 把目前的音量存進設定檔
func _save_volumes() -> void:
	var config := ConfigFile.new()
	config.load(_SETTINGS_PATH)
	for bus_name in _volumes:
		config.set_value("audio", bus_name, _volumes[bus_name])
	config.save(_SETTINGS_PATH)

# ---- 畫面

# 用程式組出選單：半透明黑底、標題、三條音量拉桿、按鈕
func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	_layer.visible = false
	add_child(_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	center.add_child(list)

	var title := _make_label("暫停", _TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	list.add_child(grid)
	for bus in _BUSES:
		_add_volume_row(grid, bus[0], bus[1])

	_resume_button = _make_button("繼續遊戲", close)
	list.add_child(_resume_button)
	_restart_button = _make_button("整關重來", _on_restart_pressed)
	list.add_child(_restart_button)
	if not OS.has_feature("web"):
		list.add_child(_make_button("離開遊戲", _on_quit_pressed))
	list.add_child(_make_label("Esc／P 繼續", _FONT_SIZE, Color(0.75, 0.75, 0.75)))
	center.sort_children.connect(_snap_to_pixels.bind(center))

# 加一列音量：名稱、拉桿、百分比
func _add_volume_row(grid: GridContainer, bus_name: String, label_text: String) -> void:
	grid.add_child(_make_label(label_text, _FONT_SIZE))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(120, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value = _volumes[bus_name]
	slider.value_changed.connect(_on_volume_changed.bind(bus_name))
	grid.add_child(slider)
	var value_label := _make_label("%d%%" % roundi(_volumes[bus_name] * 100.0), _FONT_SIZE)
	value_label.custom_minimum_size = Vector2(36, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(value_label)
	_value_labels[bus_name] = value_label

# 做一個指定字級（與顏色）的文字
func _make_label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

# 做一個按下去會呼叫 callback 的按鈕
func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", _FONT_SIZE)
	button.pressed.connect(callback)
	return button

# 容器置中算出來的位置常常落在半個像素上，像素字型會糊掉，排好之後捨去成整數像素
func _snap_to_pixels(container: Container) -> void:
	for child in container.get_children():
		if child is Control:
			(child as Control).position = (child as Control).position.floor()
