extends Node2D

# 手動驗證用：KeySettings 按鍵設定。這個場景把往左改成 J、往右改成 L、跳躍改成 Shift，
# 同時掛了預設按 Shift 翻轉的重力翻轉卡，用來確認改過的按鍵也會觸發衝突警告。
# KeySettings 底下有兩列自訂按鍵：E（按下時）切換左邊的門、Q（放開時）切換右邊的門；
# 另外故意放了一個不是按鍵觸發器的 NotATrigger 節點。

# 印出操作說明
func _ready() -> void:
	print("[測試] 一開始輸出面板應該有：往左改成 J、往右改成 L、跳躍改成 Shift，以及一則「Player 跟 Mechanic_GravityFlip 都綁定了 Shift」的衝突警告")
	print("[測試] J／L 左右走、按 Shift 會跳（同時也會翻轉重力，這就是警告說的衝突）")
	print("[測試] A／D、空白鍵沒反應；方向鍵 ← → 照樣能走")
	print("[測試] 另外應該有一則「NotATrigger 不是按鍵觸發器」的警告")
	print("[測試] 按 E：左邊的門一按下就開關；按住 Q：右邊的門不動，放開才開關")
	print("[測試] 停止後回到編輯器，把 KeySettings 的 jump_key 改回 None 再跑：空白鍵又能跳，衝突警告消失")
