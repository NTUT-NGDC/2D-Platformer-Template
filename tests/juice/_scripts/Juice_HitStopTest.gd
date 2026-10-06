extends Node2D

# 手動驗證用：頓幀。Juice_HitStop 用預設值（打中東西時、0.08 秒），
# Juice_HitStop_EnemyDied 改成打倒敵人時、0.25 秒。每次有頓幀請求都會印出長度。

# 印出操作說明，監聽頓幀請求
func _ready() -> void:
	Events.hitstop_requested.connect(func(duration: float):
		print("[測試] 頓幀請求：%.2f 秒" % duration))
	print("[測試] 方向鍵移動、空白跳、F 攻擊、0 Juice 總開關")
	print("[測試] ① F 打箱子：每打中一下畫面頓一下（0.08 秒）")
	print("[測試] ② F 打敵人：打中頓一下；最後一下打倒敵人時頓得更久（0.25 秒）")
	print("[測試] ③ 被敵人撞到受傷：不會頓幀（受傷不算「打中東西時」）")
	print("[測試] ④ 按 0 關掉 Juice：打中東西不再頓幀，也不會印頓幀請求")
