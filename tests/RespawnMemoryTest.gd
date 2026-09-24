extends Node2D

# 手動驗證用：RespawnMemory 死亡重生流程，以及 ValueSettings 的 reset_on_death 欄位可以每個
# 數值種類分別設定：這個場景故意讓「金幣」保持預設（會退回）、「鑰匙」「分數」關閉（死亡不受影響）。
# 因為道具零件（Pickup）跟危險地形還沒做出來，用除錯按鍵模擬：
# 按 C 加 5 個金幣、按 S 加 1 分、按 K 立刻死亡。

@onready var _player: CharacterBody2D = $Player
@onready var _checkpoint: Area2D = $Checkpoint
@onready var _key_door: Node2D = $KeyDoor
@onready var _permanent_button: Area2D = $PermanentButton
@onready var _signal_door: Node2D = $SignalDoor

func _ready() -> void:
	_permanent_button.turned_on.connect(_signal_door.activate)
	Stats.add("鑰匙", 1)
	print("[測試] 玩家已經有 1 把鑰匙。按 C 加 5 個金幣、按 S 加 1 分、按 K 立刻死亡")
	print("[測試] 建議先測「完全沒踩重生點就死」：現在直接按 K，應該回到最初的出生點，金幣退回 0")
	print("[測試] 測完可以照這個順序走：踩重生點（變綠）→ 按 C 加金幣、按 S 加分 → 走過鑰匙門（用掉鑰匙，自動開）")
	print("[測試] → 踩永久按鈕（訊號門會打開）→ 按 K 死亡")
	print("[測試] 死亡後應該：在重生點復活、血量補滿")
	print("[測試]   金幣：退回踩重生點當下的數字（reset_on_death 預設開）")
	print("[測試]   鑰匙：維持死亡當下用掉之後的數量，不會退回（ValueSettings_Key 把 reset_on_death 關了）")
	print("[測試]   分數：完全不受影響（ValueSettings_Score 也把 reset_on_death 關了）")
	print("[測試]   鑰匙門、訊號門都保持開著（不會重新載入場景，零件維持原狀）")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_C:
		Stats.add("金幣", 5)
		print("[測試] 金幣 +5，目前：%d" % Stats.get_value("金幣"))
	elif event.physical_keycode == KEY_S:
		Stats.add("分數", 1)
		print("[測試] 分數 +1，目前：%d" % Stats.get_value("分數"))
	elif event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
