extends Node2D

# 手動驗證用：OneWayPlatform 下方跳上去可以穿過、落下時會站在上面。

func _ready() -> void:
	print("[測試] 走到左邊 OneWayPlatform_A（4 格寬）正下方，往上跳：應該直接穿過去，")
	print("[測試] 到最高點開始下墜時會被平台擋住，站在平台上面")
	print("[測試] 右邊 OneWayPlatform_B 是 8 格寬版本，確認寬度看起來明顯比較寬")
	print("[測試] 站在平台上時，走到邊緣掉下去，應該能正常掉回地板")
