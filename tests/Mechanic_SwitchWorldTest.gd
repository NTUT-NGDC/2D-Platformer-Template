extends Node2D

# 手動驗證用：Mechanic_SwitchWorld 每隔 switch_seconds 秒讓紅／藍方塊互換實心與虛空，
# 切換前會閃爍提示。

func _ready() -> void:
	Events.mechanic_event.connect(_on_mechanic_event)
	print("[測試] 中間的橋一半紅一半藍，每 2 秒互換：紅實心時藍是虛空，反之亦然")
	print("[測試] 切換前 0.4 秒方塊會先閃爍提示，接著才真的互換")
	print("[測試] 試著在方塊還是實心時站上去，等它切換成虛空應該會直接掉下去")

func _on_mechanic_event(card: String, event: String) -> void:
	print("[測試] Events.mechanic_event：%s / %s" % [card, event])
