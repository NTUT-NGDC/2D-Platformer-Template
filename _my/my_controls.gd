extends Node

# 這裡放你自己的按鍵要做的事。把 KeyTrigger_E／KeyTrigger_1 的訊號（例如 pressed）接到
# 下面這些函式，或者直接接到你擺的零件身上（不寫程式也可以）。

# 按下 E 執行；把 print 換成你想做的事，例如呼叫你擺的零件的 activate()
func on_e_pressed() -> void:
	print("按下 E 了")

# 按下 1 執行，寫法跟上面一樣
func on_1_pressed() -> void:
	print("按下 1 了")
