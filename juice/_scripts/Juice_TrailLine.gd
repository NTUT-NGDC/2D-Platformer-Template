@tool
extends JuiceBase

# 拖尾線：從角色身後拖出一條頭粗尾細、越來越淡的光帶，像 Unity 的 TrailRenderer。拖進 Player → Juice 底下就一直作用（持續型）。
# 線畫在關卡座標裡，只跟著角色的位置走。兩種拖線方式：
# - 速度夠快時：速度超過 min_speed 就拖線（衝刺、被彈射這類很快的移動）
# - 用訊號開關：把卡片或零件的訊號連到 start_trail()／stop_trail()，例如衝刺卡的 dashed／dash_ended
# 想調粗細曲線、漸層、貼圖：在這個節點底下放一個 Line2D 子節點，就改用它來畫線（寬度曲線、漸層在它的 Inspector 裡調）。

## 什麼時候拖線：速度夠快時自動拖，或用訊號連到 start_trail()／stop_trail() 自己決定開關
@export_enum("速度夠快時", "用訊號開關") var mode: int = 0:
	set(value):
		mode = value
		notify_property_list_changed()
## 速度超過這個值（像素／秒）才會拖出線；一般走路大約 200、跳起來大約 400，預設只有衝刺這類很快的移動才看得到
@export_range(50.0, 1000.0) var min_speed: float = 450.0
## 拖尾有多長：保留最近幾秒走過的路
@export_range(0.05, 0.6) var duration: float = 0.2
## 線的顏色（底下有 Line2D 樣板時看樣板的漸層）
@export_enum("白", "黃", "紅", "藍", "綠") var color: int = 0

const _MODE_SPEED := 0
const _COLORS := [Color.WHITE, Color(1.0, 0.9, 0.3), Color(1.0, 0.3, 0.25), Color(0.35, 0.6, 1.0), Color(0.35, 0.9, 0.4)]
const _WIDTH := 6.0
const _START_ALPHA := 0.8
# 兩個點至少要隔多遠才記（像素），太密沒必要
const _MIN_STEP := 1.0
# 一幀內移動超過這個距離就當作瞬間移動（傳送、重生），線重新開始，不要拉出一條橫跨畫面的線
const _TELEPORT_DISTANCE := 100.0
# 用訊號開關時，開了這麼久還沒收到 stop_trail() 就自動停，避免忘了連「停止」線就永遠拖著
const _AUTO_STOP := 2.0
# 編輯器裡幫空白的 Line2D 樣板放一條示範線，調曲線、漸層時看得到效果
const _PREVIEW_LENGTH := 64.0
const _PREVIEW_POINTS := 9

var _line: Line2D = null
var _points: Array = []   # [位置, 記下的時間]，新的在前面
var _time: float = 0.0
var _signal_on: bool = false
var _signal_on_time: float = 0.0

# 開始拖線（拖線方式選「用訊號開關」時用），可以把任何訊號連到這裡（訊號帶的參數會被忽略）
func start_trail(..._args: Array) -> void:
	_signal_on = true
	_signal_on_time = 0.0

# 停止拖線，已經拖出來的線會從尾巴慢慢縮回去
func stop_trail(..._args: Array) -> void:
	_signal_on = false

# 持續型：拖進來就一直作用
func _is_continuous() -> bool:
	return true

# 準備畫線用的 Line2D：有樣板就用樣板（保留它的寬度、曲線、漸層），沒有就自己建一條頭粗尾細、頭實尾淡的線
func _on_setup() -> void:
	if _line == null:
		_line = _get_template()
		if _line:
			print("[%s] 使用子節點「%s」畫拖尾線" % [name, _line.name])
		else:
			_line = _make_default_line()
			add_child(_line)
	_line.top_level = true
	if _line.z_index == 0:
		_line.z_index = -1
	_line.global_transform = Transform2D.IDENTITY
	_line.points = PackedVector2Array()

# 建立預設的線：粗 6、頭粗尾細、依 color 上色並從頭到尾淡掉
func _make_default_line() -> Line2D:
	var line := Line2D.new()
	line.width = _WIDTH
	line.antialiased = false
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 1.0))
	taper.add_point(Vector2(1.0, 0.0))
	line.width_curve = taper
	var c: Color = _COLORS[color]
	var fade := Gradient.new()
	fade.set_color(0, Color(c.r, c.g, c.b, _START_ALPHA))
	fade.set_color(1, Color(c.r, c.g, c.b, 0.0))
	line.gradient = fade
	return line

# 每幀：該拖線時記下現在的位置，丟掉太舊的點，重畫線
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _line == null or not is_instance_valid(player):
		return
	_time += delta
	if _signal_on:
		_signal_on_time += delta
		if _signal_on_time > _AUTO_STOP:
			_signal_on = false
	var pos: Vector2 = player.global_position
	if _points.size() > 0 and pos.distance_to(_points[0][0]) > _TELEPORT_DISTANCE:
		_points.clear()
	if _should_emit() and (_points.is_empty() or pos.distance_to(_points[0][0]) >= _MIN_STEP):
		_points.push_front([pos, _time])
	while _points.size() > 0 and _time - _points[-1][1] > duration:
		_points.pop_back()
	_redraw(pos)

# 現在要不要拖線：Juice 要開著、角色活著，再看拖線方式
func _should_emit() -> bool:
	if not _is_juice_on() or player.is_dead():
		return false
	if mode == _MODE_SPEED:
		return player.velocity.length() >= min_speed
	return _signal_on

# 把記下的點畫成線；線的頭一律接在角色現在的位置上，不拖線之後線從尾巴縮回角色身上
func _redraw(pos: Vector2) -> void:
	var line_points := PackedVector2Array()
	if _points.size() > 0 and _points[0][0] != pos:
		line_points.append(pos)
	for p in _points:
		line_points.append(p[0])
	_line.points = line_points if line_points.size() >= 2 else PackedVector2Array()

# 清掉整條線、關掉訊號開關
func _on_reset() -> void:
	_points.clear()
	_signal_on = false
	if _line:
		_line.points = PackedVector2Array()

# 找底下第一個 Line2D 子節點當樣板，沒有就回傳 null
func _get_template() -> Line2D:
	for child in get_children():
		if child is Line2D:
			return child
	return null

# 依設定隱藏用不到的欄位：用訊號開關時藏起 min_speed；有 Line2D 樣板時藏起 color
func _validate_property(property: Dictionary) -> void:
	super(property)
	var should_hide := false
	match property.name:
		"min_speed": should_hide = mode != _MODE_SPEED
		"color": should_hide = _get_template() != null
	if should_hide:
		property.usage &= ~PROPERTY_USAGE_EDITOR

# 編輯器裡子節點增減時：重新整理欄位，並幫空白的 Line2D 樣板放一條示範線
func _notification(what: int) -> void:
	if what != NOTIFICATION_CHILD_ORDER_CHANGED or not is_inside_tree():
		return
	notify_property_list_changed()
	if not Engine.is_editor_hint():
		return
	var template := _get_template()
	if template and template.points.is_empty():
		var preview := PackedVector2Array()
		for i in _PREVIEW_POINTS:
			preview.append(Vector2(-_PREVIEW_LENGTH * i / (_PREVIEW_POINTS - 1), 0.0))
		template.points = preview
