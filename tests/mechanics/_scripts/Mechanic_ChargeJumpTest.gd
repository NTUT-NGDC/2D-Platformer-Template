extends Node2D

# 手動驗證用：Mechanic_ChargeJump 按住跳躍鍵蓄力、放開才跳，蓄力時間影響跳躍高度，
# 蓄力時左右移動會被鎖住（lock_move_while_charging），Player 自己的預設跳躍不會重複觸發。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 快點一下空白鍵馬上放開：應該只跳一個小低高度（min_jump_ratio）")
	print("[測試] 按住空白鍵蓄力 1 秒以上再放開：應該跳得明顯更高")
	print("[測試] 蓄力過程中嘗試按左右方向鍵：角色應該完全不會移動（lock_move_while_charging 開著）")
	print("[測試] 確認過程中只會跳一次，不會又低又高疊加成兩段跳")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
