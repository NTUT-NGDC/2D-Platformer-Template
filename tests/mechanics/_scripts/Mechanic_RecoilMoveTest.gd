extends Node2D

# 手動驗證用：Mechanic_RecoilMove 按方向鍵往反方向噴射移動，空中次數有限、落地補滿，
# 地面上不限次數。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 角色一開始在半空中。按方向鍵（上下左右）應該往反方向噴一下")
	print("[測試] 空中最多噴 3 次（air_charges=3），第 4 次應該閃灰、印出 recoil_empty，不會真的噴")
	print("[測試] 落地後（refill_on_land 開著）次數應該補滿，可以再噴 3 次")
	print("[測試] 站在地面上時噴射應該不限次數（air_charges 只限制空中）")
	print("[測試] 噴射後 0.3 秒內連按應該不會生效（cooldown）")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
