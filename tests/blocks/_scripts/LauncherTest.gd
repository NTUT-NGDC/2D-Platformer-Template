extends Node2D

# 手動驗證用：Launcher 彈簧固定力道、彈跳床依撞擊（落下）速度反彈。

@onready var _spring: Node2D = $Launcher_Spring
@onready var _trampoline: Node2D = $Launcher_Trampoline

func _ready() -> void:
	_spring.launched.connect(func(_body): _print_launched("Launcher_Spring"))
	_trampoline.launched.connect(func(_body): _print_launched("Launcher_Trampoline"))
	print("[測試] 左邊 Launcher_Spring（彈簧，force=500）：直接走上去，不管怎麼碰都應該固定彈那麼高")
	print("[測試] 右邊 Launcher_Trampoline（彈跳床，force 上限=500）：")
	print("[測試]   直接走上去只是輕輕碰到，彈得比較低（有保底最低彈力）")
	print("[測試]   先往上跳一下、下墜時再落到上面，落下速度比較快，應該明顯彈得更高")

# 每次彈出都印一次，方便對照
func _print_launched(source_name: String) -> void:
	print("[測試] %s 觸發 launched" % source_name)
