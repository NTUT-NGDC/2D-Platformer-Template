extends Node2D

# 手動驗證用：Goal 踩到時 emit reached，同步轉發 Events.level_cleared。

@onready var _goal: Area2D = $Goal

func _ready() -> void:
	_goal.reached.connect(func(): print("[測試] Goal.reached 觸發了"))
	Events.level_cleared.connect(func(): print("[測試] Events.level_cleared 正確轉發"))
	print("[測試] 用方向鍵／AD 走到黃色的終點方塊上")
