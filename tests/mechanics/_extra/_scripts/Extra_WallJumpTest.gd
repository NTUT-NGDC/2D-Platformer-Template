extends Node2D

# 手動驗證用：Extra_WallJump 貼牆在空中按跳躍鍵會蹬牆反彈並往上跳。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 跳到其中一面牆上貼著，這時候再按一次跳躍鍵，應該會往反方向蹬出去、往上跳")
	print("[測試] 兩面牆之間可以左右蹬牆跳往上爬")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
