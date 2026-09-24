extends Node2D

# 手動驗證用：Ability_Ranged 按 key 朝面向方向發射子彈，撞到地形或 Hittable 就消失，
# use_gravity 開啟時子彈會像拋物線一樣往下墜。

@onready var _breakable: StaticBody2D = $Breakable_Target

func _ready() -> void:
	_breakable.broken.connect(func(): print("[測試] Breakable_Target 被子彈打碎了"))
	print("[測試] 面向右邊按 G（Ability_Ranged_Flat，直線飛行）打 Breakable_Target，應該一發就碎裂")
	print("[測試] 按 H（Ability_Ranged_Arc，use_gravity 開）發射子彈，應該看到子彈邊飛邊往下墜，")
	print("[測試] 跟 G 的直線子彈比較看看軌跡差異")
	print("[測試] 往右走到 Enemy_Target 附近按 G 或 H，應該看到牠被打退一小段距離")
	print("[測試] 點滑鼠左鍵（Ability_Ranged_Mouse，按鍵種類選滑鼠左鍵）也應該發射直線子彈")
	print("[測試] 往 Wall_Block 的方向發射（不打 Enemy 或 Breakable），子彈撞到牆應該直接消失")
