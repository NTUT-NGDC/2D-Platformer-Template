extends Node2D

# 手動驗證用：擠壓拉伸。Juice_SquashStretch 用預設值（落地時壓扁、跟著落地力道），
# Juice_SquashStretch_Jump 改成跳躍時拉長。另外掛了重力翻轉（Q）、忽大忽小（E）。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	print("[測試] 方向鍵移動、空白跳、Q 翻轉重力、E 切換大小、K 死亡、P 印出角色圖狀態、0 Juice 總開關")
	print("[測試] ① 起跳：角色拉長一下；落地：壓扁一下再彈回，腳底一直貼著地板")
	print("[測試] ② 按 Q 翻到天花板：貼著天花板那一側壓扁；按 E 變大：變形跟著一起放大")
	print("[測試] ③ 從天花板掉回地板（再按 Q）：壓得比一般跳躍落地扁")
	print("[測試] ④ 起跳後馬上按 K：重生後角色是原本的樣子，不會卡在拉長的形狀")
	print("[測試] ⑤ 隨時按 P：沒有在變形時，角色圖應該是 位置(0, 0) 縮放(1, 1)")

# 除錯按鍵：K 死亡、P 印出角色圖狀態
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_K:
			print("[測試] 模擬死亡")
			_player.kill()
		KEY_P:
			var sprite: Node2D = _player.visual.get_child(0)
			print("[測試] 角色圖 位置%s 縮放%s ｜ Visual 縮放%s" % [sprite.position, sprite.scale, _player.visual.scale])
