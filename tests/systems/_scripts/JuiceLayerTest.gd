extends Node2D

# 手動驗證用：Player 表現層 API（set_juice_squash／set_juice_tint／set_juice_tilt／clear_juice）。
# 用三個假的「組件」A、B、C 發請求，跟重力翻轉（Q）、忽大忽小（E）、自動奔跑（R 開關）、越跑越快一起作用。

@onready var _player: CharacterBody2D = $Player
@onready var _auto_run: Node = $Player/Mechanics/Mechanic_AutoRun

var _a := Node.new()
var _b := Node.new()
var _c := Node.new()
var _on := {}
var _original: Dictionary = {}

# 建立假組件，記住角色圖原本的樣子，印出操作說明
func _ready() -> void:
	for n in [_a, _b, _c]:
		add_child(n)
	_a.name = "A"
	_b.name = "B"
	_c.name = "C"
	var sprite: Node2D = _player.visual.get_child(0)
	_original = {"position": sprite.position, "scale": sprite.scale, "rotation": sprite.rotation, "modulate": sprite.modulate}
	print("[測試] 1＝A 壓扁　2＝B 拉長　5＝C 傾斜（再按一次就撤掉那一項）　3＝A 閃白　4＝B 閃紅（閃 0.3 秒自己恢復）")
	print("[測試] 6＝撤掉 A 的全部　9＝撤掉全部　P＝印出狀態　Q 翻轉重力　E 切換大小　R 開關自動奔跑")
	print("[測試] ① 按 1：角色壓扁，腳底仍貼著地板（不會浮起來或陷進去）")
	print("[測試] ② 再按 2：壓扁和拉長相乘，大約是 (1.12, 0.78)")
	print("[測試] ③ 按 Q 翻到天花板：還是貼著天花板那一側壓扁；按 E 變大：壓扁跟著一起放大")
	print("[測試] ④ 按 3 或 4：閃一下就自己恢復；兩個連續快按會疊成偏亮的紅；一直跑變紅（越跑越快）時再按，閃完還是紅的")
	print("[測試] ⑤ 按 5 傾斜，按 R 自動奔跑會往左右跑：傾斜方向跟著角色朝向鏡像")
	print("[測試] ⑥ 1、2 都開著時按 6：只拿掉 A 的壓扁，B 的拉長還在")
	print("[測試] ⑦ 按 9：角色圖完全還原，狀態會印「已還原：是」")

# 數字鍵切換各個請求
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_1: _toggle("a_squash", func(on): _player.set_juice_squash(_a, Vector2(1.4, 0.6) if on else Vector2.ONE))
		KEY_2: _toggle("b_squash", func(on): _player.set_juice_squash(_b, Vector2(0.8, 1.3) if on else Vector2.ONE))
		KEY_3: _flash(_a, Color(2, 2, 2), "A 閃白")
		KEY_4: _flash(_b, Color(1, 0.3, 0.3), "B 閃紅")
		KEY_5: _toggle("c_tilt", func(on): _player.set_juice_tilt(_c, 0.35 if on else 0.0))
		KEY_6:
			_player.clear_juice(_a)
			_on.erase("a_squash")
			print("[測試] 撤掉 A")
			_print_state()
		KEY_9:
			for n in [_a, _b, _c]:
				_player.clear_juice(n)
			_on.clear()
			print("[測試] 撤掉全部")
			_print_state()
		KEY_R:
			_auto_run.enabled = not _auto_run.enabled
			print("[測試] 自動奔跑：%s" % ("開" if _auto_run.enabled else "關"))
		KEY_P:
			_print_state()

# 切換某一項請求的開關並印出狀態
func _toggle(key: String, apply: Callable) -> void:
	var on: bool = not _on.get(key, false)
	_on[key] = on
	apply.call(on)
	print("[測試] %s：%s" % [key, "開" if on else "關"])
	_print_state()

# 讓某個組件把角色疊上一層顏色，0.3 秒後自己撤掉顏色（之後 U137 閃色組件就是這樣用 API）
func _flash(source: Node, color: Color, label: String) -> void:
	_player.set_juice_tint(source, color)
	print("[測試] %s" % label)
	_print_state()
	await get_tree().create_timer(0.3).timeout
	_player.set_juice_tint(source, Color.WHITE)
	print("[測試] %s 結束" % label)
	_print_state()

# 印出角色圖（Visual 的子節點）與 Visual 本身目前的樣子
func _print_state() -> void:
	var visual: Node2D = _player.visual
	var sprite: Node2D = visual.get_child(0)
	var restored: bool = sprite.position == _original.position and sprite.scale == _original.scale \
		and is_equal_approx(sprite.rotation, _original.rotation) and sprite.modulate == _original.modulate
	print("[測試] 角色圖 位置%s 縮放%s 角度%.2f 顏色%s ｜ Visual 縮放%s 顏色%s ｜ 已還原：%s" % [
		sprite.position, sprite.scale, sprite.rotation, sprite.modulate,
		visual.scale, visual.modulate, "是" if restored else "否",
	])
