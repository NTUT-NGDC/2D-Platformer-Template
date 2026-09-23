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
signal checkpoint_reached(checkpoint: Node)

# 數值事件（由 Stats 轉發，供 HUD、W3 果汁訂閱）
signal value_changed(kind, old_value: int, new_value: int)

# 受擊事件（由 Hittable 介面實作方轉發，供 W3 頓幀、震動訂閱）
signal hit(target: Node, source: Node)

# 機制卡事件（主限制卡在自己規格書上寫的關鍵瞬間 emit，供 W3 果汁組件訂閱，W1 不用管）
signal mechanic_event(card: String, event: String)

# 表現層請求（W3 Juice 用，讓組件不必知道攝影機在哪）
signal shake_requested(strength: float, duration: float)
signal hitstop_requested(duration: float)
