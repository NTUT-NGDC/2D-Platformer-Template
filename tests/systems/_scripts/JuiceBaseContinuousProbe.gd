@tool
extends JuiceBase

# 測試用的持續型 Juice 組件：Inspector 裡看不到「觸發時機」

# 宣告自己是持續型
func _is_continuous() -> bool:
	return true

# 印出已經開始作用
func _on_setup() -> void:
	print("[測試] %s：持續型已開始作用（Inspector 裡不會有「觸發時機」）" % name)
