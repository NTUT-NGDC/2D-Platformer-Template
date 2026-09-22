extends Node

# 全域數值系統：數值種類由學員自己決定名稱（字串），第一次用到某個名稱時自動出現，不用先宣告。
# 機制卡與零件透過這裡讀寫數值，不要自己存狀態。

## 血量是唯一有特殊意義的種類名稱：歸零時 Player 會死亡（見 player/Player.gd 的 take_damage）
const HEALTH_KIND := "血量"

# 兩個種類名稱的編輯距離在這個範圍內，視為可能是打錯字
const _TYPO_MAX_DISTANCE := 1

signal value_changed(kind: String, old_value: int, new_value: int)

var _values: Dictionary = {}       # kind(String) -> int
var _max_values: Dictionary = {}   # kind(String) -> int，0 代表不限
var _known_kinds: Array[String] = []

# 血量是系統內建的預設種類，其他種類都是第一次用到才出現，初始 0、不限
func _ready() -> void:
	_values[HEALTH_KIND] = 3
	_max_values[HEALTH_KIND] = 3
	_known_kinds.append(HEALTH_KIND)

# 增加數值，amount 給負數就是減少；會被夾在 0 到上限之間（上限 0 代表不限）
func add(kind: String, amount: int) -> void:
	_check_typo(kind)
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
func get_value(kind: String) -> int:
	_check_typo(kind)
	return _values.get(kind, 0)

# 檢查目前數值是不是至少有 n
func has_at_least(kind: String, n: int) -> bool:
	return get_value(kind) >= n

# 數值足夠就扣掉並回傳 true，不夠就什麼都不做並回傳 false
func consume(kind: String, n: int) -> bool:
	if not has_at_least(kind, n):
		return false
	add(kind, -n)
	return true

# 第一次看到這個名稱時，跟已經用過的名稱比對，太像但不一樣就印警告，抓可能的打錯字
func _check_typo(kind: String) -> void:
	if kind in _known_kinds:
		return
	for existing in _known_kinds:
		if _levenshtein(kind, existing) <= _TYPO_MAX_DISTANCE:
			push_warning("[Stats] 數值種類「%s」跟已經用過的「%s」很像，是不是打錯字了？" % [kind, existing])
			break
	_known_kinds.append(kind)

# 計算兩個字串的編輯距離（改幾個字才會變成另一個），用來抓相近但打錯的名稱
func _levenshtein(a: String, b: String) -> int:
	var len_a := a.length()
	var len_b := b.length()
	var prev: Array = range(len_b + 1)
	var curr: Array = []
	curr.resize(len_b + 1)
	for i in range(1, len_a + 1):
		curr[0] = i
		for j in range(1, len_b + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			curr[j] = min(prev[j] + 1, min(curr[j - 1] + 1, prev[j - 1] + cost))
		prev = curr.duplicate()
	return prev[len_b]
