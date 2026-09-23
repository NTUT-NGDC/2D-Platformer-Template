extends Window

# W1 課堂抽卡場景：按按鈕從 10 張主限制卡隨機抽一張。純 UI，不存檔、不防重複、不連線。
# 卡片資料在 res://data/mechanic_cards.tres，文字要改直接開那個檔案改，不用碰這支程式。

const CARD_LIST_PATH := "res://data/mechanic_cards.tres"

@onready var _title_label: Label = %CardTitle
@onready var _rule_label: Label = %CardRule
@onready var _difficulty_label: Label = %CardDifficulty
@onready var _drag_hint_label: Label = %CardDragHint
@onready var _draw_button: Button = %DrawButton

var _cards: Array = []

func _ready() -> void:
	_use_native_resolution()
	var list: Resource = load(CARD_LIST_PATH)
	_cards = list.cards
	_draw_button.pressed.connect(_on_draw_pressed)
	_show_placeholder()

# 這個場景要用自己的 960x540，不要被 project.godot 的 480x270 縮放設定蓋過去
func _use_native_resolution() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.size = Vector2i(960, 540)

# 按鈕按下：從卡池隨機抽一張顯示，並把按鈕文字換成「重抽」
func _on_draw_pressed() -> void:
	var card: Resource = _cards[randi() % _cards.size()]
	_show_card(card)
	_draw_button.text = "重抽一張"

# 把抽到的卡內容填進畫面上的四個欄位
func _show_card(card: Resource) -> void:
	_title_label.text = card.card_name
	_rule_label.text = card.rule_text
	_difficulty_label.text = "難度：技術 %s／設計 %s" % [
		_stars(card.difficulty_technical),
		_stars(card.difficulty_design),
	]
	_drag_hint_label.text = "把 mechanics/%s.tscn 拖到 Player 底下的 Mechanics" % card.file_name

# 數字換成星星文字，1～2 顆
func _stars(n: int) -> String:
	return "⭐".repeat(n)

# 還沒抽過卡之前的畫面
func _show_placeholder() -> void:
	_title_label.text = "按下面的按鈕抽一張卡"
	_rule_label.text = ""
	_difficulty_label.text = ""
	_drag_hint_label.text = ""
