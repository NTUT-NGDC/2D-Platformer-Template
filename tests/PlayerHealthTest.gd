extends Node

# 手動驗證用：Player.take_damage() 內部委派給 Stats 扣血量，血量歸零時 Stats 自動呼叫 kill()

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_player.died.connect(_on_player_died)
	print("[測試] 血量目前值：%d（應該是 3）" % Stats.get_value(Stats.HEALTH_KIND))
	await get_tree().create_timer(1.0).timeout
	print("[測試] 扣 1 點傷害，畫面左上角應該出現血條")
	_player.take_damage(1.0)
	print("[測試] 血量目前值：%d（應該是 2）" % Stats.get_value(Stats.HEALTH_KIND))
	await get_tree().create_timer(1.0).timeout
	print("[測試] 再扣 2 點傷害，血量應該歸零並觸發死亡")
	_player.take_damage(2.0)
	print("[測試] 血量目前值：%d（應該是 0）" % Stats.get_value(Stats.HEALTH_KIND))

# Player.died 訊號有觸發，證明 Stats 血量歸零時成功呼叫了 kill()
func _on_player_died() -> void:
	print("[測試] Player.died 觸發了，代表 Stats 血量歸零時成功呼叫了 kill()")
