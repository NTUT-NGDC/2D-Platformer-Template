extends Node2D

# 手動驗證用：EnemyShooter 拖到 Enemy 底下就會開槍。
# Enemy_Aim：朝玩家、偵測 10 格、射擊前停一下。Enemy_Facing：朝面向方向、不限距離、hit_objects 開（會打碎方塊）。
# EnemyShooter_Stray 故意沒放在 Enemy 底下。

@onready var _breakable: StaticBody2D = $Breakable_Target
@onready var _enemy_aim: CharacterBody2D = $Enemy_Aim

# 印出操作說明
func _ready() -> void:
	_breakable.broken.connect(func(): print("[測試] Breakable_Target 被 Enemy_Facing 的子彈打碎（hit_objects 開，正常）"))
	_enemy_aim.defeated.connect(func(): print("[測試] Enemy_Aim 被打倒，應該停止開槍"))
	Events.hit.connect(func(target, source): print("[測試] %s 被 %s 打到" % [target.name, source.name]))
	print("[測試] 開場：輸出面板有 EnemyShooter_Stray 沒放在 Enemy 底下的警告；編輯器裡它的場景樹有黃色驚嘆號")
	print("[測試] 編輯器裡：Enemy_Aim 的 EnemyShooter 有淡紅色圓圈（10 格偵測範圍），Enemy_Facing 的沒有（0 = 不限）")
	print("[測試] 一開始玩家在範圍外：Enemy_Aim 不開槍。往右走進圓圈：Enemy_Aim 停一下、朝玩家射，HUD 血量 -1")
	print("[測試] Enemy_Facing 每秒往牠面向的方向射；面向左時會把 Breakable_Target 打碎（3 秒後長回來）")
	print("[測試] 被打到血量歸零會重生：場上的敵人子彈要全部消失，不會一重生就被打")
	print("[測試] 按 G 反擊：Enemy_Aim 被打倒（3 發）之後就不會再開槍；重生後復活並重新開槍")
