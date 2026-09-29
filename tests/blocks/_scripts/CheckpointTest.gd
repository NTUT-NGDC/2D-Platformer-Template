extends Node2D

# 手動驗證用：Checkpoint 踩到時 emit reached，同步轉發 Events.checkpoint_reached，
# 以及 repeatable 欄位（預設關閉＝只算第一次踩到，開啟＝每次踩到都算）。

@onready var _once: Area2D = $Checkpoint_Once
@onready var _repeatable: Area2D = $Checkpoint_Repeatable

func _ready() -> void:
	_once.reached.connect(func(): print("[測試] Checkpoint_Once（repeatable=false）：reached"))
	_repeatable.reached.connect(func(): print("[測試] Checkpoint_Repeatable（repeatable=true）：reached"))
	Events.checkpoint_reached.connect(_on_checkpoint_reached)
	print("[測試] 左邊 Checkpoint_Once 只會在第一次踩到時觸發，之後離開再回來都不會再觸發")
	print("[測試] 右邊 Checkpoint_Repeatable 每次踩到都會觸發，來回走幾次測試看看")

func _on_checkpoint_reached(checkpoint: Node) -> void:
	print("[測試] Events.checkpoint_reached 正確轉發，checkpoint = %s" % checkpoint.name)
