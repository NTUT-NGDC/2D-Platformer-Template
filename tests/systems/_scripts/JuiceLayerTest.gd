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
	print("[測試] 1＝A 壓扁　2＝B 拉長　3＝A 閃白　4＝B 變紅　5＝C 傾斜（再按一次就撤掉那一項）")
	print("[測試] 6＝撤掉 A 的全部　0＝撤掉全部　P＝印出狀態　Q 翻轉重力　E 切換大小　R 開關自動奔跑")
	print("[測試] ① 按 1：角色壓扁，腳底仍貼著地板（不會浮起來或陷進去）")
	print("[測試] ② 再按 2：壓扁和拉長相乘，大約是 (1.12, 0.78)")
	print("[測試] ③ 按 Q 翻到天花板：還是貼著天花板那一側壓扁；按 E 變大：壓扁跟著一起放大")
	print("[測試] ④ 按 3、4：顏色疊加（偏亮的紅）；往右一直跑，越跑越快的變紅也照常疊上去")
	print("[測試] ⑤ 按 5 傾斜，按 R 自動奔跑會往左右跑：傾斜方向跟著角色朝向鏡像")
	print("[測試] ⑥ 按 6 只拿掉 A 那份（壓扁、閃白消失，B 的拉長和變紅還在）")
	print("[測試] ⑦ 按 0：角色圖完全還原，狀態會印「已還原：是」")

# 數字鍵切換各個請求
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_1: _toggle("a_squash", func(on): _player.set_juice_squash(_a, Vector2(1.4, 0.6) if on else Vector2.ONE))
		KEY_2: _toggle("b_squash", func(on): _player.set_juice_squash(_b, Vector2(0.8, 1.3) if on else Vector2.ONE))
		KEY_3: _toggle("a_tint", func(on): _player.set_juice_tint(_a, Color(2, 2, 2) if on else Color.WHITE))
		KEY_4: _toggle("b_tint", func(on): _player.set_juice_tint(_b, Color(1, 0.3, 0.3) if on else Color.WHITE))
		KEY_5: _toggle("c_tilt", func(on): _player.set_juice_tilt(_c, 0.35 if on else 0.0))
		KEY_6:
			_player.clear_juice(_a)
			_on.erase("a_squash")
			_on.erase("a_tint")
			print("[測試] 撤掉 A")
			_print_state()
		KEY_0:
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
