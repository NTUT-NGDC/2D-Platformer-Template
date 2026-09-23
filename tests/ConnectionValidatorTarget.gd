extends Node

# 測試用的假目標節點：故意提供一個需要兩個參數的函式，
# 用來讓 ConnectionValidator 抓「參數數量不對」

func needs_two_args(_a, _b) -> void:
	pass
