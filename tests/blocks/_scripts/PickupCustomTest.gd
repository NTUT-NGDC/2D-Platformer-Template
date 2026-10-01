extends Node2D

# 手動驗證用：Pickup 種類選「自訂」的打字欄位與四點防呆（空白、全形整理、打錯字提醒、全新名稱提示）。

func _ready() -> void:
	for child in get_children():
		if child.has_signal("collected"):
			var item_name: String = child.name
			child.collected.connect(func(): _print_status(item_name))
	print("[測試] 先看編輯器場景樹：Pickup_Typo、Pickup_Empty 有黃色驚嘆號，其他三個沒有")
	print("[測試] 開場輸出面板應該有：Pickup_NewKind 的「新的數值種類『寶石』」提示、Pickup_Typo 的「是不是想打『金幣』」警告、Pickup_Empty 的空白警告")
	print("[測試] 由左往右走過五個道具：")
	print("[測試]   Pickup_Star 星星 +1；Pickup_FullWidth（打的是全形空白＋星星＋半形空白）也算星星 +1，左上角星星=2")
	print("[測試]   Pickup_NewKind 寶石 +1，左上角多一行寶石；Pickup_Typo 會變成獨立的「金幤」+1；Pickup_Empty 不加任何數值，但會印出撿到")

# 每撿到一個道具就印出目前相關數值
func _print_status(item_name: String) -> void:
	print("[測試] %s 撿到了：星星=%d 寶石=%d 金幤=%d" % [
		item_name, Stats.get_value("星星"), Stats.get_value("寶石"), Stats.get_value("金幤"),
	])
