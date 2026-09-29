extends Node2D

# 手動驗證用：兩個 Room 並排，Room1 用自動重生點、Room2 底下放了一個 Marker2D 當重生點。
# 鏡頭掛 CameraRig，走過邊界時應該瞬間切到另一個房間，輸出面板會印房間名稱。按 Z 測試震動。

# 接上 room_entered，印出操作說明
func _ready() -> void:
	Events.room_entered.connect(_on_room_entered)
	print("[測試] 往右走過兩個房間的交界：鏡頭瞬間切到 Room2（沒有滑過去），輸出面板印出「玩家進入 Room2」")
	print("[測試] 站在交界上來回小步移動，只有玩家中心跨過邊界時才會切，不會一直閃")
	print("[測試] 按 Z 震動鏡頭：震完應該回到房間正中央，不會偏掉")

# 每次進入房間印出該房間的中心與重生點
func _on_room_entered(room: Node) -> void:
	print("[測試] %s 中心：%s　重生點：%s" % [room.name, room.get_center(), room.get_spawn_point()])

# 除錯按鍵：Z 震動
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Z:
		Events.shake_requested.emit(6.0, 0.4)
