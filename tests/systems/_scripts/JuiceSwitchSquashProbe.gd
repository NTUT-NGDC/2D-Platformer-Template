@tool
extends JuiceBase

# 測試用的一次型 Juice：觸發時角色壓扁，0.4 秒內彈回原狀

var _tween: Tween = null

# 壓扁再慢慢彈回來
func _on_play() -> void:
	print("[測試] %s：播放擠壓" % name)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(v: Vector2): player.set_juice_squash(self, v), Vector2(1.5, 0.5), Vector2.ONE, 0.4)

# 停掉播到一半的擠壓
func _on_reset() -> void:
	if _tween:
		_tween.kill()
		_tween = null
