extends Node2D

# 手動驗證用：Door 開門方式選「自訂數值」的打字欄位與防呆（空白、打錯字、場景裡沒人給這個數值）。

@onready var _door_star: Node2D = $Door_Star

func _ready() -> void:
	_door_star.opened.connect(func(): print("[測試] Door_Star：opened（星星剩 %d，應該是 0）" % Stats.get_value("星星")))
	print("[測試] 先看編輯器場景樹：Door_Typo、Door_Missing、Door_Empty 有黃色驚嘆號，Door_Star 沒有")
	print("[測試] 開場輸出面板應該有三則 [門] 警告：Door_Typo「是不是想打『星星』」、Door_Missing「場景裡沒有…『月亮』」、Door_Empty 空白")
	print("[測試] 走過地上那顆星星（不要跳）去碰 Door_Star：不會開（需要 2 顆）")
	print("[測試] 退回去跳起來吃空中那顆，再碰一次門：門打開、星星被用掉")
