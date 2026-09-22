extends Node2D

# 手動驗證用：Button 的三種踩踏模式（踩住才開／踩一下切換／踩一下永久開）+ turned_on/turned_off。
# 用方向鍵走到每個按鈕上方測試，按鈕顏色會從灰變綠。被攻擊觸發模式沒有近戰能力可以測，
# 改成 3 秒後直接呼叫 take_hit() 示範。

@onready var _button_hold: Area2D = $Button_HoldMode
@onready var _button_toggle: Area2D = $Button_ToggleMode
@onready var _button_permanent: Area2D = $Button_PermanentMode
@onready var _button_hit: Area2D = $Button_HitMode

func _ready() -> void:
	_button_hold.turned_on.connect(func(): print("[測試] 踩住才開：turned_on"))
	_button_hold.turned_off.connect(func(): print("[測試] 踩住才開：turned_off"))
	_button_toggle.turned_on.connect(func(): print("[測試] 踩一下切換：turned_on"))
	_button_toggle.turned_off.connect(func(): print("[測試] 踩一下切換：turned_off"))
	_button_permanent.turned_on.connect(func(): print("[測試] 踩一下永久開：turned_on（之後應該不會再有 turned_off）"))
	_button_hit.turned_on.connect(func(): print("[測試] 被攻擊觸發：turned_on"))
	_button_hit.turned_off.connect(func(): print("[測試] 被攻擊觸發：turned_off"))

	print("[測試] 由左到右四個按鈕：踩住才開／踩一下切換／踩一下永久開／被攻擊觸發")
	print("[測試] 用方向鍵／AD 走過去踩，觀察輸出面板訊息與按鈕顏色（灰→綠）")
	await get_tree().create_timer(3.0).timeout
	print("[測試] 對「被攻擊觸發」按鈕呼叫一次 take_hit()")
	_button_hit.take_hit(1, Vector2.ZERO, self)
