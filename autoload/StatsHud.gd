extends Node

# Stats 的畫面呈現：訂閱 Stats.value_changed 自動同步，Stats 本身不知道這裡的存在。
# 學員不用擺任何 UI 節點。ValueSettings 把 show_in_hud 打開的種類一開場就顯示；
# 沒有 ValueSettings 的種類，第一次被實際加減到時才生出對應的那一列。

var _hud: CanvasLayer = null
var _hud_container: VBoxContainer = null
var _bars: Dictionary = {}    # kind(String) -> ProgressBar，血量這種特殊種類用這個
var _labels: Dictionary = {}  # kind(String) -> Label，其他種類用這個顯示「名稱：數字」
var _titles: Dictionary = {}  # kind(String) -> Label，血條前面的名字
var _corner_layer: CanvasLayer = null
var _corners: Dictionary = {}  # 角落 -> VBoxContainer，機制卡、零件的預設 UI 放這裡自動上下排

const CORNER_TOP_RIGHT := 0
const CORNER_BOTTOM_LEFT := 1

# 開始監聽 Stats 的數值變動與設定
func _ready() -> void:
	Stats.value_changed.connect(_on_value_changed)
	Stats.configured.connect(_on_configured)

# ValueSettings 套用設定：show_in_hud 打開就立刻顯示這一列，關掉就把已經顯示的那一列藏起來
func _on_configured(kind: String) -> void:
	if Stats.is_hud_visible(kind):
		if not _bars.has(kind) and not _labels.has(kind):
			_add_row(kind)
		_set_row_visible(kind, true)
		_refresh_row(kind)
	else:
		_set_row_visible(kind, false)

# 數值變動時：第一次看到這個種類就先生一列出來，然後把畫面同步成最新的值。
# ValueSettings 把 show_in_hud 關掉的種類永遠不出現在畫面上。
func _on_value_changed(kind: String, _old_value: int, _new_value: int) -> void:
	if not Stats.is_hud_visible(kind):
		return
	if not _bars.has(kind) and not _labels.has(kind):
		_add_row(kind)
	_refresh_row(kind)

# 顯示或藏起某個種類那一列，還沒生出來就不處理
func _set_row_visible(kind: String, row_visible: bool) -> void:
	var control: Control = _bars.get(kind, _labels.get(kind, null))
	if control != null:
		control.get_parent().visible = row_visible

# 拿到畫面某個角落的共用容器：機制卡、零件把自己的預設 UI 加進來，好幾個同時出現時自動上下排、不會疊在一起。
# 加進來的東西屬於這裡，不會跟著卡片一起刪掉，卡片被拔掉時要自己 queue_free 掉
func get_corner(corner: int) -> VBoxContainer:
	if _corners.has(corner):
		return _corners[corner]
	if _corner_layer == null:
		_corner_layer = CanvasLayer.new()
		add_child(_corner_layer)
	var box := VBoxContainer.new()
	if corner == CORNER_TOP_RIGHT:
		box.anchor_left = 1.0
		box.anchor_right = 1.0
		box.offset_left = -4.0
		box.offset_right = -4.0
		box.offset_top = 4.0
		box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		box.alignment = BoxContainer.ALIGNMENT_BEGIN
		box.child_entered_tree.connect(func(child: Node):
			if child is Control:
				child.size_flags_horizontal = Control.SIZE_SHRINK_END)
	else:
		box.anchor_top = 1.0
		box.anchor_bottom = 1.0
		box.offset_left = 4.0
		box.offset_top = -4.0
		box.offset_bottom = -4.0
		box.grow_vertical = Control.GROW_DIRECTION_BEGIN
		box.alignment = BoxContainer.ALIGNMENT_END
	_corner_layer.add_child(box)
	_corners[corner] = box
	return box

# 建立 HUD 用的 CanvasLayer，只在第一次真的需要顯示東西時才做
func _ensure_hud() -> void:
	if _hud != null:
		return
	_hud = CanvasLayer.new()
	add_child(_hud)
	_hud_container = VBoxContainer.new()
	_hud_container.position = Vector2(4, 4)
	_hud.add_child(_hud_container)

# 幫某個種類在 HUD 加一列；血量用血條，其他種類用「圖示＋數字」
func _add_row(kind: String) -> void:
	_ensure_hud()
	var row := HBoxContainer.new()
	if kind == Stats.HEALTH_KIND:
		var title := Label.new()
		_titles[kind] = title
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(60, 12)
		bar.show_percentage = false
		row.add_child(title)
		row.add_child(bar)
		_bars[kind] = bar
	else:
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(10, 10)
		var hue: float = float(absi(hash(kind)) % 360) / 360.0
		icon.color = Color.from_hsv(hue, 0.6, 0.9)
		var label := Label.new()
		row.add_child(icon)
		row.add_child(label)
		_labels[kind] = label
	_hud_container.add_child(row)

# 把某個種類那一列的畫面內容同步成 Stats 目前的數值與顯示名稱
func _refresh_row(kind: String) -> void:
	if _titles.has(kind):
		_titles[kind].text = Stats.get_display_name(kind)
	if _bars.has(kind):
		var bar: ProgressBar = _bars[kind]
		var max_value := Stats.get_max_value(kind)
		bar.max_value = max_value if max_value > 0 else max(Stats.get_value(kind), 1)
		bar.value = Stats.get_value(kind)
	elif _labels.has(kind):
		var label: Label = _labels[kind]
		label.text = "%s：%d" % [Stats.get_display_name(kind), Stats.get_value(kind)]
