extends Node2D

# 手動驗證用：Ability_Melee 按 F 在面向方向短暫生成攻擊判定區，打中 Hittable 會扣血／擊退，
# 冷卻中再按不會生效。

@onready var _breakable: StaticBody2D = $Breakable_Target

func _ready() -> void:
	_breakable.broken.connect(func(): print("[測試] Breakable_Target 碎裂了"))
	print("[測試] 走到 Breakable_Target（耐久 3）右邊一點點，面向右邊按 F 攻擊三次（要等冷卻 0.5 秒）")
	print("[測試] 每按一次應該扣 1 點耐久，冷卻中連按不會多扣，第三下應該碎裂")
	print("[測試] 再往右走到 Enemy_Target（被兩面牆夾住）旁邊按 F，應該看到牠被打退一小段距離")
	print("[測試] 面向左邊（走過頭再按 F）攻擊判定區應該改成往左邊生成，不會打到背後的東西")
