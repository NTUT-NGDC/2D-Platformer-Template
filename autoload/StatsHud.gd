extends Node

# Stats 的畫面呈現：訂閱 Stats.value_changed 自動同步，Stats 本身不知道這裡的存在。
# 學員不用擺任何 UI 節點，數值第一次被實際加減到時，這裡才會生出對應的那一列。

var _hud: CanvasLayer = null
var _hud_container: VBoxContainer = null
var _bars: Dictionary = {}    # kind(String) -> ProgressBar，血量這種特殊種類用這個
var _labels: Dictionary = {}  # kind(String) -> Label，其他種類用這個顯示「名稱：數字」

# 開始監聽 Stats 的數值變動
func _ready() -> void:
	Stats.value_changed.connect(_on_value_changed)

# 數值變動時：第一次看到這個種類就先生一列出來，然後把畫面同步成最新的值
func _on_value_changed(kind: String, _old_value: int, _new_value: int) -> void:
	if not _bars.has(kind) and not _labels.has(kind):
		_add_row(kind)
	_refresh_row(kind)

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
		title.text = "血量"
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

# 把某個種類那一列的畫面內容同步成 Stats 目前的數值
func _refresh_row(kind: String) -> void:
	if _bars.has(kind):
		var bar: ProgressBar = _bars[kind]
		var max_value := Stats.get_max_value(kind)
		bar.max_value = max_value if max_value > 0 else max(Stats.get_value(kind), 1)
		bar.value = Stats.get_value(kind)
	elif _labels.has(kind):
		var label: Label = _labels[kind]
		label.text = "%s：%d" % [kind, Stats.get_value(kind)]
