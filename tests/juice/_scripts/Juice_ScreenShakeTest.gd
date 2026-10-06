extends Node2D

# 手動驗證用：螢幕震動。Juice_ScreenShake 用預設值（落地時、跟著落地力道），
# Juice_ScreenShake_Hurt 改成受傷時、幅度 10。每次有震動請求都會印出幅度。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明，監聽震動請求
func _ready() -> void:
	Events.shake_requested.connect(func(strength: float, duration: float):
		print("[測試] 震動請求：幅度 %.1f　%.2f 秒" % [strength, duration]))
	print("[測試] 方向鍵移動、空白跳、Q 翻轉重力、H 受傷、0 Juice 總開關")
	print("[測試] ① 跳一下落地：畫面輕輕晃一下（幅度約 3）")
	print("[測試] ② 跳上右邊的矮台階再走下來：晃得比跳躍落地小（幅度約 1）")
	print("[測試] ③ 按 Q 翻到天花板、再按 Q 掉回地板：晃得比跳躍落地大（幅度約 4～5）")
	print("[測試] ④ 按 H：大震動（幅度 10）；大震動還沒停時落地，震動不會突然變小")
	print("[測試] ⑤ 按 0 關掉 Juice：落地、受傷都不再震動，也不會印震動請求")

# 除錯按鍵：H 受傷
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H:
		print("[測試] 模擬受傷")
		_player.take_damage(1)
