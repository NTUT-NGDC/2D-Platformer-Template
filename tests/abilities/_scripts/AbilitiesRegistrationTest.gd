extends Node2D

# 手動驗證用：Player 的 Abilities 容器零連線發現機制。
# Ability_OK 掛在 Player → Abilities 底下，應該自動被呼叫 setup()，印出「已啟用」。
# Ability_Misplaced 故意掛在場景根目錄下（不是 Player 的子節點），應該印中文警告。

func _ready() -> void:
	print("[測試] 應該看到「[Ability_OK] 已啟用」")
	print("[測試] 應該看到 Ability_Misplaced 的中文警告（沒有掛在 Player 的 Abilities 底下）")
