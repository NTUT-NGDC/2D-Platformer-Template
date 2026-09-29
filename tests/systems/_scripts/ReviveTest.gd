extends Node2D

# 手動驗證用：Player.kill() 只宣告死亡、Player.revive() 把狀態全部歸零。
# 這個場景故意沒有任何重生處理者，死亡後玩家會停在原地不動，直到按 R 手動復活。
# 按 G 翻轉重力、按 B 變大兩倍、按 H 扣 1 血、按 K 死亡、按 R 復活到起點。

@onready var _player: CharacterBody2D = $Player

var _start_position: Vector2 = Vector2.ZERO

# 記住起點並接上死亡／重生訊號，印出操作說明
func _ready() -> void:
	_start_position = _player.global_position
	Events.player_died.connect(func(): print("[測試] 收到 player_died，玩家應該停在原地不動、沒有自動重生"))
	Events.player_respawned.connect(func(_p): print("[測試] 收到 player_respawned"); _print_state())
	print("[測試] 按 G 翻轉重力、按 B 變大兩倍、按 H 扣 1 血、按 K 死亡、按 R 復活到起點")
	print("[測試] 建議順序：G → B → H → K（確認沒有自動重生）→ R")
	print("[測試] 復活後應該：回到起點、重力朝下、大小 1、血量補滿、可以正常移動跳躍")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_G:
			_player.flip_gravity()
			_print_state()
		KEY_B:
			_player.set_size_factor(2.0)
			_print_state()
		KEY_H:
			_player.take_damage(1.0)
			_print_state()
		KEY_K:
			print("[測試] 模擬死亡")
			_player.kill()
		KEY_R:
			print("[測試] 復活到起點")
			_player.revive(_start_position)

# 印出玩家目前的重力方向、大小、血量
func _print_state() -> void:
	print("[測試] 重力方向：%s　大小：%.1f　血量：%d" % [
		"朝下" if _player.up_direction == Vector2.UP else "朝上",
		_player.size_factor,
		Stats.get_value(Stats.HEALTH_KIND),
	])
