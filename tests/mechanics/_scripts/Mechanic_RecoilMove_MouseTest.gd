extends Node2D

# 手動驗證用：Mechanic_RecoilMove 的 input_type 選「滑鼠左鍵」，點滑鼠左鍵往游標的反方向噴射，
# 方向鍵不能動也不會噴；次數、冷卻、落地補滿規則跟方向鍵模式一樣。

# 印出操作說明
func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 角色一開始在半空中。把游標放在角色下方點左鍵，角色應該往上噴；放在左邊點，應該往右噴")
	print("[測試] 游標放在斜下方點，應該往斜上方噴（方向跟著游標，不只上下左右）")
	print("[測試] 按方向鍵應該完全沒反應（不能走、也不會噴）")
	print("[測試] 空中最多噴 3 次，第 4 次閃灰、印出 recoil_empty；落地後補滿")
	print("[測試] 游標剛好點在角色身上不會噴")

# 印出機制卡事件
func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
