extends Node

# 手動驗證用：NameCheck 的名稱整理、近似名稱比對、名稱清單格式

func _ready() -> void:
	print("[測試] clean(\"  金幣  \")：「%s」（應該是「金幣」）" % NameCheck.clean("  金幣  "))
	print("[測試] clean(\"ｋｅｙ１\")：「%s」（全形轉半形，應該是「key1」）" % NameCheck.clean("ｋｅｙ１"))
	print("[測試] clean(\"　鑰匙　\")：「%s」（全形空白也去掉，應該是「鑰匙」）" % NameCheck.clean("　鑰匙　"))

	var groups := ["鑰匙", "敵人", "Key"]
	print("[測試] find_similar(鑰是)：「%s」（應該是「鑰匙」）" % NameCheck.find_similar("鑰是", groups))
	print("[測試] find_similar(key)：「%s」（大小寫不同也算像，應該是「Key」）" % NameCheck.find_similar("key", groups))
	print("[測試] find_similar(鑰匙)：「%s」（完全一樣不算打錯，應該是空的）" % NameCheck.find_similar("鑰匙", groups))
	print("[測試] find_similar(金幣)：「%s」（差太多，應該是空的）" % NameCheck.find_similar("金幣", groups))

	print("[測試] list_text：%s（應該是「鑰匙」、「敵人」、「Key」）" % NameCheck.list_text(groups))
	print("[測試] list_text 空清單：%s（應該是（沒有））" % NameCheck.list_text([]))

	print("[測試] 接下來故意打錯字「金幤」，應該在偵錯器的錯誤分頁看到跟「金幣」很像的警告")
	Stats.add("金幣", 1)
	Stats.add("金幤", 1)
