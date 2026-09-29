extends Node2D

# 手動驗證用：Breakable 的 take_hit 扣耐久、耐久歸零碎裂、Events.hit 轉發，
# 以及 break_by_impact 高速撞擊直接打破、respawn_time 重生。

@onready var _breakable_hit: Node2D = $Breakable_Hit
@onready var _breakable_impact: Node2D = $Breakable_Impact

func _ready() -> void:
	Events.hit.connect(_on_events_hit)
	_breakable_hit.broken.connect(func(): print("[測試] Breakable_Hit：broken 已發出，3 秒後應該重生"))
	_breakable_impact.broken.connect(func(): print("[測試] Breakable_Impact：broken 已發出，respawn_time=0 不會重生"))
	print("[測試] Breakable_Hit（左邊，durability=3）：3 秒後開始每秒呼叫一次 take_hit(1,...)，第三下應該碎裂")
	print("[測試] Breakable_Impact（右邊，break_by_impact 開，impact_speed=200）：走過去，在上面跳一下讓角色落地，落地瞬間速度超過門檻應該直接碎裂")
	_run_hit_sequence()

# 每秒對 Breakable_Hit 呼叫一次 take_hit，模擬被攻擊三次
func _run_hit_sequence() -> void:
	await get_tree().create_timer(3.0).timeout
	for i in 3:
		print("[測試] Breakable_Hit：take_hit 第 %d 下" % (i + 1))
		_breakable_hit.take_hit(1, Vector2.ZERO, self)
		await get_tree().create_timer(1.0).timeout

# 印出 Events.hit 轉發內容，確認受擊介面有正確 emit
func _on_events_hit(target: Node, source: Node) -> void:
	print("[測試] Events.hit 轉發：target=%s source=%s" % [target.name, source.name])
