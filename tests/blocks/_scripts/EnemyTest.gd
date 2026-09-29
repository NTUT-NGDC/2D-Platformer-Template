extends Node2D

# 手動驗證用：Enemy 左右巡邏、撞牆轉身、受擊、血量歸零消失、重生後復活。

@onready var _enemy_hit: CharacterBody2D = $Enemy_HitTest

func _ready() -> void:
	_enemy_hit.defeated.connect(func(): print("[測試] Enemy_HitTest：defeated 已發出，應該消失了"))
	print("[測試] Enemy_Wall（被兩面牆夾住）應該左右巡邏、撞牆就轉身，直接看著它來回走就好")
	print("[測試] 3 秒後對 Enemy_HitTest 呼叫 take_hit(1,...)：血量 2→1，應該被打退一下但還活著")
	print("[測試] 再過 2 秒呼叫第二次：血量 1→0，應該消失並發出 defeated")
	print("[測試] 確認消失後，走到左邊踩 Spike_Instant 讓角色死亡重生，Enemy_HitTest 應該重新出現")
	await get_tree().create_timer(3.0).timeout
	_enemy_hit.take_hit(1, Vector2(80, -80), self)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(_enemy_hit):
		_enemy_hit.take_hit(1, Vector2(80, -80), self)
