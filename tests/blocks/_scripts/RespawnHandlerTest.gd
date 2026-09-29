extends Node2D

# 手動驗證用：RespawnHandler 軟重生。兩個 Room 並排，Room2 底下有 Marker2D（小平台上），
# Room2 右邊有一個 Checkpoint。按 C 加 5 個金幣、按 K 立刻死亡。

@onready var _player: CharacterBody2D = $Player

# 接上重生相關訊號，印出操作說明
func _ready() -> void:
	Events.respawn_requested.connect(func(_p): print("[測試] 收到 respawn_requested"))
	Events.player_respawned.connect(func(_p): print("[測試] 收到 player_respawned，金幣：%d" % Stats.get_value("金幣")))
	Events.level_restarted.connect(func(): print("[測試] 收到 level_restarted"))
	print("[測試] 按 C 加 5 個金幣、按 K 立刻死亡")
	print("[測試] ① 在 Room1 按 C 兩次（10 金幣）→ 走進 Room2 → 按 C 一次（15）→ 按 K")
	print("[測試]    應該：0.8 秒後重生在 Room2 小平台上（Marker2D），金幣退回 10（進 Room2 當下），鏡頭留在 Room2")
	print("[測試] ② 走到 Room2 右邊踩 Checkpoint（變綠）→ 按 K：應該重生在 Checkpoint，不是小平台")
	print("[測試] ③ 走回 Room1 → 按 K：應該重生在 Room1 底部中央（Checkpoint 在別的房間，不算）")
	print("[測試] ④ 停止，把 RespawnHandler 的 mode 改成「整關重來」再跑：在 Room2 按 K，應該回到 Room1 起點、金幣退回 0、鏡頭切回 Room1")
	print("[測試] ⑤ 停止，刪掉 RespawnHandler 再跑：按 K 後玩家停住不重生，輸出面板印出中文提示，沒有紅字錯誤")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_C:
		Stats.add("金幣", 5)
		print("[測試] 金幣 +5，目前：%d" % Stats.get_value("金幣"))
	elif event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
