extends CanvasLayer

# 過關畫面：拖進關卡就生效，不用連任何線。終點、存活計時卡這類東西發出過關事件時自動跳出來，
# 遊戲暫停，顯示「過關！」、用了幾秒、死了幾次、製作者自己寫的一行字；按 R 整關重來再玩一次。
# 也可以用 activate 讓別的零件的訊號叫出來（例如打倒魔王就過關）。

## 顯示從開場（或上一次再玩一次）到過關用了幾秒
@export var show_time: bool = true

## 顯示這一輪死了幾次
@export var show_deaths: bool = true

## 過關畫面最下面多顯示一行字，例如「感謝遊玩！」「製作：小明」；空白就不顯示（這一格可以打字）
@export var message: String = ""

@onready var _time_label: Label = %TimeLabel
@onready var _deaths_label: Label = %DeathsLabel
@onready var _message_label: Label = %MessageLabel
@onready var _center: CenterContainer = $CenterContainer
@onready var _list: VBoxContainer = $CenterContainer/VBoxContainer

var _showing: bool = false

## 顯示過關畫面（已經在顯示就不重複）
func activate() -> void:
	if _showing:
		return
	_showing = true
	_time_label.visible = show_time
	var elapsed := HudData.get_value(HudData.PLAY_TIME)
	var deaths := int(HudData.get_value(HudData.DEATHS))
	_time_label.text = "用了 %.1f 秒" % elapsed
	_deaths_label.visible = show_deaths
	_deaths_label.text = "死了 %d 次" % deaths
	var clean_message := message.strip_edges()
	_message_label.visible = clean_message != ""
	_message_label.text = clean_message
	visible = true
	get_tree().paused = true
	print("[過關畫面] 過關！用了 %.1f 秒、死了 %d 次，按 R 再玩一次" % [elapsed, deaths])

# 加入群組（讓終點、重生記憶知道場景裡有過關畫面），接上過關事件；暫停時也要能收按鍵
func _ready() -> void:
	add_to_group("clear_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	Events.level_cleared.connect(activate)
	_center.sort_children.connect(_snap_to_pixels.bind(_center))
	_list.sort_children.connect(_snap_to_pixels.bind(_list))
	if get_tree().get_nodes_in_group("clear_screen").size() > 1:
		push_warning("[過關畫面] 場景裡有不只一個 ClearScreen，會疊在一起")
		printerr("⚠ [過關畫面] 場景裡有不只一個 ClearScreen，%s 可以刪掉" % name)

# 容器置中算出來的位置常常落在半個像素上，像素字型畫在半格會糊掉，排好之後一律捨去成整數像素
func _snap_to_pixels(container: Container) -> void:
	for child in container.get_children():
		if child is Control:
			(child as Control).position = (child as Control).position.floor()

# 顯示中按 R（restart 動作）：關掉畫面、解除暫停、整關重來
func _unhandled_input(event: InputEvent) -> void:
	if not _showing or not event.is_action_pressed("restart"):
		return
	get_viewport().set_input_as_handled()
	_play_again()

# 再玩一次：時間、死亡次數歸零，請重生處理者整關重來；終點恢復成還沒踩過
func _play_again() -> void:
	_showing = false
	visible = false
	get_tree().paused = false
	HudData.reset_run()
	get_tree().call_group("goal", "reset")
	var handler := get_tree().get_first_node_in_group("respawn_handler")
	if handler == null or not handler.has_method("restart_level_now"):
		print("[過關畫面] 場景裡沒有 RespawnHandler，沒辦法整關重來，只關掉過關畫面。想要重來就把 blocks/RespawnHandler.tscn 拖進關卡")
		return
	handler.restart_level_now()
