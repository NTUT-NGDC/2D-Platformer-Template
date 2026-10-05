extends Node2D

# 手動驗證用：脫殼卡的切換殼、數量上限、可脫次數、死亡處理、顯示方式。兩個房間並排，觸發時機是「按下按鍵」（C）、
# 力道 0（殼留在原地方便數）。Shell_Amber：每個房間 1 顆、最舊的碎掉。Shell_Blue：整個關卡 2 顆、不能再脫。
# Shell_Green：可以脫 3 次。按 K 死亡。

@onready var _player: CharacterBody2D = $Player

# 印出測試步驟
func _ready() -> void:
	print("[測試] 按 C 脫殼、Q／E 切換殼、K 死亡。玩家頭上的小方塊和畫面右上角都會顯示目前選中的殼")
	print("[測試] ① 按 E、Q：頭上小方塊換顏色，右上角換名稱；輸出面板印「Extra_Molt 發出 shell_changed」")
	print("[測試] ② 琥珀殼：在 Room1 按 C、走幾步再按 C → 舊的那顆碎掉（每個房間 1 顆）；走到 Room2 按 C → Room1 那顆還在")
	print("[測試] ③ 藍殼：在任何地方按 C 兩次 → 兩顆都在；第三次 → 不會脫，印「數量滿了」和「Extra_Molt 發出 molt_blocked」")
	print("[測試] ④ 綠殼：頭上和右上角顯示剩 3 次，每脫一顆少 1；剩 0 再按 C → 不會脫，印「次數用完了」和 molt_blocked")
	print("[測試] ⑤ 按 K：重生的那一刻所有殼碎掉，綠殼回到剩 3 次（預設「重生時清掉」）")
	print("[測試] ⑥ 把 Extra_Molt 的「玩家死掉時」改成「死掉時馬上清掉」：按 K 的那一刻殼就碎掉；改成「保留」：殼和次數都留著")
	print("[測試] ⑦ 把「顯示方式」改成「玩家頭上」「畫面右上角」「不顯示」，各跑一次看對不對")
	print("[測試] ⑧ 把 prev_key／next_key 改成別的鍵（例如 Z／X）再跑：改用新的鍵切換")

# 除錯按鍵：K 死亡
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
