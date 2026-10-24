extends Control

# 換字零件（U251）：三組按鈕／勾選框連到三個 SwitchText，開場先自動按一輪檢查，之後可以用滑鼠點來測。
# 「換字」→ SwitchA 的 toggle（關 ↔ 開）；「勾我」→ SwitchB 的 set_on（沒勾 ↔ 勾著，換顏色）；「下一段」→ SwitchC 的 next_text（四段輪流）。

@onready var _toggle_button: Button = $ToggleButton
@onready var _check_box: CheckBox = $CheckBox
@onready var _next_button: Button = $NextButton
@onready var _a: Label = $SwitchA
@onready var _b: Label = $SwitchB
@onready var _c: Label = $SwitchC

# 跑自動檢查，再印出手動操作說明
func _ready() -> void:
	await get_tree().process_frame
	_run_checks()
	print("[測試] ── 手動測試 ──")
	print("[測試] ① 點「換字」：右邊的「關」變「開」，再點變回「關」")
	print("[測試] ② 勾「勾我」：右邊變成黃色的「勾著」；取消勾：變回白色的「沒勾」")
	print("[測試] ③ 點「下一段」：第一段 → 第二段 → 第三段 → 第四段 → 第一段；SwitchC 取消勾 loop_texts 再按 F6：停在第四段")
	print("[測試] ④ 選 SwitchA：Inspector 沒有 Label 原本的 Text 欄位，改 normal_text 編輯器裡馬上換字；active_text 清空、more_texts 空著：出現黃色驚嘆號")
	print("[測試] ⑤ 選 SwitchB：color_style 選「不換顏色」active_color 藏起來；選回「換顏色」，active_color 的 A 拉到 0：出現黃色驚嘆號")

# 照學員會做的方式送訊號，檢查字和顏色有沒有跟著換
func _run_checks() -> void:
	print("[測試] ── 自動檢查 ──")
	_check("一開始顯示平常的字", _a.text == "關" and _b.text == "沒勾" and _c.text == "第一段")
	_toggle_button.pressed.emit()
	_check("按「換字」：關 → 開", _a.text == "開")
	_toggle_button.pressed.emit()
	_check("再按一次：開 → 關", _a.text == "關")

	_check_box.button_pressed = true
	_check("勾「勾我」：沒勾 → 勾著，換成 active_color", _b.text == "勾著" and _b.has_theme_color_override("font_color"))
	_check_box.button_pressed = false
	_check("取消勾：勾著 → 沒勾，顏色換回原本的", _b.text == "沒勾" and not _b.has_theme_color_override("font_color"))

	var seen := PackedStringArray()
	for i in 4:
		_next_button.pressed.emit()
		seen.append(_c.text)
	_check("按四次「下一段」：第二段、第三段、第四段、回到第一段", seen == PackedStringArray(["第二段", "第三段", "第四段", "第一段"]))
	_c.call("previous_text")
	_check("previous_text：從第一段往回到第四段", _c.text == "第四段")
	_c.call("show_first")
	_check("show_first：回到第一段", _c.text == "第一段")

# 印出一條檢查結果
func _check(label: String, ok: bool) -> void:
	if ok:
		print("[測試] ✓ %s" % label)
	else:
		printerr("[測試] ✗ %s" % label)
