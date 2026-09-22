extends Node

# 所有機制卡、能力、按鍵觸發器統一透過這裡收輸入，不要各自讀 Input。
# 同一個按鍵／動作、同一個時機被多邊綁定時，優先權高的先收到；它回傳 true 代表「處理掉了」，
# 優先權較低的這一輪就不會再收到。

## 按下的那一幀觸發一次，callback 不帶參數
const PRESSED := 0
## 按著的每個物理幀觸發，callback 帶「已按住秒數」(float)
const HELD := 1
## 放開的那一幀觸發一次，callback 帶「總共按住的秒數」(float)
const RELEASED := 2

# 一條綁定紀錄
class Binding extends RefCounted:
	var owner: Node
	var trigger: StringName
	var phase: int
	var callback: Callable
	var priority: int
	var key: int = -1

var _bindings: Array[Binding] = []
var _press_started_at: Dictionary = {}   # trigger(StringName) -> 按下當下的時間戳（秒）
var _key_action_refs: Dictionary = {}    # key(int) -> 有幾條綁定在用這個臨時動作

# 用動作名稱綁定；機制卡、能力、資工生用這個，priority 越大越先收到
func bind(owner: Node, action: StringName, phase: int, callback: Callable, priority: int = 0) -> void:
	_add_binding(owner, action, phase, callback, priority, -1)

# 直接用按鍵綁定，內部自動建立只在執行期存在的臨時動作，不會寫回專案設定
func bind_key(owner: Node, key: Key, phase: int, callback: Callable, priority: int = 0) -> void:
	var action := _ensure_key_action(key)
	_add_binding(owner, action, phase, callback, priority, key)

# 幫某個實體按鍵建立（或沿用）一個只在記憶體裡存在的臨時動作
func _ensure_key_action(key: Key) -> StringName:
	var action := StringName("_input_router_key_%d" % key)
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	_key_action_refs[key] = _key_action_refs.get(key, 0) + 1
	return action

# 建立一條綁定紀錄並加入清單
func _add_binding(owner: Node, trigger: StringName, phase: int, callback: Callable, priority: int, key: int) -> void:
	var binding := Binding.new()
	binding.owner = owner
	binding.trigger = trigger
	binding.phase = phase
	binding.callback = callback
	binding.priority = priority
	binding.key = key
	_bindings.append(binding)

# 每個物理幀依優先權派發所有綁定的事件
func _physics_process(_delta: float) -> void:
	if _bindings.is_empty():
		return

	var triggers: Dictionary = {}
	for binding in _bindings:
		triggers[binding.trigger] = true
	for trigger in triggers:
		if Input.is_action_just_pressed(trigger):
			_press_started_at[trigger] = Time.get_ticks_msec() / 1000.0

	var groups: Dictionary = {}
	for binding in _bindings:
		var group_key := "%s|%d" % [binding.trigger, binding.phase]
		if not groups.has(group_key):
			groups[group_key] = []
		groups[group_key].append(binding)
	for group_key in groups:
		var group: Array = groups[group_key]
		group.sort_custom(func(a, b): return a.priority > b.priority)
		_dispatch_group(group)

	for trigger in triggers:
		if Input.is_action_just_released(trigger):
			_press_started_at.erase(trigger)

# 對同一個觸發來源＋時機的所有綁定，依優先權高到低派發，直到有人回傳 true 為止
func _dispatch_group(group: Array) -> void:
	var trigger: StringName = group[0].trigger
	var phase: int = group[0].phase
	var fired := false
	match phase:
		PRESSED:
			fired = Input.is_action_just_pressed(trigger)
		HELD:
			fired = Input.is_action_pressed(trigger)
		RELEASED:
			fired = Input.is_action_just_released(trigger)
	if not fired:
		return

	var now := Time.get_ticks_msec() / 1000.0
	var held_duration: float = now - _press_started_at.get(trigger, now)

	for binding in group:
		if not is_instance_valid(binding.owner):
			continue
		var handled = binding.callback.call(held_duration) if phase != PRESSED else binding.callback.call()
		if handled:
			return
