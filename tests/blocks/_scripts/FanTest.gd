extends Node2D

# 手動驗證用：Fan 的 direction/force/range_tiles 效果，以及 activate/deactivate/toggle。

@onready var _button: Area2D = $Button_Toggle
@onready var _fan_toggle: Area2D = $Fan_Toggle

func _ready() -> void:
	_button.turned_on.connect(_fan_toggle.activate)
	_button.turned_off.connect(_fan_toggle.deactivate)
	print("[測試] Fan_Up（左側）一直開著，站上去應該被持續往上吹")
	print("[測試] Fan_Side（中間）一直開著，走進範圍應該被持續往右吹")
	print("[測試] Fan_Toggle（右側）一開始關著，踩一下旁邊的 Button_Toggle 會開始往上吹，再踩一次會停")
