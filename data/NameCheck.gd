class_name NameCheck
extends RefCounted

# 共用名稱檢查工具：學員打字的名稱欄位（數值種類、群組名稱…）一律透過這裡整理與比對，
# 規則見 CLAUDE.md 鐵律 4。全部是靜態函式，編輯器裡（@tool）跟執行時都能直接呼叫。

# 兩個名稱的編輯距離在這個範圍內（且不完全一樣），視為可能是打錯字
const MAX_DISTANCE := 1

# 整理學員打的名稱：全形英數字與全形空白轉半形、去掉頭尾空白
static func clean(name: String) -> String:
	var result := ""
	for i in name.length():
		var code := name.unicode_at(i)
		if code == 0x3000:
			code = 0x20
		elif code >= 0xFF01 and code <= 0xFF5E:
			code -= 0xFEE0
		result += char(code)
	return result.strip_edges()

# 從候選名稱裡找出跟 name 最像但不完全一樣的一個，找不到就回傳空字串
static func find_similar(name: String, candidates: Array) -> String:
	var target := clean(name)
	var best := ""
	var best_distance := MAX_DISTANCE + 1
	for candidate in candidates:
		var text := str(candidate)
		var compare := clean(text)
		if compare == target:
			continue
		# 只差大小寫算距離 0，一定會被抓出來（群組名稱有分大小寫）
		var d := distance(target.to_lower(), compare.to_lower())
		if d < best_distance:
			best = text
			best_distance = d
	return best

# 把名稱清單排成「A」、「B」這種格式，放進中文警告訊息用；清單空的話回傳「（沒有）」
static func list_text(names: Array) -> String:
	if names.is_empty():
		return "（沒有）"
	var parts: Array[String] = []
	for n in names:
		parts.append("「%s」" % str(n))
	return "、".join(parts)

# 找出場景裡所有用到的數值種類名稱（ValueSettings、道具、門…有 get_value_kind() 的節點），不重複；
# exclude 的那個節點不算，拿來檢查「除了我自己，還有沒有別人用這個名字」
static func collect_value_kinds(root: Node, exclude: Node = null) -> Array:
	var kinds: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != exclude and node.has_method("get_value_kind"):
			var kind: String = node.get_value_kind()
			if kind != "" and kind not in kinds:
				kinds.append(kind)
		stack.append_array(node.get_children())
	return kinds

# 計算兩個字串的編輯距離（改幾個字才會變成另一個）
static func distance(a: String, b: String) -> int:
	var len_a := a.length()
	var len_b := b.length()
	var prev: Array = range(len_b + 1)
	var curr: Array = []
	curr.resize(len_b + 1)
	for i in range(1, len_a + 1):
		curr[0] = i
		for j in range(1, len_b + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			curr[j] = min(prev[j] + 1, min(curr[j - 1] + 1, prev[j - 1] + cost))
		prev = curr.duplicate()
	return prev[len_b]
