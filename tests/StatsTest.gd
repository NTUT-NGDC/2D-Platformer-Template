extends Node

# 手動驗證用：Stats 自動載入的 add / get_value / has_at_least / consume 與 value_changed 訊號

func _ready() -> void:
	Stats.value_changed.connect(_on_value_changed)

	print("[測試] 血量預設值：%d（應該是 3）" % Stats.get_value(Stats.Kind.HEALTH))

	Stats.add(Stats.Kind.COIN, 5)
	print("[測試] 金幣加 5 後：%d（應該是 5）" % Stats.get_value(Stats.Kind.COIN))

	print("[測試] has_at_least(金幣, 3)：%s（應該是 true）" % Stats.has_at_least(Stats.Kind.COIN, 3))

	var consumed_ok := Stats.consume(Stats.Kind.COIN, 3)
	print("[測試] consume(金幣, 3)：%s（應該是 true），剩下 %d（應該是 2）" % [consumed_ok, Stats.get_value(Stats.Kind.COIN)])

	var consumed_fail := Stats.consume(Stats.Kind.COIN, 100)
	print("[測試] consume(金幣, 100)：%s（應該是 false，因為不夠），剩下 %d（應該還是 2）" % [consumed_fail, Stats.get_value(Stats.Kind.COIN)])

	Stats.add(Stats.Kind.HEALTH, -10)
	print("[測試] 血量扣 10 後：%d（應該被夾在 0，不會變負數）" % Stats.get_value(Stats.Kind.HEALTH))

# 每次數值變動都會叫到這裡，用來證明訊號有正確 emit
func _on_value_changed(kind: Stats.Kind, old_value: int, new_value: int) -> void:
	print("[測試] value_changed 訊號：種類 %d，%d → %d" % [kind, old_value, new_value])
