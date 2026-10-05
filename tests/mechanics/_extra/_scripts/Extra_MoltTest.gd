extends Node2D

# 手動驗證用：脫殼卡 Extra_Molt（縮小時脫殼、脫出方向、剛脫下的殼不跟玩家互撞、警告）

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 一開始是小隻。按 Shift 變大，再按 Shift 變小：原地留下一顆藍色的殼（跟大隻一樣大），玩家往上彈出去")
	print("[測試] 按住左或右再縮小：往那一邊彈出去；按住下再縮小（在空中比較明顯）：往下彈")
	print("[測試] 同時按住上和左右：往上（預設優先順序 上 > 左右 > 下）；什麼都不按：往上")
	print("[測試] 剛脫下的殼不會把玩家擠開；走出殼之後再走回來，可以推它、跳上去站著")
	print("[測試] 變大時不會脫殼；每縮小一次多一顆殼（數量上限是下一個單元）")
	print("[測試] 卡片底下放了一個不是殼的 NotAShell：輸出面板應該有「不是殼（Shell）」的警告，編輯器場景樹上卡片有黃色驚嘆號")
	print("[測試] 把 Extra_Molt 底下的 Shell_Blue 刪掉再跑：改成用內建的殼（琥珀色）")
	print("[測試] 把 Mechanic_SizeShift 刪掉再跑：輸出面板應該有「場景裡沒有忽大忽小卡」的警告，編輯器卡片有黃色驚嘆號")
	print("[測試] 把 Extra_Molt 的觸發時機改成「按下按鍵」：按 C 就脫殼，不用縮小")
	print("[測試] 把 Extra_Molt 的「start_inside」取消勾選：脫殼的那一刻玩家直接出現在殼外面（往上脫＝站在殼頂上，往左右脫＝緊貼殼的旁邊）")
	print("[測試] 同上，貼著牆往牆的方向脫殼（外面被牆擋住）：退回窩在殼裡，慢慢鑽出來")
	print("[測試] 同上，Inspector 出現「default_direction」：選「面向的方向」或「背對的方向」，不按方向鍵脫殼，應該往那一邊彈出去")

# 脫殼時印一行
func _on_mechanic_event(card: String, event: String) -> void:
	if card == "Extra_Molt":
		print("[測試] 脫殼了（%s）" % event)
