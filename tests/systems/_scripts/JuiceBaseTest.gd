extends Node2D

# 手動驗證用：JuiceBase 擴充。Player → Juice 底下每種觸發時機各掛一個測試組件，觸發時印出一行。
# 另外有一個持續型、一個故意掛錯位置的組件；重力翻轉卡的 flipped 和 J 鍵觸發器的 released（帶參數）
# 都連到 Probe_Manual 的 play()。

@onready var _player: CharacterBody2D = $Player
@onready var _manual: Node = $Player/Juice/Probe_Manual

# 印出操作說明
func _ready() -> void:
	print("[測試] 方向鍵移動、空白跳、F 攻擊、Q 翻轉重力、J 放開時觸發、H 受傷、K 死亡、L 過關、B 連發、T 角色變紅、X 拔掉 Probe_Tint")
	print("[測試] ① 開場：輸出面板有「Probe_Misplaced … 請把這個節點拖進 Player → Juice 底下」的警告，連線驗證器沒有報錯")
	print("[測試] ② 跳、落地（從高處和低處各一次，強度不同）、撞牆、開始移動、轉向、受傷、死亡、重生：各印一行對應時機")
	print("[測試] ③ F 打箱子／敵人 →「打中東西時」位置在被打的東西；打倒敵人 →「打倒敵人時」；吃到金幣 →「撿到東西時」；L →「過關時」")
	print("[測試] ④ Q 翻轉重力、按住 J 再放開：Probe_Manual「不自動觸發」各印一行（J 的訊號帶參數也能接）")
	print("[測試] ⑤ B：同一幀呼叫 play() 五次，只印一行；0.1 秒後再呼叫一次，又印一行")
	print("[測試] ⑥ T 角色變紅 → K 死亡：重生後顏色恢復；T 再變紅 → X：Probe_Tint 被拔掉，顏色立刻恢復")
	print("[測試] ⑦ 編輯器裡點 Probe_Landed：看得到 follow_impact；改成別的時機就消失；點 Probe_Continuous：看不到 timing")

# 除錯按鍵
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
			await Events.player_respawned
			print("[測試] 重生後角色顏色：%s（應該是白色）" % _player.visual.get_child(0).modulate)
		KEY_L:
			print("[測試] 模擬過關")
			Events.level_cleared.emit()
		KEY_B:
			print("[測試] 連發 play() 五次")
			for i in 5:
				_manual.play()
			await get_tree().create_timer(0.1).timeout
			print("[測試] 0.1 秒後再一次")
			_manual.play()
		KEY_T:
			var tint_probe := get_node_or_null("Player/Juice/Probe_Tint")
			if tint_probe:
				_player.set_juice_tint(tint_probe, Color(1, 0.3, 0.3))
				print("[測試] Probe_Tint 把角色變紅")
			else:
				print("[測試] Probe_Tint 已經被拔掉了")
		KEY_X:
			var tint_probe := get_node_or_null("Player/Juice/Probe_Tint")
			if tint_probe:
				tint_probe.queue_free()
				await get_tree().create_timer(0.1).timeout
				print("[測試] 拔掉 Probe_Tint，角色顏色：%s（應該是白色）" % _player.visual.get_child(0).modulate)
