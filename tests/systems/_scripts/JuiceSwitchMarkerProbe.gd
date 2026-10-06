@tool
extends JuiceBase

# 測試用的持續型 Juice：在角色頭上畫一個黃色方塊，總開關關掉時跟著消失

# 宣告自己是持續型
func _is_continuous() -> bool:
	return true

# 畫出頭上的黃色方塊
func _draw() -> void:
	draw_rect(Rect2(-4, -30, 8, 8), Color.YELLOW)
