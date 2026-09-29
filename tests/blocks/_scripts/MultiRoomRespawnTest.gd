extends Node2D

# 手動驗證用：四個 Room 並排＋多個重生點，測房間起點、重生點、use_room_start 同時出現的情況。
# Room1：一般房間＋一個重生點。Room2：兩個重生點（A 在左、B 在右）。Room3：不使用房間起點、沒有重生點。
# Room4：房間起點拉到左邊（spawn_x 5）＋一個重生點在最右邊。每個房間各有一枚金幣。按 K 死亡、按 R 整關重來。

@onready var _player: CharacterBody2D = $Player

# 接上重生相關訊號，印出測試步驟
func _ready() -> void:
	Events.room_entered.connect(func(room): print("[測試] 進入 %s，金幣：%d" % [room.name, Stats.get_value("金幣")]))
	Events.checkpoint_reached.connect(func(cp): print("[測試] 踩到 %s" % cp.name))
	Events.player_respawned.connect(func(p): print("[測試] 重生在 %s，金幣：%d" % [_describe(p.global_position), Stats.get_value("金幣")]))
	print("[測試] 按 K 死亡、按 R 整關重來。每一步做完看「重生在 …」那行對不對")
	print("[測試] ① Room1 還沒踩重生點就按 K → Room1 房間起點（中間）")
	print("[測試] ② 踩 Checkpoint_Room1 → 按 K → Checkpoint_Room1")
	print("[測試] ③ 進 Room2 → 按 K → Room2 房間起點（Room2 的重生點都還沒踩）")
	print("[測試] ④ 踩 Room2_A、再踩 Room2_B → 按 K → Checkpoint_Room2_B（同一間取最後踩的）")
	print("[測試] ⑤ 走回 Room1 → 按 K → Checkpoint_Room1（修正前會錯回 Room1 起點，因為只記得 Room2_B）")
	print("[測試] ⑥ 走到 Room3（不使用房間起點）→ 撿金幣 → 按 K → Checkpoint_Room2_B、鏡頭切回 Room2；Room2、Room3 的金幣都回到地上，金幣數扣回")
	print("[測試] ⑦ 走到 Room4 → 按 K → Room4 房間起點（偏左，spawn_x 5）；踩最右邊 Checkpoint_Room4 → 按 K → Checkpoint_Room4")
	print("[測試] ⑧ 按 R 整關重來 → 回到最一開始、金幣 0、所有重生點變回藍色；再踩一次 Checkpoint_Room1 要會變綠並印「踩到」")
	print("[測試] ⑨ 整關重來後直接走到 Room3 按 K → 回到玩家一開始的位置（一個重生點都沒踩過）")
	print("[測試] 每次重生後「地上的金幣數＋手上的金幣數」要等於 4，不會出現同一枚撿兩次")

# 把重生位置翻成人看得懂的描述：落在哪個重生點或哪個房間
func _describe(pos: Vector2) -> String:
	for cp in get_tree().get_nodes_in_group("checkpoint"):
		if cp.global_position.distance_to(pos) < 1.0:
			return cp.name
	for room in get_tree().get_nodes_in_group("room"):
		if room.get_spawn_point().distance_to(pos) < 1.0:
			return "%s 房間起點" % room.name
	return "其他位置 %s" % pos

# 除錯按鍵：K 死亡、R 暫時切成整關重來再死一次
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
	elif event.physical_keycode == KEY_R:
		print("[測試] 整關重來")
		var handler := $RespawnHandler
		handler.mode = 1
		_player.kill()
		await Events.player_respawned
		handler.mode = 0
