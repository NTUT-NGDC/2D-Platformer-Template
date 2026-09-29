extends Node2D

# 手動驗證用：零件的 reset()。所有物件都掛在所在的 Room 底下。Room1 有一個箱子；Room2 有箱子、3 枚金幣、
# 兩塊疊起來的可破壞方塊（不會自己長回來）、一塊崩塌地板（不會自己長回來），敵人放在「不放回」的重生分組 OneTime 裡，
# Coin_3 放在「數值不倒回」的重生分組 Farm 裡（刷金幣：金幣會回來，撿到的也算數）。
# 按 X 對所有敵人與可破壞方塊造成 99 點傷害、按 K 立刻死亡。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	Events.player_respawned.connect(func(_p): print("[測試] 重生完成，金幣：%d" % Stats.get_value("金幣")))
	print("[測試] 按 X 打倒所有敵人並打破所有可破壞方塊、按 K 立刻死亡")
	print("[測試] ① 在 Room1 把箱子往右推一段 → 走進 Room2")
	print("[測試] ② 在 Room2：按 X（敵人消失、方塊碎掉）→ 撿 3 枚金幣 → 推一下箱子 → 跳上崩塌地板讓它碎掉 → 按 K")
	print("[測試]    重生後 Room2 應該：方塊長回來、3 枚金幣都回來、箱子回原位、崩塌地板長回來")
	print("[測試]    金幣數是 1（Coin_1、Coin_2 扣回，Coin_3 在 Farm 分組不倒回）；再撿一次 Coin_3 會變 2")
	print("[測試]    敵人不會回來（在「不放回」的分組 OneTime 裡）")
	print("[測試]    Room1 的箱子應該維持被推過的位置（只重置目前房間）")
	print("[測試] ③ 走回 Room1 按 K：Room1 的箱子回原位")
	print("[測試] ④ 停止，把 RespawnHandler 的 mode 改成「整關重來」再跑：在 Room2 按 X 再按 K，敵人要回來（整關重來不看分組）")
	print("[測試] ⑤ 停止，把 OneTime 拖到 Room2 外面（關卡底下）再跑：輸出面板印出分組沒放在 Room 底下的警告")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_X:
		for node in find_children("*", "", true, false):
			if node.has_method("take_hit") and node != _player and not (node is RigidBody2D):
				node.take_hit(99, Vector2.ZERO, _player)
		print("[測試] 打倒敵人、打破方塊")
	elif event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
