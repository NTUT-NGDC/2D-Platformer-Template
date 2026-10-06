extends Node2D

# 手動驗證用：Juice 總開關（JuiceSwitch）。Player → Juice 底下掛了跳躍時擠壓（一次型）、
# 頭上黃色方塊（持續型）、Probe_Tint（T 鍵讓它把角色變紅）。

@onready var _player: CharacterBody2D = $Player
@onready var _tint_probe: Node = $Player/Juice/Probe_Tint

# 印出操作說明
func _ready() -> void:
	print("[測試] 0＝Juice 總開關　空白跳　T＝角色變紅　M＝連續切換 10 次　P＝印出狀態")
	print("[測試] ① 開場：頭上有黃色方塊，跳一下角色會壓扁再彈回")
	print("[測試] ② 按 0：右上角顯示「Juice：關」兩秒後消失；黃色方塊不見；跳躍不再壓扁")
	print("[測試] ③ 再按 0：右上角「Juice：開」；黃色方塊回來；跳躍又會壓扁")
	print("[測試] ④ 按 T 變紅 → 按 0 關掉：立刻變回白色；再按 0 打開：維持白色（效果不會自己回來）")
	print("[測試] ⑤ 跳起來的瞬間馬上按 0：壓扁播到一半就停，角色立刻回到原本的樣子")
	print("[測試] ⑥ 按 M：連續切換 10 次不會壞，最後狀態跟按之前一樣")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_T:
			_player.set_juice_tint(_tint_probe, Color(1, 0.3, 0.3))
			print("[測試] Probe_Tint 把角色變紅")
		KEY_M:
			for i in 10:
				JuiceSwitch.set_on(not JuiceSwitch.is_on())
			print("[測試] 連續切換 10 次完成")
			_print_state()
		KEY_P:
			_print_state()

# 印出總開關、黃色方塊與角色圖目前的樣子
func _print_state() -> void:
	var sprite: Node2D = _player.visual.get_child(0)
	print("[測試] 總開關：%s　黃色方塊：%s　角色圖 縮放%s 顏色%s" % [
		"開" if JuiceSwitch.is_on() else "關",
		"看得到" if $Player/Juice/Probe_Marker.visible else "看不到",
		sprite.scale, sprite.modulate,
	])
