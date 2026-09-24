extends MechanicBase

# 血量流失：每秒自動扣血，撿到金幣補血。血量走 Stats 既有流程，這張卡不自帶血量
# 上限（上限由場景的 ValueSettings 設定），歸零時走既有的 kill() 流程。
# 拖進 Player → Mechanics 底下就能用，不用連任何線。

## 每秒自動扣多少血
@export_range(0.5, 10.0) var damage_per_second: float = 1.0

## 撿到一枚金幣補多少血
@export_range(0.5, 10.0) var heal_per_coin: float = 2.0

## 要不要在畫面上顯示血條
@export var show_health_bar: bool = true

# Stats 的數值只認整數，如果每個物理幀都呼叫一次 take_damage(damage_per_second * delta)，
# 每次的量都會被 roundi() 無條件捨去變成 0（例如 1.0/60 ≈ 0.017），永遠扣不到血。
# 改成累積滿一秒才扣一次整份傷害，跟 Lava.gd 的作法一致
const _TICK_INTERVAL := 1.0

# Pickup.gd 撿到道具時是直接呼叫 Stats.add("金幣", amount) 加值，沒有專門的「撿到」訊號，
# 所以改成訂閱 Stats.value_changed，看到金幣數值變多就當作撿到一枚
const _COIN_KIND := "金幣"

var _elapsed: float = 0.0

# 訂閱金幣數值變化；show_health_bar 關閉時把血量那一列從 HUD 藏起來
func _on_setup() -> void:
	Stats.value_changed.connect(_on_stats_value_changed)
	if not show_health_bar:
		Stats.configure(Stats.HEALTH_KIND, Stats.get_value(Stats.HEALTH_KIND),
			Stats.get_max_value(Stats.HEALTH_KIND), false, Stats.is_reset_on_death(Stats.HEALTH_KIND))

# 累積滿一秒扣一次血，歸零時 Stats 會自動觸發 kill()
func apply(ctx: MoveContext) -> void:
	_elapsed += ctx.delta
	if _elapsed < _TICK_INTERVAL:
		return
	_elapsed -= _TICK_INTERVAL
	player.take_damage(damage_per_second)

# 重生時扣血計時歸零
func on_respawn() -> void:
	_elapsed = 0.0

# 金幣數值變多（撿到金幣）就幫玩家補血
func _on_stats_value_changed(kind: String, old_value: int, new_value: int) -> void:
	if kind == _COIN_KIND and new_value > old_value:
		Stats.add(Stats.HEALTH_KIND, roundi(heal_per_coin))
