extends Node2D

# 手動驗證用：SwitchBlock 的 color 分組（switch_red/switch_blue）以及玩家重疊時延後實體化。
# 因為「開關世界」規則卡（U49）還沒做，這裡直接呼叫 set_active() 模擬規則卡的控制。

@onready var _block_red: Node2D = $SwitchBlock_Red
@onready var _block_blue: Node2D = $SwitchBlock_Blue

func _ready() -> void:
	print("[測試] SwitchBlock_Red 屬於 switch_red：%s" % _block_red.is_in_group("switch_red"))
	print("[測試] SwitchBlock_Blue 屬於 switch_blue：%s" % _block_blue.is_in_group("switch_blue"))
	print("[測試] 左邊紅色方塊一開始實心擋路。3 秒後會消失，走進原本方塊的位置站著")
	await get_tree().create_timer(3.0).timeout
	_block_red.set_active(false)
	print("[測試] SwitchBlock_Red 已關閉，走進去站著，5 秒後會嘗試重新開啟")
	await get_tree().create_timer(5.0).timeout
	print("[測試] 呼叫 set_active(true)：如果你還站在裡面，應該不會立刻變回實心")
	_block_red.set_active(true)
	print("[測試] 走出方塊範圍後，才會真的變回實心（顏色恢復、擋住去路）")
