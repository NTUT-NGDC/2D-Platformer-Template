extends Node

# 玩家事件（由 Player 轉發，方便跨場景組件接收）
signal player_jumped
signal player_landed(impact_force: float)
signal player_hurt
signal player_died

# 世界事件
signal enemy_died(pos: Vector2)
signal item_collected(pos: Vector2)
signal level_cleared
signal level_restarted

# 數值事件（由 Stats 轉發，供 HUD、W3 果汁訂閱）
signal value_changed(kind, old_value: int, new_value: int)

# 表現層請求（W3 Juice 用，讓組件不必知道攝影機在哪）
signal shake_requested(strength: float, duration: float)
signal hitstop_requested(duration: float)
