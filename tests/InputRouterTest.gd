extends Node

# 手動驗證用：InputRouter 的優先權攔截、bind()/bind_key() 基本功能（U03），
# 以及 owner 離場自動解除、按鍵衝突警告、學員按鍵只聽不搶（U04）

var _temp_binder: Node = null

func _ready() -> void:
	InputRouter.bind_key(self, KEY_SPACE, InputRouter.PRESSED, _on_space_high, 10)
	InputRouter.bind_key(self, KEY_SPACE, InputRouter.PRESSED, _on_space_low, 0)
	InputRouter.bind_student_key(self, KEY_SPACE, InputRouter.PRESSED, _on_space_student)
	InputRouter.bind(self, "move_left", InputRouter.PRESSED, _on_move_left, 0)

	_temp_binder = Node.new()
	add_child(_temp_binder)
	InputRouter.bind_key(_temp_binder, KEY_G, InputRouter.PRESSED, _on_temp_g)

	print("[測試] 準備完成：")
	print("  1. 切到編輯器下方的「偵錯器 → 錯誤」分頁，應該看到 1~2 則 InputRouter 按鍵衝突警告（Space 被重複綁定）")
	print("  2. 按 Space：應該看到「高優先權」跟「學員」兩行，不該看到「低優先權」那行")
	print("  3. 按 A / ←：應該看到 bind() 那行")
	print("  4. 按 G：3 秒內應該看到「臨時節點收到 G」；3 秒後節點會被移除，之後按 G 應該完全沒反應")

	await get_tree().create_timer(3.0).timeout
	print("[測試] 移除臨時節點，現在按 G 應該沒有任何反應了")
	_temp_binder.queue_free()
	_temp_binder = null

# 高優先權，應該收到 Space
func _on_space_high() -> bool:
	print("[測試] 高優先權收到 Space（正確）")
	return true

# 低優先權，Space 應該被上面擋住，理論上不該印出這行
func _on_space_low() -> bool:
	print("[測試] 低優先權收到 Space（錯誤：應該被高優先權擋住）")
	return false

# 學員按鍵綁定，即使跟高優先權搶同一顆鍵，也應該照樣收得到
func _on_space_student() -> bool:
	print("[測試] 學員綁定收到 Space（正確，只聽不搶，不影響高優先權）")
	return true

# 驗證 bind() 用動作名稱綁定也能正常運作
func _on_move_left() -> bool:
	print("[測試] bind() 收到 move_left 動作（正確）")
	return true

# 臨時節點的綁定，節點被移除後這行就不該再出現
func _on_temp_g() -> bool:
	print("[測試] 臨時節點收到 G（節點被移除後這行就不該再出現）")
	return true
