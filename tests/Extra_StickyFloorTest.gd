extends Node2D

# 手動驗證用：Extra_StickyFloor 站在地板上變慢或黏住走不動，離地立刻恢復正常。

func _ready() -> void:
	print("[測試] 預設是「變慢」模式：站在地板上左右移動應該明顯變慢")
	print("[測試] 跳起來在空中應該完全不受影響，正常速度")
	print("[測試] 想測「黏住走不動」模式：進場前先在 Inspector 把 effect 切過去，")
	print("[測試] 這時候站在地板上應該完全走不動，但還是可以跳出去")
