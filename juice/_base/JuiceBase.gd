extends Node2D
class_name JuiceBase

## 關閉時這個 Juice 組件不會生效，但仍會顯示在場景裡。
@export var enabled: bool = true
## 什麼時候要播放這個效果。
@export_enum("跳躍時", "落地時", "受傷時", "死亡時", "撞牆時", "不自動觸發")
var timing: int = 1

var player: Node = null

# Player 呼叫，註冊自己並執行子類別初始化
func setup(p: Node) -> void:
	player = p
	_on_setup()
	print("[%s] 已啟用" % name)

# Juice 組件在這裡做初始化，例如設定初始狀態
func _on_setup() -> void:
	pass

# 依「觸發時機」把 callback 接到對應的 Player 訊號，Juice 組件用這個省去自己判斷要接哪個訊號
func _connect_trigger(callback: Callable) -> void:
	match timing:
		0: player.jumped.connect(callback)
		1: player.landed.connect(func(_f): callback.call())
		2: player.hurt.connect(callback)
		3: player.died.connect(callback)
		4: player.wall_hit.connect(callback)
		5: pass

# 檢查有沒有被正確掛在 Juice 底下，沒有就發警告
func _ready() -> void:
	# 沒有被 setup 就是掛錯位置了，要看得見
	await get_tree().process_frame
	if player == null:
		push_warning("[%s] 沒有掛在 Player 的 Juice 底下，不會生效" % name)
		printerr("⚠ [%s] 請把這個節點拖進 Player → Juice 底下" % name)
