extends Node2D

# 手動驗證用：Spike 依 penalty 扣血或即死，碰一次算一次。

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_player.hurt.connect(func(): print("[測試] 玩家受傷了（Spike_Damage）"))
	_player.died.connect(func(): print("[測試] 玩家死亡"))
	print("[測試] 左邊 Spike_Damage（damage=2）：走過去碰一下，應該扣 2 點血，血量預設 3，碰兩次會死")
	print("[測試] 右邊 Spike_Instant（即死）：碰到立刻死亡")
