extends Node2D

# 手動驗證用：粒子噴發。Juice_Particles 用預設值（落地時從腳底噴塵土），
# 其他三個：打中東西時在被打的地方噴火花、撿到東西時在金幣位置噴星星、打倒敵人時在敵人位置噴紅色碎片。
# Juice_Particles_Custom：跳躍時噴自訂場景（tests/juice/Particles_TestIcon.tscn，用 Godot 圖示當粒子圖）。
# Juice_Particles_Template：受傷時用底下的 Rain 子節點當樣板（藍色的雨往下落）。
# Juice_Particles_Broken：樣式選「自訂場景」但沒放場景，故意設錯。
# Juice_Particles_Smoke：撞牆時從身體冒煙霧。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	print("[測試] 方向鍵移動、空白跳、F 攻擊、Q 翻轉重力、H 受傷、K 死亡、C 數場上的粒子、0 Juice 總開關")
	print("[測試] ⓪ 開場：輸出面板有 Juice_Particles_Broken「custom_particles 是空的」警告，Juice_Particles_Template「使用子節點 Rain 當粒子樣板」；")
	print("[測試]    編輯器場景樹上 Juice_Particles_Broken 有黃色驚嘆號")
	print("[測試] ① 跳一下落地：腳底往兩旁噴一小撮塵土，粒子留在原地不跟著角色走")
	print("[測試] ② 按 Q 翻到天花板：塵土從天花板那一側噴出、往下飄（上下顛倒）")
	print("[測試] ③ F 打箱子：在箱子位置噴火花；打倒敵人：在敵人位置噴紅色碎片，往上噴再掉下來")
	print("[測試] ④ 撿金幣：金幣位置周圍出現黃色星星，原地不動、一閃一閃")
	print("[測試] ④-2 往左撞牆（或撞箱子）：身體位置陸續冒出灰色煙霧，慢慢往上飄、變大、變淡")
	print("[測試] ⑤ 起跳：從身體噴出幾個 Godot 圖示（自訂場景）；按 H：身體周圍落下藍色的雨（子節點樣板），樣板本身平常看不到")
	print("[測試] ⑥ 噴完一秒後按 C：場上的粒子數量是 0（噴完會自己消失）")
	print("[測試] ⑦ 編輯器裡點 Juice_Particles_Custom：只看得到 style、custom_particles、spawn_at；點 Juice_Particles_Template：只看得到 spawn_at")

# 除錯按鍵：K 死亡、C 數場上還有幾組粒子
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
		KEY_C:
			var count := 0
			for n in get_children():
				if n is CPUParticles2D:
					count += 1
			print("[測試] 場上還有 %d 組粒子" % count)
