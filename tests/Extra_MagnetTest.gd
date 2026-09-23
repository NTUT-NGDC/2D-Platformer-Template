extends Node2D

# 手動驗證用：Extra_Magnet 把範圍內的箱子往玩家方向拉過來。

func _ready() -> void:
	print("[測試] 場上有一個箱子，離遠一點看它不動；走近到範圍內，箱子應該開始被拉過來")
	print("[測試] 箱子貼近玩家時應該穩定停住，不會一直抖動或穿過玩家")
