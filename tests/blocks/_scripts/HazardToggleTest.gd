extends Node2D

# 手動驗證用：Spike、Lava、Portal 的 Receiver 介面（activate/deactivate/toggle）＋ start_on。
# 三顆按鈕都是「踩一下切換」，turned_on／turned_off 都連到 toggle（場景裡已經連好）。

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	_player.hurt.connect(func(): print("[測試] 玩家受傷，血量 %d" % Stats.get_value(Stats.HEALTH_KIND)))
	$Portal_A.teleported.connect(func(_b): print("[測試] Portal_A：傳送到 Portal_B"))
	$Portal_B.teleported.connect(func(_b): print("[測試] Portal_B：傳送到 Portal_A"))
	print("[測試] 開場：Spike_Off、Portal_A 是暗的（start_on 關），Lava_On 是亮的")
	print("[測試] 1. 直接走過 Spike_Off：不會受傷；回去踩 Button_Spike → 尖刺變亮，再走過去會扣血＋彈開")
	print("[測試] 2. 站在 Lava_On 上：每秒扣血；踩 Button_Lava → 岩漿變暗，站上去不再扣血")
	print("[測試] 3. 走進 Portal_A：不會傳送；踩 Button_Portal → 變亮，走進去傳到 Portal_B")
	print("[測試] 4. Portal_B 一直開著：從 B 走進去會傳回 A（A 關著也一樣會出現在 A）")
