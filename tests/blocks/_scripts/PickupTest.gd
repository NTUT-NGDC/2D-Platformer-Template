extends Node2D

# 手動驗證用：Pickup 四種 kind 各自正確加值，血包不會超過血量上限。

func _ready() -> void:
	Stats.add(Stats.HEALTH_KIND, -2)
	print("[測試] 先扣血到 %d/%d，方便等一下驗證血包不會超過上限" % [Stats.get_value(Stats.HEALTH_KIND), Stats.get_max_value(Stats.HEALTH_KIND)])
	for child in get_children():
		if child.has_signal("collected"):
			var item_name: String = child.name
			child.collected.connect(func(): _print_status(item_name))
	print("[測試] 依序走過四個道具：金幣、鑰匙、血包（amount=5，血量上限只有 3）、分數")

# 每撿到一個道具就印出目前所有相關數值，方便逐一核對
func _print_status(item_name: String) -> void:
	print("[測試] %s 撿到了：金幣=%d 鑰匙=%d 血量=%d/%d 分數=%d" % [
		item_name,
		Stats.get_value("金幣"),
		Stats.get_value("鑰匙"),
		Stats.get_value(Stats.HEALTH_KIND), Stats.get_max_value(Stats.HEALTH_KIND),
		Stats.get_value("分數"),
	])
