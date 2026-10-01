extends Node2D

# 手動驗證用：Spike 依 penalty 扣血（走 take_hit：有擊退、發 Events.hit）或即死，碰一次算一次。

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_player.hurt.connect(func(): print("[測試] 玩家受傷了（Spike_Damage）"))
	_player.died.connect(func(): print("[測試] 玩家死亡"))
	Events.hit.connect(func(target, source): print("[測試] Events.hit：%s 被 %s 打到" % [target.name, source.name]))
	print("[測試] 左邊 Spike_Damage（damage=2）：走過去碰一下，應該扣 2 點血並被往外、往上彈開，印出 Events.hit；血量預設 3，碰兩次會死")
	print("[測試] 右邊 Spike_Instant（即死）：碰到立刻死亡")
