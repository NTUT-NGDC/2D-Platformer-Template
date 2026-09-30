extends Node2D

# 手動驗證用：開槍的後座力兩種做法。
# ① 後座力卡（滑鼠左鍵）的 fired 連到 Ability_Ranged_Signal（只用訊號觸發）的 shoot()：每噴一次就朝游標開一槍。
# ② Ability_Ranged_Kick 按 G 開槍，recoil_strength 300：開槍時角色被往反方向推，damage 3 一槍打倒敵人。
# Ability_Ranged_Unconnected 故意選「只用訊號觸發」又沒連線，開場應該印警告。

@onready var _enemy: CharacterBody2D = $Enemy_Target

# 印出操作說明
func _ready() -> void:
	_enemy.defeated.connect(func(): print("[測試] Enemy_Target 被打倒了"))
	Events.hit.connect(func(target, source): print("[測試] %s 被 %s 打到" % [target.name, source.name]))
	print("[測試] 開場輸出面板應該有一則警告：Ability_Ranged_Unconnected 選了「只用訊號觸發」但沒有訊號連到 shoot()")
	print("[測試] ① 點滑鼠左鍵：角色往游標反方向噴，同時朝游標射出一顆子彈（每噴一次剛好一顆）")
	print("[測試]    空中次數用完再點（閃灰）：不噴也不會射子彈")
	print("[測試]    游標對準右邊的敵人點 3 次（每顆傷害 1）：第 3 顆打倒")
	print("[測試] ② 按 G：朝面向方向（右邊）開槍，角色被往左推；打中敵人一槍就倒（damage 3）")
	print("[測試]    G 有 0.4 秒冷卻，連按不會連射")
