extends Node2D

# 手動驗證用：Mechanic_TouchDeath 碰到敵人／箱子／牆各自依開關致死，死亡後由 RespawnHandler 軟重生。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 預設 die_on_enemy／die_on_box 開、die_on_wall 關")
	print("[測試] 往右走碰到敵人應該直接死掉重來，碰到箱子也應該直接死掉重來")
	print("[測試] 場景最右邊有一面牆，預設碰到不會死；想測 die_on_wall 的話先在")
	print("[測試] Inspector 把 Mechanic_TouchDeath 的 die_on_wall 打開再進來玩")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
