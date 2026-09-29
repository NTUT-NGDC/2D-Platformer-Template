extends Node

# 手動驗證用：場景裡每張機制卡自己宣告的訊號，發出時都印一行到輸出面板。
# 放進卡片的測試場景就好，不用一個個連線；卡片訊號清單見 documents/01b_mechanic_cards.md §3。

# 等卡片都進場後，幫每張卡的每個自訂訊號接上 print
func _ready() -> void:
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("signal_source"):
		if not (node is MechanicBase):
			continue
		var names: Array[String] = []
		for info in node.get_script().get_script_signal_list():
			var signal_name: String = info["name"]
			names.append(signal_name)
			node.connect(signal_name, _on_card_signal.bind(node.name, signal_name))
		print("[訊號測試] %s 的訊號：%s" % [node.name, ", ".join(names)])

# 卡片發出訊號時印出卡片名稱與訊號名稱
func _on_card_signal(card_name: String, signal_name: String) -> void:
	print("[訊號測試] %s 發出 %s" % [card_name, signal_name])
