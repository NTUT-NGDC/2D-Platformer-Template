extends Node

# 玩家死亡後自動重生：整場重新載入，不需要碰 Player 內部狀態。

const 重生延遲 := 1.0

func _ready() -> void:
	Events.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	await get_tree().create_timer(重生延遲).timeout
	Events.level_restarted.emit()
	get_tree().reload_current_scene()
