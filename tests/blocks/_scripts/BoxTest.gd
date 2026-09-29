extends Node2D

# 手動驗證用：Box 可以被推動，weight 影響推動難易，take_hit 只擊退不受傷。

@onready var _box_light: RigidBody2D = $Box_Light
@onready var _box_heavy: RigidBody2D = $Box_Heavy

func _ready() -> void:
	print("[測試] 左邊 Box_Light（輕）、右邊 Box_Heavy（重）：走過去用身體撞撞看，比較推動難易")
	print("[測試] 5 秒後會對兩個箱子呼叫同樣力道的 take_hit()，重的箱子應該飛比較短的距離")
	await get_tree().create_timer(5.0).timeout
	var light_before := _box_light.global_position
	var heavy_before := _box_heavy.global_position
	_box_light.take_hit(1, Vector2(300, -150), self)
	_box_heavy.take_hit(1, Vector2(300, -150), self)
	await get_tree().create_timer(0.5).timeout
	print("[測試] Box_Light 位移：%.1f px" % light_before.distance_to(_box_light.global_position))
	print("[測試] Box_Heavy 位移：%.1f px" % heavy_before.distance_to(_box_heavy.global_position))
