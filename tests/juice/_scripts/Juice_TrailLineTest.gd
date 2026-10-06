extends Node2D

# 手動驗證用：拖尾線（持續型）。
# Juice_TrailLine：預設值（速度夠快時、超過 450、保留 0.2 秒、白色）。
# Juice_TrailLine_Dash（一開始關著）：用訊號開關，衝刺卡的 dashed 連 start_trail、dash_ended 連 stop_trail；
#   底下有 Line2D 樣板：中間最粗的寬度曲線、紅黃綠藍漸層。
# 另外掛了衝刺（Shift，冷卻改成 0.3 秒方便連按）、重力翻轉（Q）。

@onready var _player: CharacterBody2D = $Player
@onready var _speed_trail: Node = $Player/Juice/Juice_TrailLine
@onready var _dash_trail: Node = $Player/Juice/Juice_TrailLine_Dash

# 印出操作說明
func _ready() -> void:
	print("[測試] 方向鍵移動、空白跳、Shift 衝刺、Q 翻轉重力、T 切換兩種拖尾線、Y 只開不關、K 死亡、0 Juice 總開關")
	print("[測試] 目前：速度夠快時（白色）")
	print("[測試] ① 走路、一般跳躍：沒有線")
	print("[測試] ② 按 Shift 衝刺：身後拖出白色光帶，頭粗尾細；衝刺結束後線的頭一直接在角色身上，從尾巴縮回來，不會跟角色分開")
	print("[測試] ③ 按 T 換成用訊號開關：衝刺時拖出紅黃綠藍的線，中間最粗；衝多久拖多久")
	print("[測試] ④ 按 T 換過去之後按 Y（只呼叫 start_trail，沒有 stop）：走路也會拖線，2 秒後自動停")
	print("[測試] ⑤ 衝刺中按 K：重生時不會有一條線從死掉的地方拉到重生點")
	print("[測試] ⑥ 編輯器裡點 Juice_TrailLine_Dash：看不到 min_speed、color；點底下的 Line2D：看得到示範線，改 Width Curve、Gradient 線會跟著變")

# 除錯按鍵：T 切換兩種拖尾線、Y 只開不關、K 死亡
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_T:
			_speed_trail.enabled = not _speed_trail.enabled
			_dash_trail.enabled = not _dash_trail.enabled
			print("[測試] 目前：%s" % ("速度夠快時（白色）" if _speed_trail.enabled else "用訊號開關（彩色樣板）"))
		KEY_Y:
			_dash_trail.start_trail()
			print("[測試] 呼叫 start_trail()，不呼叫 stop_trail()")
		KEY_K:
			print("[測試] 模擬死亡")
			_player.kill()
