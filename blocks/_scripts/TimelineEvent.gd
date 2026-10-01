@tool
extends Node

# 時間軸事件：Timeline 底下的一列（節點名稱＝這一列的名稱，例如改成「10秒開門」）。
# 時間軸從開始算起跑到第 time 秒時發出 triggered（不是等上一列之後幾秒），學員把 triggered 連到零件的函式（例如門的 activate）。
# 要多一個事件就選它按 Ctrl+D 複製一列，改秒數、重新連線。

## 關閉時這一列不會觸發
@export var enabled: bool = true

## 從時間軸開始算起的第幾秒觸發（不是等上一列之後幾秒）。例如 3 秒開門、6 秒關門 = 門開 3 秒後關上
@export_range(0.0, 300.0, 0.5, "suffix:秒") var time: float = 10.0:
	set(value):
		time = value
		var parent := get_parent()
		if parent is CanvasItem:
			(parent as CanvasItem).queue_redraw()

## 時間到的那一刻發出，拿去連任何零件的函式（例如門的 activate）
signal triggered

const _TIMELINE_SCRIPT_PATH := "res://blocks/_scripts/Timeline.gd"

# 加入 signal_source，等場景裡其他節點都準備好再檢查有沒有連線、有沒有放對位置
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	_check_setup.call_deferred()

# 被拖到別的地方時重新檢查黃色驚嘆號
func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED or what == NOTIFICATION_UNPARENTED:
		update_configuration_warnings()

# 時間軸呼叫：時間到了，發出 triggered
func fire() -> void:
	print("[時間軸] 第 %s 秒：觸發「%s」" % [_format_time(time), name])
	triggered.emit()

# 回傳這一列在時間軸上要顯示的文字，例如「第 10.0 秒｜10秒開門」
func get_label() -> String:
	var text := "第 %s 秒｜%s" % [_format_time(time), name]
	if not enabled:
		text += "（關閉）"
	return text

# 編輯器裡的黃色驚嘆號：沒放在 Timeline 底下
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not _is_under_timeline():
		warnings.append("時間軸事件要放在時間軸（Timeline）底下才會觸發：在場景樹把它拖到 Timeline 上放開。")
	return warnings

# 執行時檢查：沒放在 Timeline 底下、或 triggered 沒連到任何東西，就印中文警告
func _check_setup() -> void:
	if not _is_under_timeline():
		push_warning("[時間軸] %s 沒有放在 Timeline 底下，不會觸發" % name)
		printerr("⚠ [時間軸] 請把 %s 拖到關卡裡的 Timeline（時間軸）底下" % name)
		return
	if triggered.get_connections().is_empty():
		push_warning("[時間軸] %s 的 triggered 沒有連到任何東西，時間到了不會有反應" % name)
		printerr("⚠ [時間軸] %s 還沒連線：選它 → 右邊「節點」面板 → 雙擊 triggered → 選要控制的零件和函式" % name)

# 父節點是不是時間軸
func _is_under_timeline() -> bool:
	var parent := get_parent()
	var parent_script: Script = parent.get_script() if parent else null
	return parent_script != null and parent_script.resource_path == _TIMELINE_SCRIPT_PATH

# 把秒數排成一位小數的文字
func _format_time(seconds: float) -> String:
	return "%.1f" % seconds
