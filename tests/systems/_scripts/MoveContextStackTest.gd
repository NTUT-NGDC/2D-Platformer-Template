extends Node2D

# 手動驗證用：兩張卡調同一個倍率時要乘在一起，不能互相蓋掉。
# 體力（1.5 秒耗盡、走不動）＋越跑越快，自動按住「右」跑兩輪，第二輪把兩張卡在場景樹的順序對調。
# 兩輪都應該：速度先變快，體力耗盡後停下來（速度 0），不會被越跑越快的倍率蓋掉；
# 之後體力回到 30% 會再跑一小段又停，速度在 0 和兩百多之間跳是體力卡本來的行為。
# 修改前：第 1 輪體力 0 時速度還會一路衝到 600。

const _RUN_SECONDS := 4.0
const _PRINT_INTERVAL := 0.5

@onready var _player: CharacterBody2D = $Player
@onready var _mechanics: Node2D = $Player/Mechanics

# 自動跑兩輪，每輪之間讓體力回滿
func _ready() -> void:
	print("[測試] 自動按住「右」%d 秒，跑兩輪；看輸出面板的速度：體力 0 之後要停下來（速度 0），不能繼續衝到 600" % int(_RUN_SECONDS))
	await get_tree().create_timer(0.5).timeout
	await _run_round("第 1 輪（體力在前、越跑越快在後，修改前這個順序會出錯）")
	_mechanics.move_child($Player/Mechanics/Mechanic_SpeedRamp, 0)
	await get_tree().create_timer(2.0).timeout
	await _run_round("第 2 輪（越跑越快在前、體力在後）")
	print("[測試] 測完了：兩輪體力 0 之後都停下來、兩輪數字差不多，就是正確的（跟卡片順序無關）")

# 按住右跑一輪，定時印出速度、體力和越跑越快的倍率
func _run_round(title: String) -> void:
	print("[測試] ---- %s ----" % title)
	Input.action_press("move_right")
	var elapsed := 0.0
	while elapsed < _RUN_SECONDS:
		await get_tree().create_timer(_PRINT_INTERVAL).timeout
		elapsed += _PRINT_INTERVAL
		print("[測試] %.1f 秒：速度 %.0f，體力 %.2f，越跑越快倍率 %.2f" % [
			elapsed, _player.velocity.x,
			$Player/Mechanics/Mechanic_Stamina._stamina,
			$Player/Mechanics/Mechanic_SpeedRamp._multiplier,
		])
	Input.action_release("move_right")
