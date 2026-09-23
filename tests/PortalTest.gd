extends Node2D

# 手動驗證用：Portal 傳送。場景裡只在 Portal_A 指定了 pair = Portal_B，
# Portal_B 自己的 pair 留空，驗證「B 自動連回 A」。

@onready var _portal_a: Area2D = $Portal_A
@onready var _portal_b: Area2D = $Portal_B

func _ready() -> void:
	print("[測試] Portal_B 的 pair 欄位沒有手動設定，應該會被 Portal_A 自動補上配對")
	print("[測試] Portal_B 目前配對到：%s（應該是 Portal_A）" % (_portal_b._pair_portal.name if _portal_b._pair_portal else "null"))
	_portal_a.teleported.connect(func(_b): print("[測試] Portal_A：teleported"))
	_portal_b.teleported.connect(func(_b): print("[測試] Portal_B：teleported"))
	print("[測試] 走進左邊的傳送門，應該瞬移到右邊，且不會立刻被傳回去（0.3 秒內不重複觸發）")
