@tool
extends Area2D

# 道具：感應，玩家碰到時依 kind 幫對應的數值種類加值。血包直接加血量，Stats 本身就會
# 把數值夾在上限以內，不會超過。拖進場景就能用，不用連任何線。

## 種類：金幣、鑰匙、血包、分數
@export_enum("金幣", "鑰匙", "血包", "分數") var kind: int = 0

## 撿到時增加的數量
@export_range(1, 99) var amount: int = 1

## 撿到時發出，給學員自己接特效／音效用
signal collected

const _KIND_HEALTH := 2

var _collected: bool = false
var _value_returned: bool = false
var _stats_kind: String = ""

# 依 kind 算出對應的 Stats 種類名稱，設定碰撞層／遮罩，只偵測玩家
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("signal_source")
	_stats_kind = _resolve_stats_kind()
	collision_layer = 1 << 4  # 圖層 5「感應」
	collision_mask = 1 << 0   # 圖層 1「玩家」
	body_entered.connect(_on_body_entered)

# 把 Inspector 的種類選項換成 Stats 認得的字串，血包對應到內建的血量種類
func _resolve_stats_kind() -> String:
	if kind == _KIND_HEALTH:
		return Stats.HEALTH_KIND
	var labels := ["金幣", "鑰匙", "", "分數"]
	return labels[kind]

# 玩家碰到時加值、發出訊號，然後把自己藏起來（不刪除，重生時才能放回來）
func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	Stats.add(_stats_kind, amount)
	collected.emit()
	Events.item_collected.emit(global_position)
	visible = false

# 把自己恢復到關卡開始時的狀態：被撿走的放回來（數值由 rewind_values() 退，重生處理者呼叫）。
# 數值設成「死亡不退回」的道具不放回來，不然同一個可以一直重複撿
func reset() -> void:
	if not _rewinds_on_death():
		return
	_collected = false
	_value_returned = false
	visible = true

# 被撿走過的話，把當初加的數值扣回來；同一次撿只扣一次（重生處理者呼叫，在 reset() 之前）
func rewind_values() -> void:
	if not _collected or _value_returned or not _rewinds_on_death():
		return
	_value_returned = true
	if _stats_kind != Stats.HEALTH_KIND:
		Stats.add(_stats_kind, -amount)

# 這個道具的數值死掉時要不要退：血包不退（重生本來就補滿血）、設成「死亡不退回」的種類也不退
func _rewinds_on_death() -> bool:
	return _stats_kind == Stats.HEALTH_KIND or Stats.is_reset_on_death(_stats_kind)

# 編輯畫面持續請求重畫，讓虛線跟著訊號連接的變化即時更新
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# 編輯畫面用：幫這個零件自己發出的每個訊號的每條連接畫一條虛線到目標節點
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	SignalLines.draw(self, collected)
