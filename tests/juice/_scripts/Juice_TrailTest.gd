extends Node2D

# 手動驗證用：殘影（持續型）。Juice_Trail 用預設值（速度超過 250 才出現、間隔 12 像素、0.3 秒淡掉）。
# 另外掛了重力翻轉（Q）、忽大忽小（E）、越跑越快（一直跑會變快變紅）、落地擠壓。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	print("[測試] 方向鍵移動、空白跳、Q 翻轉重力、E 切換大小、K 死亡、C 數場上的分身、0 Juice 總開關")
	print("[測試] ① 剛開始走路（速度 200）：沒有殘影；跳起來、或一直跑到越跑越快：身後出現一串半透明分身，慢慢淡掉")
	print("[測試] ② 分身跟角色當下長得一樣：往左跑面向左、變大時分身也大、越跑越快變紅時分身也是紅的、落地壓扁時那一個分身也是扁的")
	print("[測試] ③ 按 Q 翻到天花板：分身也是倒過來的")
	print("[測試] ④ 一直跑的時候按 C：場上的分身不超過 12 個；停下來一秒後按 C：0 個")
	print("[測試] ⑤ 按 0 關掉 Juice：不再出現分身，場上的分身立刻消失")
	print("[測試] ⑥ 編輯器裡點 Juice_Trail：看不到「觸發時機」")

# 除錯按鍵：K 死亡、C 數場上的分身
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_K:
			print("[測試] 模擬死亡")
			_player.kill()
		KEY_C:
			var count := 0
			for n in get_children():
				if n is Node2D and n.z_index == -1 and n.get_child_count() > 0 and n.get_child(0) is Sprite2D:
					count += 1
			print("[測試] 場上有 %d 個分身" % count)
