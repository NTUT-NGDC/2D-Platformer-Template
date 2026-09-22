extends Node

# 手動驗證用：Stats 的 HUD 自動生成，數值第一次被實際加減時才會出現對應的那一列

func _ready() -> void:
	print("[測試] 一開始畫面左上角應該什麼都沒有（血量還沒被用到）")
	await get_tree().create_timer(1.5).timeout
	print("[測試] 幫血量扣 1，畫面左上角應該出現血量條")
	Stats.add(Stats.HEALTH_KIND, -1)
	await get_tree().create_timer(1.5).timeout
	print("[測試] 加 3 個金幣，畫面應該多一列「金幣：3」，前面有一個小色塊")
	Stats.add("金幣", 3)
	await get_tree().create_timer(1.5).timeout
	print("[測試] 金幣再加 2，畫面上的金幣數字應該變成 5，不會多一列")
	Stats.add("金幣", 2)
