extends MechanicBase

# 忽大忽小：在小、大兩種體型之間切換，一開始是小的。變大時如果會卡進地形，
# 會先延後，等空間夠了才真的套用，不會把玩家卡進牆裡。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 什麼時候切換大小
@export_enum("按下按鍵", "隨時間") var trigger_timing: int = 0

## 按下按鍵時用鍵盤按鍵還是滑鼠按鍵（只有「觸發時機」選按下按鍵時才會顯示這一欄）
@export_enum("鍵盤按鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type: int = 0

## 按下按鍵時要按哪一鍵切換（「觸發時機」選按下按鍵、「按鍵種類」選鍵盤按鍵時才會顯示這一欄）
@export var key: Key = KEY_SHIFT

## 變小時的體型倍率
@export_range(0.3, 1.0) var small_scale: float = 0.5

## 變大時的體型倍率
@export_range(1.0, 2.5) var big_scale: float = 1.8

## 體型是否連動推力、擊退、跳躍力
@export var size_affects_stats: bool = true

const _TRIGGER_KEY := 0
const _AUTO_INTERVAL := 3.0

const _DANGEROUS_KEYS := [
	KEY_CTRL, KEY_TAB, KEY_ESCAPE,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
]

var _is_big: bool = false
var _pending_factor: float = 0.0
var _auto_time_left: float = _AUTO_INTERVAL

# 依 trigger_timing 決定要不要顯示按鍵欄位；選滑鼠按鍵時也隱藏 key 欄位
func _validate_property(property: Dictionary) -> void:
	if property.name == "input_type" and trigger_timing != _TRIGGER_KEY:
		property.usage = PROPERTY_USAGE_NONE
	elif property.name == "key" and (trigger_timing != _TRIGGER_KEY or input_type != 0):
		property.usage = PROPERTY_USAGE_NONE

# 套用一開始的體型（小），依觸發時機接對應的按鍵
func _on_setup() -> void:
	player.set_size_factor(small_scale)
	if trigger_timing == _TRIGGER_KEY:
		if input_type == 0:
			_warn_if_dangerous_key(key)
		InputRouter.bind_input(self, input_type, key, InputRouter.PRESSED, _toggle)

# 隨時間模式的倒數；有待處理的變大請求時，每幀重新檢查空間夠不夠
func apply(ctx: MoveContext) -> void:
	if trigger_timing != _TRIGGER_KEY:
		_auto_time_left -= ctx.delta
		if _auto_time_left <= 0.0:
			_auto_time_left = _AUTO_INTERVAL
			_toggle()

	if _pending_factor != 0.0 and _try_apply_size(_pending_factor):
		_pending_factor = 0.0

	if size_affects_stats:
		_apply_stat_scales(ctx)

# 在小、大兩種體型之間切換；新的請求會蓋掉還沒套用的舊請求
func _toggle() -> void:
	var target := small_scale if _is_big else big_scale
	_is_big = not _is_big
	_pending_factor = 0.0
	if target > player.size_factor:
		_pending_factor = target
	else:
		_try_apply_size(target)

# 嘗試套用體型：變大時若會跟地形重疊就先不套用，等空間足夠再套；回傳有沒有真的套用
func _try_apply_size(target: float) -> bool:
	if target > player.size_factor and _would_overlap_terrain(target):
		return false
	player.set_size_factor(target)
	Events.mechanic_event.emit("Mechanic_SizeShift", "grew" if target > 1.0 else "shrank")
	return true

# 用縮放後的碰撞形狀在目前位置查一次，看看會不會卡進地形
func _would_overlap_terrain(target_factor: float) -> bool:
	var col := player.get_node("CollisionShape2D") as CollisionShape2D
	if col == null or not (col.shape is RectangleShape2D):
		return false
	var current_size: Vector2 = (col.shape as RectangleShape2D).size
	var ratio: float = target_factor / player.size_factor
	var shape := RectangleShape2D.new()
	shape.size = current_size * ratio
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, player.global_position)
	query.collision_mask = 1 << 1  # 圖層 2「地形」
	var space_state: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	return not space_state.intersect_shape(query, 1).is_empty()

# 依目前體型調整推力、擊退、跳躍力倍率：大隻推得動箱子、比較不容易被擊退、跳得比較低；
# 小隻跳得比較高、比較容易被敵人撞飛
func _apply_stat_scales(ctx: MoveContext) -> void:
	var f: float = player.size_factor
	if f > 1.0 and big_scale > 1.0:
		var t := (f - 1.0) / (big_scale - 1.0)
		ctx.push_scale = lerpf(1.0, 1.6, t)
		ctx.knockback_scale = lerpf(1.0, 0.6, t)
		ctx.jump_scale = lerpf(1.0, 0.7, t)
	elif f < 1.0 and small_scale < 1.0:
		var t := (1.0 - f) / (1.0 - small_scale)
		ctx.jump_scale = lerpf(1.0, 1.3, t)
		ctx.knockback_scale = lerpf(1.0, 1.6, t)

# 選到會被瀏覽器攔截的按鍵時提醒（Ctrl、Tab、Esc、F 鍵在網頁版會觸發瀏覽器內建功能）
func _warn_if_dangerous_key(k: Key) -> void:
	if k not in _DANGEROUS_KEYS:
		return
	var message := "[忽大忽小] 選到的按鍵「%s」在網頁版可能會觸發瀏覽器內建功能，建議換一個" % OS.get_keycode_string(k)
	push_warning(message)
	printerr("⚠ %s" % message)
