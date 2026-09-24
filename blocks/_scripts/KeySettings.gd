extends Node

# 按鍵設定：關卡裡所有按鍵的地方。Inspector 的「預設操作」改玩家基本操作（左右上下、跳躍）要按哪一顆鍵；
# 自訂按鍵是底下的 KeyTrigger 子節點，一個子節點一列（名稱、按鍵、觸發方式，triggered 連到要觸發的函式）。
# 設定跟著關卡存在 _my/，重灌專案也不會被蓋掉。只換掉字母鍵／空白鍵，方向鍵永遠保留；選 None 的動作
# 維持原本的按鍵。這個節點被刪掉或換場景時，改過的按鍵自動恢復成專案預設。

@export_group("預設操作")
## 往左走要按哪一顆鍵（None = 維持預設的 A，方向鍵 ← 一直都能用）
@export var left_key: Key = KEY_NONE
## 往右走要按哪一顆鍵（None = 維持預設的 D，方向鍵 → 一直都能用）
@export var right_key: Key = KEY_NONE
## 往上要按哪一顆鍵（None = 維持預設的 W，方向鍵 ↑ 一直都能用）
@export var up_key: Key = KEY_NONE
## 往下要按哪一顆鍵（None = 維持預設的 S，方向鍵 ↓ 一直都能用）
@export var down_key: Key = KEY_NONE
## 跳躍要按哪一顆鍵（None = 維持預設的空白鍵）
@export var jump_key: Key = KEY_NONE

const _ARROW_KEYS := [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]
const _ACTION_NAMES := {
	"move_left": "往左",
	"move_right": "往右",
	"move_up": "往上",
	"move_down": "往下",
	"jump": "跳躍",
}

var _original_events: Dictionary = {}  # 動作名稱 -> 改之前的按鍵事件，離開場景時還原用

# 搶在所有組件的 _ready()（向 InputRouter 註冊按鍵、檢查衝突）之前改好按鍵
func _enter_tree() -> void:
	add_to_group("key_settings")
	if get_tree().get_nodes_in_group("key_settings").size() > 1:
		push_warning("[按鍵設定] 場景裡有不只一個 KeySettings，只有第一個會生效")
		printerr("⚠ [按鍵設定] 場景裡有不只一個 KeySettings，%s 不會生效，可以刪掉" % name)
		return
	var settings := {
		"move_left": left_key,
		"move_right": right_key,
		"move_up": up_key,
		"move_down": down_key,
		"jump": jump_key,
	}
	for action in settings:
		if settings[action] != KEY_NONE:
			_replace_key(action, settings[action])
	_warn_duplicates()

# 檢查底下的子節點是不是都是按鍵觸發器，拖錯東西進來要提醒
func _ready() -> void:
	for child in get_children():
		if not ("trigger" in child and child.has_signal("triggered")):
			push_warning("[按鍵設定] %s 不是按鍵觸發器，放在 KeySettings 底下不會有作用" % child.name)
			printerr("⚠ [按鍵設定] %s 不是按鍵觸發器（KeyTrigger），請拖到關卡的其他地方" % child.name)

# 離開場景時把改過的動作恢復成原本的按鍵，不影響之後打開的其他場景
func _exit_tree() -> void:
	for action in _original_events:
		InputMap.action_erase_events(action)
		for event in _original_events[action]:
			InputMap.action_add_event(action, event)
	_original_events.clear()

# 把某個動作的字母鍵／空白鍵換成新的按鍵，方向鍵保留
func _replace_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		return
	_original_events[action] = InputMap.action_get_events(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode not in _ARROW_KEYS:
			InputMap.action_erase_event(action, event)
	var new_event := InputEventKey.new()
	new_event.physical_keycode = key
	InputMap.action_add_event(action, new_event)
	print("[按鍵設定] %s 改成 %s" % [_ACTION_NAMES[action], OS.get_keycode_string(key)])
	if key in _DANGEROUS_KEYS:
		var message := "[按鍵設定] %s 選的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % [_ACTION_NAMES[action], OS.get_keycode_string(key)]
		push_warning(message)
		printerr("⚠ %s" % message)

# 檢查有沒有兩個基本動作用到同一顆鍵（例如跳躍改成 A，但往左也是 A）
func _warn_duplicates() -> void:
	var owners := {}  # physical_keycode -> 動作中文名
	for action in _ACTION_NAMES:
		for event in InputMap.action_get_events(action):
			if not (event is InputEventKey):
				continue
			var code: int = (event as InputEventKey).physical_keycode
			if owners.has(code):
				var message := "[按鍵設定] %s 跟 %s 都用到「%s」，按下去兩個會同時發生，建議換一個" % [owners[code], _ACTION_NAMES[action], OS.get_keycode_string(code)]
				push_warning(message)
				printerr("⚠ %s" % message)
			else:
				owners[code] = _ACTION_NAMES[action]
