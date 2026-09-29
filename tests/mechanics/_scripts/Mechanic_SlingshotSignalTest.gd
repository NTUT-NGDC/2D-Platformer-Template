extends Node2D

# 手動驗證用：彈弓卡的 drag_started／launched 訊號連到 Player 的動作函式。三個場景共用這個腳本，
# 差別只在場景裡的連線（節點面板看 Mechanic_Slingshot 的訊號）。ground_only 關掉，才能在空中拉。

## 這個場景示範的連法，只用來印說明
@export var case_name: String = ""

@onready var _slingshot: Node = $Player/Mechanics/Mechanic_Slingshot

# 印出這個場景要怎麼測，並監聽兩個訊號印出發出時機
func _ready() -> void:
	_slingshot.drag_started.connect(func(): print("[測試] drag_started 發出"))
	_slingshot.launched.connect(func(): print("[測試] launched 發出（推力施加之前）"))
	print("[測試] 這個場景的連法：%s" % case_name)
	print("[測試] 先拉一次往上射到空中，趁還在飛的時候再按住滑鼠左鍵拉第二次，觀察差別")
	match case_name:
		"開始拉的時候歸零":
			print("[測試] 預期：一按下去速度瞬間歸零，之後照樣往下掉；放開照常射出")
		"射出前歸零":
			print("[測試] 預期：拉的時候照樣在飛／掉；放開時先停住再射，射出去的方向不會被原本的速度帶歪")
		"拉的時候停在空中":
			print("[測試] 預期：一按下去就停在半空中，拉多久都不會掉；放開才射出去。拉的距離是 0 直接放開也要能恢復下墜")
