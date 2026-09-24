extends Node2D

# 手動驗證用：KeySettings 按鍵設定。這個場景把往左改成 J、往右改成 L、跳躍改成 Shift，
# 同時掛了預設按 Shift 翻轉的重力翻轉卡，用來確認改過的按鍵也會觸發衝突警告。

# 印出操作說明
func _ready() -> void:
	print("[測試] 一開始輸出面板應該有：往左改成 J、往右改成 L、跳躍改成 Shift，以及一則「Player 跟 Mechanic_GravityFlip 都綁定了 Shift」的衝突警告")
	print("[測試] J／L 左右走、按 Shift 會跳（同時也會翻轉重力，這就是警告說的衝突）")
	print("[測試] A／D、空白鍵沒反應；方向鍵 ← → 照樣能走")
	print("[測試] 停止後回到編輯器，把 KeySettings 的 jump_key 改回 None 再跑：空白鍵又能跳，衝突警告消失")
