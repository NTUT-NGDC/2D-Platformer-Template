extends Node2D

# 手動驗證用：機制卡的 on_respawn()。掛了重力翻轉（Q）、忽大忽小（E）、越跑越快三張卡，
# 場景有一個 Room 與 RespawnHandler。按 K 立刻死亡，0.8 秒後自動重生。

@onready var _player: CharacterBody2D = $Player

# 重生後印出狀態，印出操作說明
func _ready() -> void:
	Events.player_respawned.connect(func(_p): _print_state())
	print("[測試] Q 翻轉重力、E 切換大小、左右一直跑會越來越快越來越紅、K 立刻死亡")
	print("[測試] ① 按 Q 翻到天花板 → 按 K：重生後站在地板上，角色圖不是倒的")
	print("[測試] ② 按 E 變大 → 按 K：重生後是一開始的小體型（0.5），不是大的")
	print("[測試] ③ 往右跑到變紅 → 按 K：重生後顏色是白的、速度回到正常")
	print("[測試] ④ Q、E 都按過再按 K，重生後兩個都復位；之後 Q、E 還能正常用")

# 除錯按鍵：K 死亡
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()

# 印出玩家目前的重力方向、大小、角色圖上下方向與顏色
func _print_state() -> void:
	var visual: Node2D = _player.visual
	print("[測試] 重生後 → 重力：%s　大小：%.2f　角色圖：%s　顏色：%s" % [
		"朝下" if _player.up_direction == Vector2.UP else "朝上",
		_player.size_factor,
		"正" if visual.scale.y > 0.0 else "倒",
		visual.modulate,
	])
