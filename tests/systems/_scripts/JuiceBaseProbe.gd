@tool
extends JuiceBase

# 測試用的 Juice 組件：每次播放就印出一行觸發時機、位置與強度

const _TIMING_NAMES := ["跳躍時", "落地時", "受傷時", "死亡時", "撞牆時", "開始移動時", "轉向時", "重生時",
	"打中東西時", "打倒敵人時", "撿到東西時", "過關時", "不自動觸發"]

# 印出這次是哪個時機觸發、在哪裡、強度多少
func _on_play() -> void:
	print("[測試] %s：「%s」觸發　位置 (%.0f, %.0f)　強度 %.2f" % [
		name, _TIMING_NAMES[timing], _trigger_position.x, _trigger_position.y, _trigger_power])

# 印出 _on_reset() 被呼叫（重生或 Juice 總開關關掉時）
func _on_reset() -> void:
	if timing == TIMING_MANUAL:
		print("[測試] %s：_on_reset() 被呼叫（重生或總開關關掉）" % name)
