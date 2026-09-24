extends Node2D

# 手動驗證用：兩個 Room 並排，Room1 用自動重生點、Room2 底下放了一個 Marker2D 當重生點。
# 鏡頭拉遠到兩個房間都看得到（U76 才會做鏡頭瞬切），走過邊界時輸出面板會印房間名稱。

# 接上 room_entered，印出操作說明
func _ready() -> void:
	Events.room_entered.connect(_on_room_entered)
	print("[測試] 往右走過兩個房間的交界，輸出面板應該印出「玩家進入 Room2」；走回來印「玩家進入 Room1」")
	print("[測試] 站在交界上來回小步移動，只有玩家中心跨過邊界時才會印，不會一直洗版")

# 每次進入房間印出該房間的中心與重生點
func _on_room_entered(room: Node) -> void:
	print("[測試] %s 中心：%s　重生點：%s" % [room.name, room.get_center(), room.get_spawn_point()])
