extends Node2D

# 手動驗證用：Mechanic_AutoRun 角色自動往一邊跑，撞牆轉向，跳躍鍵仍然有效。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 角色被兩面牆夾住，應該自動左右來回跑，不用按方向鍵")
	print("[測試] 撞到牆的瞬間應該印出一次 wall_turned，角色朝向（貼圖左右翻轉）應該同步改變")
	print("[測試] 按空白鍵跳躍應該正常有效，不受這張卡影響")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
