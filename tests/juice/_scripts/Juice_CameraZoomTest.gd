extends Node2D

# 手動驗證用：鏡頭推近。Juice_CameraZoom 用預設值（打倒敵人時、放大 0.25、0.4 秒），
# Juice_CameraZoom_Manual 是「不自動觸發」、放大 0.6、0.8 秒，按 Z 呼叫它的 play()。
# 鏡頭是預設的瞬切模式；按 1／2／3 可以切換鏡頭模式比較。

@onready var _camera: Camera2D = $Camera2D
@onready var _manual: Node = $Player/Juice/Juice_CameraZoom_Manual

const _MODE_NAMES := ["瞬切", "房間內跟隨", "自由跟隨"]

# 印出操作說明，監聽推近請求
func _ready() -> void:
	Events.zoom_requested.connect(func(strength: float, duration: float):
		print("[測試] 推近請求：放大 %.2f　%.2f 秒" % [strength, duration]))
	print("[測試] 方向鍵移動、空白跳、F 攻擊、Z 大推近、1／2／3 切鏡頭模式、0 Juice 總開關")
	print("[測試] ① F 打倒敵人：鏡頭快速放大一點再慢慢回來，畫面往玩家那邊偏")
	print("[測試] ② 站在房間左右兩端按 Z：放大明顯；瞬切、房間內跟隨模式都不會看到房間外（黑色區域）")
	print("[測試] ③ 按 Z 後馬上按 0：推近立刻停、回到原本大小")

# 除錯按鍵：Z 大推近、1／2／3 切鏡頭模式
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_Z:
			_manual.play()
		KEY_1, KEY_2, KEY_3:
			_camera.mode = event.physical_keycode - KEY_1
			_camera.position_smoothing_enabled = _camera.mode != 0
			print("[測試] 鏡頭模式：%s" % _MODE_NAMES[_camera.mode])
