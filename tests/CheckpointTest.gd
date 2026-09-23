extends Node2D

# 手動驗證用：Checkpoint 踩到時 emit reached，同步轉發 Events.checkpoint_reached。
# 用方向鍵走到重生點上，顏色應該從藍變綠，輸出面板印出兩則訊息。

@onready var _checkpoint: Area2D = $Checkpoint

func _ready() -> void:
	_checkpoint.reached.connect(func(): print("[測試] Checkpoint.reached 觸發了"))
	Events.checkpoint_reached.connect(_on_checkpoint_reached)
	print("[測試] 用方向鍵／AD 走到重生點（藍色方塊）上，顏色應該變綠，並印出兩則訊息")

func _on_checkpoint_reached(checkpoint: Node) -> void:
	print("[測試] Events.checkpoint_reached 正確轉發，checkpoint = %s" % checkpoint.name)
