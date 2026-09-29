extends Node2D

# 手動驗證用：Button 的「指定群組」。左邊箱子加了「鑰匙」群組，右邊箱子沒有；
# 左右兩個按鈕都只讓「鑰匙」群組踩（右邊那個故意在名字前後多打空白，測自動整理）。
# 最左邊的按鈕 tag 故意打錯成「鑰是」、最右邊的 tag 空白，執行時應該各印一則中文警告。

@onready var _button_left: Area2D = $Button_KeyLeft
@onready var _button_right: Area2D = $Button_KeyRight

func _ready() -> void:
	_button_left.turned_on.connect(func(): print("[測試] 左邊按鈕 turned_on（應該只在鑰匙箱子壓上去時出現）"))
	_button_left.turned_off.connect(func(): print("[測試] 左邊按鈕 turned_off"))
	_button_right.turned_on.connect(func(): print("[測試] 右邊按鈕 turned_on（普通箱子推上去不應該出現；把鑰匙箱子推過來才會）"))
	_button_right.turned_off.connect(func(): print("[測試] 右邊按鈕 turned_off"))

	print("[測試] 把左邊的鑰匙箱子往左推到按鈕上 → 按鈕變綠；玩家自己踩 → 沒反應")
	print("[測試] 把右邊的普通箱子往右推到按鈕上 → 沒反應")
	print("[測試] 開場應該看到兩則警告：Button_Typo 建議「鑰匙」、Button_Empty 說 tag 是空的")
