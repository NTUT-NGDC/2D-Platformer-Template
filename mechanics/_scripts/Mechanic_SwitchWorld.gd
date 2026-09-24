extends MechanicBase

# 開關世界：每隔 switch_seconds 秒，紅／藍方塊互換實心與虛空，統一呼叫場景中所有
# blocks/SwitchBlock.tscn 的 set_active()。blink_before_switch 開啟時，切換前方塊會
# 先閃爍提示。拖進 Player → Mechanics 底下就能用，不用連任何線。

## 紅藍方塊多久切換一次
@export_range(0.5, 5.0) var switch_seconds: float = 2.0

## 遊戲開始時哪個顏色是實體
@export_enum("紅色先", "藍色先") var start_color: int = 0

## 切換前方塊要不要先閃爍提示
@export var blink_before_switch: bool = true

const _START_RED := 0
const _RED_GROUP := "switch_red"
const _BLUE_GROUP := "switch_blue"
const _BLINK_LEAD_TIME := 0.4  # 切換前這麼多秒開始閃爍
const _BLINK_INTERVAL := 0.1

var _red_active: bool = true
var _elapsed: float = 0.0
var _blink_timer: float = 0.0
var _blink_dim: bool = false

# 套用一開始哪個顏色是實心；場上找不到任何 SwitchBlock 就印警告
func _on_setup() -> void:
	_red_active = (start_color == _START_RED)
	if not _has_any_switch_block():
		push_warning("[開關世界] 場景裡找不到任何 SwitchBlock，這張卡不會有效果")
		return
	_apply_state()

# 累積時間，快到切換點時視需要閃爍，時間到就讓紅藍互換
func apply(ctx: MoveContext) -> void:
	if not _has_any_switch_block():
		return

	_elapsed += ctx.delta
	var remaining: float = switch_seconds - _elapsed
	if blink_before_switch and remaining <= _BLINK_LEAD_TIME and remaining > 0.0:
		_update_blink(ctx.delta)

	if _elapsed < switch_seconds:
		return
	_elapsed = 0.0
	_red_active = not _red_active
	_apply_state()
	_reset_blink()
	Events.mechanic_event.emit("Mechanic_SwitchWorld", "switched")

# 重生時紅藍方塊回到一開始的狀態，切換倒數重新開始
func on_respawn() -> void:
	_red_active = (start_color == _START_RED)
	_elapsed = 0.0
	if not _has_any_switch_block():
		return
	_apply_state()
	_reset_blink()

# 依目前的 _red_active 呼叫每個 SwitchBlock 的 set_active()
func _apply_state() -> void:
	for block in get_tree().get_nodes_in_group(_RED_GROUP):
		if block.has_method("set_active"):
			block.set_active(_red_active)
	for block in get_tree().get_nodes_in_group(_BLUE_GROUP):
		if block.has_method("set_active"):
			block.set_active(not _red_active)

# 切換前閃爍：用 CanvasItem 內建的 modulate 讓所有方塊透明度忽明忽暗，不碰 SwitchBlock
# 自己的私有視覺節點
func _update_blink(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer < _BLINK_INTERVAL:
		return
	_blink_timer = 0.0
	_blink_dim = not _blink_dim
	var alpha: float = 0.4 if _blink_dim else 1.0
	for block in _all_switch_blocks():
		if block is CanvasItem:
			var item: CanvasItem = block
			item.modulate.a = alpha

# 切換完成後把透明度還原成正常
func _reset_blink() -> void:
	_blink_timer = 0.0
	_blink_dim = false
	for block in _all_switch_blocks():
		if block is CanvasItem:
			var item: CanvasItem = block
			item.modulate.a = 1.0

# 場景中所有 SwitchBlock（不分紅藍）
func _all_switch_blocks() -> Array:
	return get_tree().get_nodes_in_group(_RED_GROUP) + get_tree().get_nodes_in_group(_BLUE_GROUP)

# 場上有沒有任何 SwitchBlock
func _has_any_switch_block() -> bool:
	return not _all_switch_blocks().is_empty()
