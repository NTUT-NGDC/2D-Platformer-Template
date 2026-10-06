@tool
extends JuiceBase

# 粒子噴發：觸發時噴出一小撮粒子。拖進 Player → Juice 底下就能用，預設是落地時從腳底噴塵土。
# 粒子生在關卡裡、不跟著玩家走，噴完自己消失。三種用法：
# 1. 樣式下拉選內建的塵土、火花、星星、碎片、煙霧（juice/particles/ 底下的粒子場景）
# 2. 樣式選「自訂場景」，把自己做的粒子場景（根節點是 CPUParticles2D，可以放自己的圖）拖進 custom_particles
# 3. 在這個節點底下放一個 CPUParticles2D 子節點，就改用它當樣板（樣式、顏色、數量都看它的）

## 粒子的樣子：塵土（往兩旁散開）、火花（往四面八方快速噴）、星星（在原地一閃一閃，適合金幣）、
## 碎片（往上噴再掉下來）、煙霧（陸續冒出、慢慢往上飄散），或「自訂場景」用自己做的粒子場景
@export_enum("塵土", "火花", "星星", "碎片", "煙霧", "自訂場景") var style: int = 0:
	set(value):
		style = value
		notify_property_list_changed()
		update_configuration_warnings()
## 一次噴幾顆
@export_range(4, 64) var amount: int = 12
## 粒子顏色，選「跟著樣式」就用每種樣式自己的顏色
@export_enum("跟著樣式", "白", "黃", "紅", "藍", "綠") var color: int = 0
## 自己做的粒子場景：根節點要是 CPUParticles2D，可以參考 juice/particles/ 裡的範例複製一份到 _my/ 再改
@export var custom_particles: PackedScene = null:
	set(value):
		custom_particles = value
		update_configuration_warnings()
## 從哪裡噴：腳底、身體中心，或事件發生的地方（例如打中的敵人、撿到的金幣；玩家自己的事件就是玩家位置）
@export_enum("腳底", "身體中心", "事件發生處") var spawn_at: int = 0

const _STYLE_CUSTOM := 5
const _MAX_AMOUNT := 64
const _SPAWN_FEET := 0
const _SPAWN_CENTER := 1
const _PRESETS := [
	preload("res://juice/particles/Particles_Dust.tscn"),
	preload("res://juice/particles/Particles_Sparks.tscn"),
	preload("res://juice/particles/Particles_Stars.tscn"),
	preload("res://juice/particles/Particles_Debris.tscn"),
	preload("res://juice/particles/Particles_Smoke.tscn"),
]
const _COLORS := [Color.WHITE, Color(1.0, 0.9, 0.3), Color(1.0, 0.3, 0.25), Color(0.35, 0.6, 1.0), Color(0.35, 0.9, 0.4)]

var _bursts: Array = []   # 還沒噴完的粒子（WeakRef），重生或總開關關掉時一起清掉
var _warned_amount: bool = false
var _use_custom: bool = false   # 自訂場景有設好，開場檢查一次記下來

# 子節點樣板只拿來複製，自己不噴、不顯示；檢查自訂場景有沒有設好
func _on_setup() -> void:
	var template := _get_template()
	if template:
		template.emitting = false
		template.visible = false
		print("[%s] 使用子節點「%s」當粒子樣板" % [name, template.name])
	elif style == _STYLE_CUSTOM:
		var problem := _custom_problem()
		_use_custom = problem == ""
		if not _use_custom:
			push_warning("[%s] %s，先改用塵土" % [name, problem])
			printerr("⚠ [%s] %s，先改用塵土" % [name, problem])

# 在指定的位置生出一組粒子，噴完自己刪掉
func _on_play() -> void:
	var level := get_tree().current_scene
	if level == null:
		return
	var p := _make_particles()
	level.add_child(p)
	p.global_position = _spawn_position()
	p.finished.connect(p.queue_free)
	p.restart()
	_bursts.append(weakref(p))

# 清掉還在場上的粒子
func _on_reset() -> void:
	for w in _bursts:
		var p = w.get_ref()
		if p:
			p.queue_free()
	_bursts.clear()

# 依「從哪裡噴」算出粒子的位置
func _spawn_position() -> Vector2:
	match spawn_at:
		_SPAWN_FEET: return player.get_feet_position()
		_SPAWN_CENTER: return player.global_position
	return _trigger_position

# 做出一組一次噴完的粒子：子節點樣板 → 自訂場景 → 內建樣式；重力翻轉時整組上下顛倒
func _make_particles() -> CPUParticles2D:
	_bursts = _bursts.filter(func(w): return w.get_ref() != null)
	var p: CPUParticles2D
	var base_amount: int
	var template := _get_template()
	if template:
		p = template.duplicate()
		p.visible = true
		base_amount = p.amount
	elif _use_custom:
		p = custom_particles.instantiate()
		base_amount = p.amount
	else:
		p = _PRESETS[style if style < _STYLE_CUSTOM else 0].instantiate()
		base_amount = amount
		if color > 0:
			p.color = _COLORS[color - 1]
	if base_amount > _MAX_AMOUNT and not _warned_amount:
		_warned_amount = true
		push_warning("[%s] 粒子一次最多 64 顆（弱電腦和網頁版才跑得動），已經自動減到 64" % name)
		printerr("⚠ [%s] 粒子一次最多 64 顆，已經自動減到 64" % name)
	p.amount = clampi(roundi(base_amount * _trigger_power), 1, _MAX_AMOUNT)
	p.one_shot = true
	p.emitting = false
	p.local_coords = false
	p.position = Vector2.ZERO
	if is_instance_valid(player) and player.up_direction.y > 0.0:
		p.direction.y = -p.direction.y
		p.gravity.y = -p.gravity.y
	return p

# 找底下第一個 CPUParticles2D 子節點當樣板，沒有就回傳 null
func _get_template() -> CPUParticles2D:
	for child in get_children():
		if child is CPUParticles2D:
			return child
	return null

# 檢查自訂場景能不能用，能用回傳空字串，不能用回傳原因
func _custom_problem() -> String:
	if custom_particles == null:
		return "樣式選了「自訂場景」，但 custom_particles 是空的，請把粒子場景拖進來"
	var probe := custom_particles.instantiate()
	var ok := probe is CPUParticles2D
	probe.free()
	if not ok:
		return "custom_particles 的根節點不是 CPUParticles2D（網頁版和弱電腦要用 CPUParticles2D）"
	return ""

# 依用法隱藏用不到的欄位：有子節點樣板時只留「從哪裡噴」；自訂場景時藏起數量和顏色；不是自訂場景時藏起 custom_particles
func _validate_property(property: Dictionary) -> void:
	super(property)
	var has_template := _get_template() != null
	var custom := style == _STYLE_CUSTOM
	var should_hide := false
	match property.name:
		"style": should_hide = has_template
		"amount", "color": should_hide = has_template or custom
		"custom_particles": should_hide = has_template or not custom
	if should_hide:
		property.usage &= ~PROPERTY_USAGE_EDITOR

# 編輯器裡就看得到設定錯誤：自訂場景是空的、根節點不對，或子節點用了 GPUParticles2D
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for child in get_children():
		if child is GPUParticles2D:
			warnings.append("子節點「%s」是 GPUParticles2D，請改用 CPUParticles2D（網頁版和弱電腦比較順）" % child.name)
	if _get_template() == null and style == _STYLE_CUSTOM:
		var problem := _custom_problem()
		if problem != "":
			warnings.append(problem + "；沒設好之前先噴塵土")
	return warnings

# 子節點增減時，重新整理 Inspector 欄位與警告
func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED and is_inside_tree():
		notify_property_list_changed()
		update_configuration_warnings()
