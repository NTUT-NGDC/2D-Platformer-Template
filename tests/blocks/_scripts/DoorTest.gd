extends Node2D

# 手動驗證用：Door 的 Receiver 介面（activate/deactivate/toggle）+ 鑰匙模式的自動開門。
# 「訊號控制」那扇門刻意不先幫你連好訊號——照 01a_shared_systems.md §6 的流程，自己在
# 「節點」面板選 Button_Hold，把 turned_on 連到 Door_Signal 的 activate、turned_off 連到
# deactivate，連好之後重新播放，踩住按鈕門才會開，放開會關上。

@onready var _door_signal: Node2D = $Door_Signal
@onready var _door_key: Node2D = $Door_Key

func _ready() -> void:
	_door_signal.opened.connect(func(): print("[測試] Door_Signal：opened"))
	_door_signal.closed.connect(func(): print("[測試] Door_Signal：closed"))
	_door_key.opened.connect(func(): print("[測試] Door_Key：opened（鑰匙用掉了）"))

	print("[測試] 這個場景故意不幫你連訊號：先在「節點」面板選 Button_Hold，")
	print("[測試] 把 turned_on 連到 Door_Signal 的 activate、turned_off 連到 deactivate")
	print("[測試] 連好後重新播放，踩住按鈕門才會打開，放開會關上")
	print("[測試] 玩家身上已經給了 1 把鑰匙，走到右邊 Door_Key 那扇門會自動開並用掉鑰匙")
	Stats.add("鑰匙", 1)
