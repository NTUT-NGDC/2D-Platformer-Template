extends Node

# 手動驗證用：ConnectionValidator 連線驗證器。這個場景故意接了四種錯誤的訊號連接，
# 播放後不用做任何操作，輸出面板／偵錯器應該直接印出對應的中文警告。

func _ready() -> void:
	print("[測試] 這個場景故意接錯了四種連線，播放後不用操作，應該直接看到警告：")
	print("[測試] 1. Button_MissingMethod → Target.activate_typo（函式不存在）")
	print("[測試] 2. Button_WrongArity → Target.needs_two_args（參數數量不對）")
	print("[測試] 3. Button_DeletedTarget → 已刪除的節點（目標節點不存在）")
	print("[測試] 4. Button_Dangerous → Decoration.queue_free（危險內建函式）")
