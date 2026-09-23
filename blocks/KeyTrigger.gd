extends Node

# 按鍵觸發器：不用連任何線，拖進場景就能用。依 key_source 決定要用預先定義的動作
# （跟移動/跳躍共用同一顆鍵）還是自己選一個按鍵。一律用學員按鍵優先權註冊，
# 不會搶走 Player 或機制卡的輸入（見 documents/01a_shared_systems.md §3.5）。

## 關閉時這個觸發器不會生效
@export var enabled: bool = true

## 按鍵來源：預先定義的動作（跟移動/跳躍共用同一顆鍵）、或自己選一個按鍵
@export_enum("預設動作", "自訂按鍵") var key_source: int = 0

## key_source 選「預設動作」時，要用哪一個
@export_enum("move_left", "move_right", "move_up", "move_down", "jump", "restart") var action: String = "jump"

## key_source 選「自訂按鍵」時，要用哪一個按鍵
@export var key: Key = KEY_E

## 按下的那一幀發出
signal pressed
## 開始按住那一刻發出（時機等同 pressed，名字給知道「按住」概念的人用）
signal hold_started
## 放開、結束按住那一刻發出
signal hold_ended
## 放開的那一幀發出，帶總共按住的秒數（進階用，一般接效果不用管這個參數）
signal released(seconds: float)
## 按著的每個物理幀發出，帶已經按住的秒數（進階用）
signal held(seconds: float)

const _SOURCE_ACTION := 0
const _SOURCE_KEY := 1

const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

# 依 key_source 顯示對應欄位，另一個隱藏，學員不會被無關的欄位搞混
func _validate_property(property: Dictionary) -> void:
	if property.name == "action" and key_source != _SOURCE_ACTION:
		property.usage = PROPERTY_USAGE_NONE
	elif property.name == "key" and key_source != _SOURCE_KEY:
		property.usage = PROPERTY_USAGE_NONE

# 依 key_source 向 InputRouter 註冊三個時機，一律用學員優先權（只聽不搶）
func _ready() -> void:
	if key_source == _SOURCE_ACTION:
		InputRouter.bind_student(self, StringName(action), InputRouter.PRESSED, _on_pressed)
		InputRouter.bind_student(self, StringName(action), InputRouter.HELD, _on_held)
		InputRouter.bind_student(self, StringName(action), InputRouter.RELEASED, _on_released)
	else:
		_warn_if_dangerous_key(key)
		InputRouter.bind_student_key(self, key, InputRouter.PRESSED, _on_pressed)
		InputRouter.bind_student_key(self, key, InputRouter.HELD, _on_held)
		InputRouter.bind_student_key(self, key, InputRouter.RELEASED, _on_released)

# 按下那一幀：發出 pressed 跟 hold_started
func _on_pressed() -> void:
	pressed.emit()
	hold_started.emit()

# 按著的每個物理幀：發出 held(秒數)
func _on_held(seconds: float) -> void:
	held.emit(seconds)

# 放開那一幀：發出 hold_ended 跟 released(總共按住的秒數)
func _on_released(seconds: float) -> void:
	hold_ended.emit()
	released.emit(seconds)

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[按鍵觸發器] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
