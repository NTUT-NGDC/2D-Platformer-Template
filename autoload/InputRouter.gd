extends Node

# 所有機制卡、能力、按鍵觸發器統一透過這裡收輸入，不要各自讀 Input。
# 同一個按鍵／動作、同一個時機被多邊綁定時，優先權高的先收到；它回傳 true 代表「處理掉了」，
# 優先權較低的這一輪就不會再收到。學員自己擺的按鍵觸發器例外：一律用 bind_student_key()，
# 一定收得到，但不會擋住任何其他綁定（見 _dispatch_group）。

# 按下的那一幀觸發一次，callback 不帶參數
const PRESSED := 0
# 按著的每個物理幀觸發，callback 帶「已按住秒數」(float)
const HELD := 1
# 放開的那一幀觸發一次，callback 帶「總共按住的秒數」(float)
const RELEASED := 2

# 學員按鍵觸發器專用的優先權：故意設到不可能有人蓋過去的低點
const STUDENT_PRIORITY := -2147483648

# 一條綁定紀錄
class Binding extends RefCounted:
	var owner: Node
	var trigger: StringName
	var phase: int
	var callback: Callable
	var priority: int
	var key: int = -1
	var is_student: bool = false

var _bindings: Array[Binding] = []
var _press_started_at: Dictionary = {}   # trigger(StringName) -> 按下當下的時間戳（秒）
var _key_action_refs: Dictionary = {}    # key(int) -> 有幾條綁定在用這個臨時動作
var _watched_owners: Dictionary = {}     # owner(Node) -> true，避免對同一個 owner 重複接 tree_exiting

# 用動作名稱綁定；機制卡、能力、資工生用這個，priority 越大越先收到
@warning_ignore("shadowed_variable_base_class")
func bind(owner: Node, action: StringName, phase: int, callback: Callable, priority: int = 0) -> void:
	_add_binding(owner, action, phase, callback, priority, -1, false)

# 直接用按鍵綁定，內部自動建立只在執行期存在的臨時動作，不會寫回專案設定
@warning_ignore("shadowed_variable_base_class")
func bind_key(owner: Node, key: Key, phase: int, callback: Callable, priority: int = 0) -> void:
	var action := _ensure_key_action(key)
	_add_binding(owner, action, phase, callback, priority, key, false)

# 學員自己擺的按鍵觸發器專用（KeyTrigger、MyControls）：一定收得到輸入，但不會擋住任何其他綁定
@warning_ignore("shadowed_variable_base_class")
func bind_student_key(owner: Node, key: Key, phase: int, callback: Callable) -> void:
	var action := _ensure_key_action(key)
	_add_binding(owner, action, phase, callback, STUDENT_PRIORITY, key, true)

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

# 建立一條綁定紀錄、加入清單、順便做衝突檢查與離場自動解除的掛勾
@warning_ignore("shadowed_variable_base_class")
func _add_binding(owner: Node, trigger: StringName, phase: int, callback: Callable, priority: int, key: int, is_student: bool) -> void:
	var binding := Binding.new()
	binding.owner = owner
	binding.trigger = trigger
	binding.phase = phase
	binding.callback = callback
	binding.priority = priority
	binding.key = key
	binding.is_student = is_student
	_bindings.append(binding)
	_warn_if_conflict(binding)
	if not _watched_owners.has(owner):
		_watched_owners[owner] = true
		owner.tree_exiting.connect(_on_owner_exiting.bind(owner))

# owner 離開場景樹時，自動解除它在這裡註冊的所有綁定
@warning_ignore("shadowed_variable_base_class")
func _on_owner_exiting(owner: Node) -> void:
	_watched_owners.erase(owner)
	var remaining: Array[Binding] = []
	for binding in _bindings:
		if binding.owner == owner:
			if binding.key != -1:
				_release_key_action(binding.key)
		else:
			remaining.append(binding)
	_bindings = remaining

# 減少臨時動作的參照計數，歸零時從 InputMap 移除，避免累積用不到的動作
func _release_key_action(key: int) -> void:
	if not _key_action_refs.has(key):
		return
	_key_action_refs[key] -= 1
	if _key_action_refs[key] <= 0:
		_key_action_refs.erase(key)
		var action := StringName("_input_router_key_%d" % key)
		if InputMap.has_action(action):
			InputMap.erase_action(action)

# 把一條綁定換算成實際的按鍵清單，供衝突檢查比對用
func _resolve_keys(trigger: StringName, key: int) -> Array[int]:
	if key != -1:
		return [key]
	var keys: Array[int] = []
	for event in InputMap.action_get_events(trigger):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys

# 新綁定跟既有綁定的實體按鍵、時機重疊時，印中文警告提醒可能互相搶輸入
func _warn_if_conflict(new_binding: Binding) -> void:
	var new_keys := _resolve_keys(new_binding.trigger, new_binding.key)
	if new_keys.is_empty():
		return
	for existing in _bindings:
		if existing == new_binding or existing.phase != new_binding.phase:
			continue
		var existing_keys := _resolve_keys(existing.trigger, existing.key)
		for k in new_keys:
			if k in existing_keys:
				push_warning("[InputRouter] %s 跟 %s 都綁定了同一個按鍵（%s），同一時機可能互相搶輸入" % [
					_owner_label(existing.owner), _owner_label(new_binding.owner), OS.get_keycode_string(k)
				])
				return

# 綁定紀錄裡的節點名稱，節點已經被釋放就給一個看得懂的替代字串
@warning_ignore("shadowed_variable_base_class")
func _owner_label(owner: Node) -> String:
	if is_instance_valid(owner):
		return owner.name
	return "（已釋放的節點）"

# 這條綁定現在算不算數：owner 已經不在場景樹裡，或它的「啟用」被關掉，都視為暫時不派發
func _is_active(binding: Binding) -> bool:
	if not is_instance_valid(binding.owner):
		return false
	if binding.owner.get("enabled") == false:
		return false
	return true

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

# 對同一個觸發來源＋時機的所有綁定派發事件：一般綁定依優先權互相擋，學員綁定一律收得到、不擋人
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
	var arg = (now - _press_started_at.get(trigger, now)) if phase != PRESSED else null

	var handled := false
	for binding in group:
		if not _is_active(binding):
			continue
		if binding.is_student:
			_call_binding(binding, arg)
			continue
		if handled:
			continue
		if _call_binding(binding, arg):
			handled = true

# 呼叫綁定的 callback，依時機決定要不要帶參數
func _call_binding(binding: Binding, arg) -> Variant:
	if arg == null:
		return binding.callback.call()
	return binding.callback.call(arg)
