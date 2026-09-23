extends Node2D

# 手動驗證用：MovingPlatform 的 activate/deactivate/toggle，以及站上去會不會被帶著走。

@onready var _button: Area2D = $Button_Elevator
@onready var _platform_auto: AnimatableBody2D = $Platform_Auto
@onready var _platform_elevator: AnimatableBody2D = $Platform_Elevator

func _ready() -> void:
	_button.turned_on.connect(_platform_elevator.activate)
	_button.turned_off.connect(_platform_elevator.deactivate)
	print("[測試] Platform_Auto（藍色）應該自己左右來回移動，站上去角色應該被帶著走")
	print("[測試] Platform_Elevator 一開始不會動，踩一下 Button_Elevator 切換開關，會開始上下移動")
	print("[測試] 再踩一次 Button_Elevator，Platform_Elevator 應該停在目前位置，不會跳回起點")
	await get_tree().create_timer(1.0).timeout
	var p1 := _platform_auto.global_position
	await get_tree().create_timer(1.0).timeout
	var p2 := _platform_auto.global_position
	print("[測試] Platform_Auto 1 秒內位置變化：%s → %s（應該不一樣，代表真的在動）" % [p1, p2])
