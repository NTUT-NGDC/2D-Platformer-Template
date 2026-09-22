extends Node

# 手動驗證用：InputRouter 的優先權攔截與 bind()/bind_key() 基本功能
# 按 Play 後看 Output 面板：按 Space 只應印出「高優先權」那行，按 A 或 ← 應印出 bind() 那行

func _ready() -> void:
	InputRouter.bind_key(self, KEY_SPACE, InputRouter.PRESSED, _on_space_high, 10)
	InputRouter.bind_key(self, KEY_SPACE, InputRouter.PRESSED, _on_space_low, 0)
	InputRouter.bind(self, "move_left", InputRouter.PRESSED, _on_move_left, 0)
	print("[測試] 準備完成，按 Space 測試優先權攔截，按 A / ← 測試 bind() 動作綁定")

# 高優先權，應該收到 Space
func _on_space_high() -> bool:
	print("[測試] 高優先權收到 Space（正確）")
	return true

# 低優先權，Space 應該被上面擋住，理論上不該印出這行
func _on_space_low() -> bool:
	print("[測試] 低優先權收到 Space（錯誤：應該被高優先權擋住）")
	return false

# 驗證 bind() 用動作名稱綁定也能正常運作
func _on_move_left() -> bool:
	print("[測試] bind() 收到 move_left 動作（正確）")
	return true
