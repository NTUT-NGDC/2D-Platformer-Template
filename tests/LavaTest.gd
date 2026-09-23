extends Node2D

# 手動驗證用：Lava 站上去依 instant_kill 扣血或即死。

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_player.hurt.connect(func(): print("[測試] 玩家受傷了（Lava_Damage 每秒扣血中）"))
	_player.died.connect(func(): print("[測試] 玩家死亡"))
	print("[測試] 左邊 Lava_Damage（damage_per_second=1）：站上去每秒扣 1 點血，血量預設 3 點，約 3 秒後死亡重生")
	print("[測試] 右邊 Lava_Instant（instant_kill=true）：踩到立刻死亡重生，不會慢慢扣血")
