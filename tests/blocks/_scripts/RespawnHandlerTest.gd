extends Node2D

# 手動驗證用：RespawnHandler 軟重生。兩個 Room 並排，Room2 的房間起點拉到小平台上（spawn_x 8、spawn_y 7），
# Room2 右邊有一個 Checkpoint（在 Coin_Room2_A 跟 Coin_Room2_B 中間）。每個房間兩枚金幣，都掛在房間底下。
# 金幣數只會因為撿金幣改變，死掉時放回去的金幣會把數值扣回來。按 K 立刻死亡。

@onready var _player: CharacterBody2D = $Player

# 接上重生相關訊號，印出操作說明
func _ready() -> void:
	Events.respawn_requested.connect(func(_p): print("[測試] 收到 respawn_requested"))
	Events.player_respawned.connect(func(_p): print("[測試] 收到 player_respawned，金幣：%d" % Stats.get_value("金幣")))
	Events.level_restarted.connect(func(): print("[測試] 收到 level_restarted"))
	print("[測試] 按 K 立刻死亡。看「player_respawned，金幣：」那行的數字")
	print("[測試] ① 在 Room1 撿 2 枚金幣（2）→ 走進 Room2 → 撿 Coin_Room2_A（3）→ 按 K")
	print("[測試]    應該：重生在 Room2 小平台上（房間起點），Coin_Room2_A 回到地上，金幣 2，鏡頭留在 Room2")
	print("[測試] ② 撿 Coin_Room2_A（3）→ 踩 Checkpoint（變綠）→ 撿 Coin_Room2_B（4）→ 按 K")
	print("[測試]    應該：重生在 Checkpoint，Room2 兩枚金幣都回到地上，金幣 2")
	print("[測試] ③ 走回 Room1 → 按 K：重生在 Room1 底部中央（走進 Room1 時重生位置就改成 Room1 房間起點，蓋過 Room2 的 Checkpoint），Room1 兩枚金幣回來，金幣 0")
	print("[測試] ④ 停止，把 RespawnHandler 的 mode 改成「整關重來」再跑：撿幾枚金幣後在 Room2 按 K，應該回到 Room1 起點、所有金幣回來、金幣 0")
	print("[測試] ⑤ 停止，刪掉 RespawnHandler 再跑：按 K 後玩家停住不重生，輸出面板印出中文提示，沒有紅字錯誤")
	print("[測試] ⑥ 停止，把 Room1 的 use_room_start 取消勾選（黃點變灰）再跑：撿 Room1 一枚金幣（1）→ 按 K")
	print("[測試]    應該：印「沒有使用房間起點，也還沒踩過任何重生點」，回到玩家一開始的位置，金幣回到地上、金幣 0")
	print("[測試] ⑦ 同樣設定：走到 Room2 踩 Checkpoint → 走回 Room1 → 撿 Room1 兩枚金幣（2）→ 按 K")
	print("[測試]    應該：重生在 Room2 的 Checkpoint、鏡頭切到 Room2、Room1 金幣回到地上、金幣 0")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
