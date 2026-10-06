extends Node2D

# 手動驗證用：閃色。角色圖先調成淺藍色，白色閃光才看得出來。
# Juice_Flash 用預設值（受傷時閃紅 3 次），Juice_Flash_Jump 跳躍時閃白 1 次，Juice_Flash_Land 落地時閃黑 1 次。
# 另外掛了越跑越快（一直跑會慢慢變紅）。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	print("[測試] 方向鍵移動、空白跳、H 受傷、K 死亡、P 印出角色圖顏色、0 Juice 總開關")
	print("[測試] ① 按 H：角色閃紅 3 次，約 0.4 秒後回到淺藍色")
	print("[測試] ② 起跳：閃白一下（變亮）；落地：閃黑一下")
	print("[測試] ③ 一直往右跑到 Visual 變紅（越跑越快），再按 H：閃色疊在上面，閃完還是越跑越快的顏色")
	print("[測試] ④ 按 H 後馬上按 K：重生後是原本的淺藍色，不會卡在紅色")
	print("[測試] ⑤ 沒有在閃時按 P：角色圖顏色應該是 (0.45, 0.65, 1.0, 1.0)")

# 除錯按鍵：H 受傷、K 死亡、P 印出角色圖顏色
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_H:
			print("[測試] 模擬受傷")
			_player.take_damage(1)
		KEY_K:
			print("[測試] 模擬死亡")
			_player.kill()
		KEY_P:
			print("[測試] 角色圖顏色%s ｜ Visual 顏色%s" % [_player.visual.get_child(0).modulate, _player.visual.modulate])
