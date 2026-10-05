extends Node2D

# 手動驗證用：脫殼卡內建的三種殼（卡片底下沒有放殼）。觸發時機是「按下按鍵」（C）。
# 場景裡另外直接擺了幾顆殼：兩顆塑膠殼（上面各掉下一個箱子、一顆蟬殼）、一顆浮在空中的蜘蛛殼。

# 接上場景裡（以及之後脫出來的）彈彈特性的 bounced 訊號，印出測試步驟
func _ready() -> void:
	for node in find_children("*", "", true, false):
		_watch_trait(node)
	get_tree().node_added.connect(_watch_trait)
	print("[測試] 一開場：Plastic_A 上面的箱子、Plastic_B 上面的蟬殼掉下來，碰到塑膠殼就被彈起來，一直彈")
	print("[測試] 按 C 脫殼、Q／E 切換：頭上小方塊依序是琥珀（蟬殼）→ 藍（塑膠殼）→ 灰（蜘蛛殼）")
	print("[測試] 蟬殼：會掉、推得動、可以站上去，跟一般的殼一樣")
	print("[測試] 塑膠殼：會掉、推得動；跳到它上面會被彈得比一般跳躍高（印「把東西彈起來了」）；從殼裡鑽出來不會被彈")
	print("[測試] 蜘蛛殼：在空中脫（跳起來按 C）會停在空中不會掉；推不動，可以站上去（Spider_InAir 也一樣）")

# 是彈彈特性的話，彈起東西時印出是哪一顆殼
func _watch_trait(node: Node) -> void:
	if node is ShellTrait and node.has_signal("bounced"):
		node.bounced.connect(func(): print("[測試] %s 把東西彈起來了" % node.get_parent().name))
