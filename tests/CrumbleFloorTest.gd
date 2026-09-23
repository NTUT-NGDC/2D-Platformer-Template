extends Node2D

# 手動驗證用：CrumbleFloor 踩上去抖動→碎裂→依 respawn_time 重生或不重生。

@onready var _floor_a: Node2D = $CrumbleFloor_A
@onready var _floor_b: Node2D = $CrumbleFloor_B

func _ready() -> void:
	_floor_a.crumbled.connect(func(): print("[測試] CrumbleFloor_A：crumbled 已發出，3 秒後應該重生"))
	_floor_b.crumbled.connect(func(): print("[測試] CrumbleFloor_B：crumbled 已發出，respawn_time=0 不會重生"))
	print("[測試] CrumbleFloor_A（左邊，break_delay=0.6）：走上去應該先抖動再碎裂消失，3 秒後重生")
	print("[測試] CrumbleFloor_B（右邊，break_delay=1.5，triggered_by=任何物體）：走上去先抖動再碎裂消失，不會重生")
