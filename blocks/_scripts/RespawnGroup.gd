@tool
extends Node2D

# 重生分組：放在 Room 底下，再把金幣、箱子、敵人、門拖到它底下，這一組就套用這裡的重生規則。
# 直接放在 Room 底下、沒進任何分組的東西用預設規則（放回去）。可以改名成「刷金幣」「一次性寶物」方便辨認。
# 規則只管「在房間裡死掉」的時候；整關重來一律全部放回去、數值全部倒回。

## 玩家在這個房間死掉時，要不要把這一組的東西放回去；不勾的話撿了、打倒了、推走了就一直是那樣
@export var reset_objects: bool = true:
	set(value):
		reset_objects = value
		queue_redraw()

## 玩家在這個房間死掉時，這一組的金幣撿到的數值、門用掉的鑰匙要不要倒回；不勾的話撿到的就算數（例如刷金幣）
@export var rewind_values: bool = true:
	set(value):
		rewind_values = value
		queue_redraw()

const _LABEL_COLOR := Color(0.75, 0.9, 1.0, 0.9)
const _LABEL_OFF_COLOR := Color(1.0, 0.6, 0.4, 0.9)

# 重生處理者用這個判斷要不要放回這一組的東西
func resets_objects() -> bool:
	return reset_objects

# 重生處理者用這個判斷要不要倒回這一組的東西帶來的數值
func rewinds_values() -> bool:
	return rewind_values

# 編輯器場景樹的黃色驚嘆號：分組底下沒有任何東西
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_child_count() == 0:
		warnings.append("這個分組底下沒有東西，把要套用這個規則的金幣、箱子、敵人拖進來。")
	return warnings

# 編輯器裡子節點增減時更新黃色警告
func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	child_entered_tree.connect(func(_n): update_configuration_warnings())
	child_exiting_tree.connect(func(_n): update_configuration_warnings.call_deferred())

# 編輯畫面用：在每個子物件上方標一行小字，看得出它屬於哪個分組、會不會放回去、數值會不會倒回
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := _LABEL_COLOR if reset_objects and rewind_values else _LABEL_OFF_COLOR
	var notes := PackedStringArray()
	if not reset_objects:
		notes.append("不放回")
	if not rewind_values:
		notes.append("數值不倒回")
	var text: String = str(name) if notes.is_empty() else "%s（%s）" % [name, "、".join(notes)]
	for child in get_children():
		if child is Node2D:
			draw_string(ThemeDB.fallback_font, (child as Node2D).position + Vector2(-8, -20), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)

# 編輯畫面持續重畫，子物件被拖動時標籤跟著移動
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
