extends Node2D

# 手動驗證用：Extra_StompOnly 一般跳躍完全失效，只能靠往下踩中敵人反彈起跳。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 按跳躍鍵應該完全沒反應（跳躍力歸零）")
	print("[測試] 走到平台邊緣掉下去，落在巡邏的敵人正上方，應該會反彈彈起來，")
	print("[測試] 敵人也會扣血；被反彈起來後可以再踩第二次繼續彈")
	print("[測試] 從旁邊直接撞到敵人（不是從正上方落下）應該不算踩到，只是被撞受傷")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
