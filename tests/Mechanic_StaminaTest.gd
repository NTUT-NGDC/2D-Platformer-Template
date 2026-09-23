extends Node2D

# 手動驗證用：Mechanic_Stamina 移動時扣體力、停下回復；體力歸零依 penalty_mode
# 走不動或變很慢，回到 30% 才解除。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 左邊那條走廊來回跑，左下角體力條應該邊跑邊掉、停下來邊回")
	print("[測試] 體力條見底時應該依 penalty_mode 走不動（預設）或變很慢，回到約 30% 才解除")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
