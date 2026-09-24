extends Node2D
class_name MechanicBase

## 關閉時這張機制卡不會生效，但仍會顯示在場景裡。
@export var enabled: bool = true

var player: Node = null

# Player 呼叫，註冊自己並執行子類別初始化
func setup(p: Node) -> void:
	player = p
	_on_setup()
	print("[%s] 已啟用" % name)

# 機制卡在這裡做初始化，例如接訊號、設定初始狀態
func _on_setup() -> void:
	pass

# 機制卡在這裡影響每個物理幀的移動參數
func apply(_ctx: MoveContext) -> void:
	pass

# 玩家重生時 Player 會呼叫，機制卡在這裡把自己的狀態歸零（例如翻轉狀態、計時、倍率）
func on_respawn() -> void:
	pass

# 檢查有沒有被正確掛在 Mechanics 底下，沒有就發警告
func _ready() -> void:
	# 沒有被 setup 就是掛錯位置了，要看得見
	await get_tree().process_frame
	if player == null:
		push_warning("[%s] 沒有掛在 Player 的 Mechanics 底下，不會生效" % name)
		printerr("⚠ [%s] 請把這個節點拖進 Player → Mechanics 底下" % name)
