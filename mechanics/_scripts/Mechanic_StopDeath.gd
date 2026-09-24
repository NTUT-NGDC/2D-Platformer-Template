extends MechanicBase

# 停下即死：靜止不動超過 max_idle_seconds 就依 penalty_mode 直接死亡或開始持續扣血，
# 移動就重新計時。跟蓄力青蛙跳一起掛時，蓄力中會暫停計時（蓄力本來就要站著不動）。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 最多可以靜止不動幾秒
@export_range(0.5, 5.0) var max_idle_seconds: float = 1.5

## 超過時間之後的懲罰方式
@export_enum("直接死亡", "持續扣血") var penalty_mode: int = 0

## 快要超過時間時角色要不要閃紅警告
@export var show_warning: bool = true

const _PENALTY_KILL := 0
const _MOVE_EPSILON := 5.0
const _WARNING_RATIO := 0.7  # 逾時前這個比例的時間開始閃紅
const _FLASH_INTERVAL := 0.15
# 持續扣血模式逾時後每秒扣血量，規格沒給精確數字，抓一個會痛但不會秒死的量
const _DRAIN_DAMAGE_PER_SECOND := 2.0
const _CHARGE_JUMP_SCRIPT := "res://mechanics/_scripts/Mechanic_ChargeJump.gd"

var _idle_seconds: float = 0.0
var _flash_timer: float = 0.0
var _charge_jump: Node = null

# 找場上有沒有蓄力青蛙跳，之後拿它的 is_charging 決定要不要暫停計時
func _on_setup() -> void:
	_charge_jump = _find_sibling(_CHARGE_JUMP_SCRIPT)

# 依移動狀態算靜止時間，逾時套用懲罰，接近逾時視需要閃紅警告
func apply(ctx: MoveContext) -> void:
	if _charge_jump != null and _charge_jump.is_charging:
		_update_flash(false, ctx.delta)
		return

	var moving: bool = player.velocity.length() > _MOVE_EPSILON
	if moving:
		_idle_seconds = 0.0
	else:
		_idle_seconds += ctx.delta

	if show_warning:
		_update_flash(_idle_seconds >= max_idle_seconds * _WARNING_RATIO, ctx.delta)

	if _idle_seconds < max_idle_seconds:
		return

	if penalty_mode == _PENALTY_KILL:
		player.kill()
		Events.mechanic_event.emit("Mechanic_StopDeath", "died")
	else:
		player.take_damage(_DRAIN_DAMAGE_PER_SECOND * ctx.delta)
		Events.mechanic_event.emit("Mechanic_StopDeath", "draining")

# 重生時靜止計時歸零、顏色還原
func on_respawn() -> void:
	_idle_seconds = 0.0
	_update_flash(false, 0.0)

# 閃紅警告：關閉就把顏色還原、計時器歸零；開啟就每 _FLASH_INTERVAL 秒切換白／紅
func _update_flash(active: bool, delta: float) -> void:
	if not active:
		_flash_timer = 0.0
		if player.visual:
			player.visual.modulate = Color.WHITE
		return
	_flash_timer += delta
	if _flash_timer >= _FLASH_INTERVAL:
		_flash_timer = 0.0
		if player.visual:
			player.visual.modulate = Color.WHITE if player.visual.modulate == Color.RED else Color.RED

# 檢查 Mechanics 容器裡有沒有掛著某個腳本路徑對應的卡，回傳那個節點
func _find_sibling(script_path: String) -> Node:
	if not player.has_node("Mechanics"):
		return null
	for child in player.get_node("Mechanics").get_children():
		var script: Script = child.get_script()
		if script != null and script.resource_path == script_path:
			return child
	return null
