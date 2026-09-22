extends Node

# 全域數值系統：金幣、鑰匙、血量、分數，固定四種。機制卡與零件透過這裡讀寫數值，不要自己存狀態。

enum Kind { COIN, KEY_ITEM, HEALTH, SCORE }

signal value_changed(kind: Kind, old_value: int, new_value: int)

var _values: Dictionary = {
	Kind.COIN: 0,
	Kind.KEY_ITEM: 0,
	Kind.HEALTH: 3,
	Kind.SCORE: 0,
}
var _max_values: Dictionary = {
	Kind.COIN: 0,
	Kind.KEY_ITEM: 0,
	Kind.HEALTH: 3,
	Kind.SCORE: 0,
}

# 增加數值，amount 給負數就是減少；會被夾在 0 到上限之間（上限 0 代表不限）
func add(kind: Kind, amount: int) -> void:
	var old_value: int = _values.get(kind, 0)
	var new_value: int = old_value + amount
	var max_value: int = _max_values.get(kind, 0)
	if max_value > 0:
		new_value = min(new_value, max_value)
	new_value = max(new_value, 0)
	if new_value == old_value:
		return
	_values[kind] = new_value
	value_changed.emit(kind, old_value, new_value)
	Events.value_changed.emit(kind, old_value, new_value)

# 查詢目前數值
func get_value(kind: Kind) -> int:
	return _values.get(kind, 0)

# 檢查目前數值是不是至少有 n
func has_at_least(kind: Kind, n: int) -> bool:
	return get_value(kind) >= n

# 數值足夠就扣掉並回傳 true，不夠就什麼都不做並回傳 false
func consume(kind: Kind, n: int) -> bool:
	if not has_at_least(kind, n):
		return false
	add(kind, -n)
	return true
