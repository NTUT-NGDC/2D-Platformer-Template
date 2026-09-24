extends Node2D

# 手動驗證用：零件的 reset()。Room1 有一個箱子；Room2 有箱子、敵人、3 枚金幣、兩塊疊起來的
# 可破壞方塊（不會自己長回來）、一塊崩塌地板（不會自己長回來）。
# 按 X 對所有敵人與可破壞方塊造成 99 點傷害、按 K 立刻死亡。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	Events.player_respawned.connect(func(_p): print("[測試] 重生完成，金幣：%d" % Stats.get_value("金幣")))
	print("[測試] 按 X 打倒所有敵人並打破所有可破壞方塊、按 K 立刻死亡")
	print("[測試] ① 在 Room1 把箱子往右推一段 → 走進 Room2")
	print("[測試] ② 在 Room2：按 X（敵人消失、方塊碎掉）→ 撿 3 枚金幣 → 推一下箱子 → 跳上崩塌地板讓它碎掉 → 按 K")
	print("[測試]    重生後 Room2 應該：敵人回來、方塊長回來、金幣回來（金幣數退回 0）、箱子回原位、崩塌地板長回來")
	print("[測試]    Room1 的箱子應該維持被推過的位置（只重置目前房間）")
	print("[測試] ③ 走回 Room1 按 K：Room1 的箱子回原位")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_X:
		for node in get_children():
			if node.has_method("take_hit") and node != _player and not (node is RigidBody2D):
				node.take_hit(99, Vector2.ZERO, _player)
		print("[測試] 打倒敵人、打破方塊")
	elif event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
