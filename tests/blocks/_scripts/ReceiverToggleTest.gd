extends Node2D

# 手動驗證用：Launcher、EnemyShooter 的 Receiver 介面（activate/deactivate/toggle）＋ start_on。
# 兩顆按鈕都是「踩一下切換」，turned_on／turned_off 都連到 toggle（場景裡已經連好）。
# 左邊按鈕 reset_on_death 不勾、右邊有勾，比較兩者死亡重生後的差別。

@onready var _shooter: Node = $Enemy_Shooter/EnemyShooter

func _ready() -> void:
	$Launcher_Off.launched.connect(func(_b): print("[測試] Launcher_Off：彈出去了"))
	_shooter.shot.connect(func(): print("[測試] EnemyShooter：開槍"))
	print("[測試] 開場：Launcher_Off 是暗的（start_on 關），走上去不會彈；右邊敵人不會開槍")
	print("[測試] 踩一下左邊按鈕（變綠）→ 彈射台變亮，走上去會被彈起來；再踩一下按鈕 → 又變暗、不會彈")
	print("[測試] 踩一下右邊按鈕 → 約 1.5 秒後敵人開始朝你開槍；再踩一下 → 停火")
	print("[測試] 兩顆按鈕都開著的狀態下被打死重生：")
	print("[測試]   左邊按鈕（reset_on_death 不勾）維持綠色，彈射台維持開著")
	print("[測試]   右邊按鈕（reset_on_death 有勾）變回灰色，敵人停火；再踩一下又會開始射（兩邊沒有對不上）")
