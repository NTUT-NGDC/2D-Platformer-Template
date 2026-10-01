extends Window

# 規則卡抽卡場景：先在上面選自己的主限制卡（可以不選），按按鈕從 8 張規則卡隨機抽一張。
# 選了主限制卡的話，跟它衝突的規則卡（01b_mechanic_cards.md 第 4 節會印警告的組合）不會被抽到。
# 純 UI，不存檔、不連線。卡片資料在 res://data/rule_cards.tres（衝突寫在每張卡的 conflicts_with），
# 主限制卡清單讀 res://data/mechanic_cards.tres，文字要改直接開那兩個檔案改，不用碰這支程式。

const RULE_LIST_PATH := "res://data/rule_cards.tres"
const MAIN_LIST_PATH := "res://data/mechanic_cards.tres"

@onready var _main_option: OptionButton = %MainCardOption
@onready var _excluded_label: Label = %ExcludedNote
@onready var _title_label: Label = %CardTitle
@onready var _rule_label: Label = %CardRule
@onready var _difficulty_label: Label = %CardDifficulty
@onready var _drag_hint_label: Label = %CardDragHint
@onready var _draw_button: Button = %DrawButton

var _rule_cards: Array = []
var _main_cards: Array = []
var _shown_card: Resource = null

# 讀卡片資料、填主限制卡下拉選單、接上按鈕
func _ready() -> void:
	_use_native_resolution()
	_rule_cards = (load(RULE_LIST_PATH) as Resource).cards
	_main_cards = (load(MAIN_LIST_PATH) as Resource).cards
	_main_option.add_item("不指定（還沒有主限制卡）")
	for card in _main_cards:
		_main_option.add_item(card.card_name)
	_main_option.item_selected.connect(_on_main_selected)
	_draw_button.pressed.connect(_on_draw_pressed)
	_update_excluded_note()
	_show_placeholder()

# 這個場景要用自己的 960x540，不要被 project.godot 的 480x270 縮放設定蓋過去
func _use_native_resolution() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.size = Vector2i(960, 540)

# 換了主限制卡：更新排除說明；目前顯示的規則卡跟新選的衝突的話清掉，請學員重抽
func _on_main_selected(_index: int) -> void:
	_update_excluded_note()
	if _shown_card != null and _shown_card not in _get_candidates():
		_show_placeholder()
		_title_label.text = "這張跟你的主限制卡衝突，請重抽"

# 按鈕按下：從不衝突的規則卡裡隨機抽一張顯示，並把按鈕文字換成「重抽」
func _on_draw_pressed() -> void:
	var candidates := _get_candidates()
	_shown_card = candidates[randi() % candidates.size()]
	_show_card(_shown_card)
	_draw_button.text = "重抽一張"

# 目前選的主限制卡的檔名，選「不指定」時是空字串
func _get_main_file() -> String:
	var index := _main_option.selected - 1
	if index < 0:
		return ""
	return _main_cards[index].file_name

# 跟目前選的主限制卡不衝突的規則卡
func _get_candidates() -> Array:
	var main_file := _get_main_file()
	var result: Array = []
	for card in _rule_cards:
		if main_file not in card.conflicts_with:
			result.append(card)
	return result

# 選了主限制卡、而且有規則卡被排除時，列出被排除的卡名
func _update_excluded_note() -> void:
	var main_file := _get_main_file()
	var excluded: Array[String] = []
	for card in _rule_cards:
		if main_file != "" and main_file in card.conflicts_with:
			excluded.append("「%s」" % card.card_name)
	if excluded.is_empty():
		_excluded_label.text = ""
	else:
		_excluded_label.text = "跟你的主限制卡衝突、不會抽到：%s" % "、".join(excluded)

# 把抽到的卡內容填進畫面上的四個欄位
func _show_card(card: Resource) -> void:
	_title_label.text = card.card_name
	_rule_label.text = card.rule_text
	_difficulty_label.text = "難度：技術 %s／設計 %s" % [
		_stars(card.difficulty_technical),
		_stars(card.difficulty_design),
	]
	_drag_hint_label.text = "把 mechanics/%s.tscn 拖到 Player 底下的 Mechanics" % card.file_name

# 數字換成星星文字，1～2 顆；用 ★ 不用 emoji，網頁版沒有 emoji 字型會變方框
func _stars(n: int) -> String:
	return "★".repeat(n)

# 還沒抽過卡之前的畫面
func _show_placeholder() -> void:
	_shown_card = null
	_title_label.text = "先選你的主限制卡，再抽一張規則卡"
	_rule_label.text = ""
	_difficulty_label.text = ""
	_drag_hint_label.text = ""
