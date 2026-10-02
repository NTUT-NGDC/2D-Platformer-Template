extends Node2D

# 手動驗證用：四個 Room 並排＋多個重生點，測「唯一的重生位置」：走進房間記房間起點、踩重生點記重生點，
# 死掉回到最後記下的那個。重生點都是預設的「只有第一次踩到」才記。
# Room1：一般房間＋一個重生點。Room2：兩個重生點（A 在左、B 在右）。Room3：不使用房間起點、沒有重生點。
# Room4：房間起點拉到左邊（spawn_x 5）＋一個重生點在最右邊。每個房間各有一枚金幣。按 K 死亡、按 R 整關重來。

@onready var _player: CharacterBody2D = $Player

# 接上重生相關訊號，印出測試步驟
func _ready() -> void:
	Events.room_entered.connect(func(room): print("[測試] 進入 %s，金幣：%d" % [room.name, Stats.get_value("金幣")]))
	Events.checkpoint_reached.connect(func(cp): print("[測試] 踩到 %s" % cp.name))
	Events.player_respawned.connect(func(p): print("[測試] 重生在 %s，金幣：%d" % [_describe(p.global_position), Stats.get_value("金幣")]))
	print("[測試] 按 K 死亡、按 R 整關重來。每一步做完看「重生在 …」那行對不對；輸出面板的「重生位置改成 …」會說目前記下哪裡")
	print("[測試] ① Room1 還沒踩重生點就按 K → Room1 房間起點（一開場走進 Room1 就記下了）")
	print("[測試] ② 踩 Checkpoint_Room1 → 按 K → Checkpoint_Room1（重生點蓋過房間起點）")
	print("[測試] ③ 進 Room2 → 按 K → Room2 房間起點（進房間又蓋過重生點）")
	print("[測試] ④ 踩 Room2_A、再踩 Room2_B → 按 K → Checkpoint_Room2_B（最後踩的）")
	print("[測試] ⑤ 走回 Room1 → 按 K → Room1 房間起點（每次進入都記）；再踩 Checkpoint_Room1 → 按 K → 還是 Room1 房間起點")
	print("[測試]    （Checkpoint_Room1 是「只有第一次踩到」，已經踩過不會再記；想要每次都記就把它的 save_trigger 改成「每次踩到」）")
	print("[測試] ⑥ 走到 Room3（不使用房間起點，經過 Room2 時記下 Room2 房間起點）→ 撿金幣 → 按 K → Room2 房間起點、鏡頭切回 Room2；")
	print("[測試]    Room2、Room3 的金幣都回到地上，金幣數扣回")
	print("[測試] ⑦ 走到 Room4 → 按 K → Room4 房間起點（偏左，spawn_x 5）；踩最右邊 Checkpoint_Room4 → 按 K → Checkpoint_Room4")
	print("[測試] ⑧ 按 R 整關重來 → 回到最一開始、金幣 0、所有重生點變回藍色；再踩一次 Checkpoint_Room1 要會變綠並印「踩到」")
	print("[測試] ⑨ 整關重來後直接走到 Room3 按 K → Room2 房間起點（經過 Room2 時記下的，Room3 不使用房間起點）")
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
