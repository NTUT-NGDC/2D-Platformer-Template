class_name ShellTrait
extends Node2D

# 殼的特性組件基底：拖進殼（Shell）底下就會生效，不用連任何線。
# 自己做新的特性：繼承這個腳本，在 _on_setup() 裡做初始化，用 shell 拿到自己所在的殼。

var shell: Shell = null

# 殼呼叫，註冊自己並執行子類別初始化
func setup(s: Shell) -> void:
	shell = s
	_on_setup()
	print("[殼的特性] %s 已啟用" % name)

# 特性在這裡做初始化，例如接訊號、偵測碰到殼的東西
func _on_setup() -> void:
	pass

# 檢查有沒有被正確放在殼底下，沒有就發警告
func _ready() -> void:
	# 沒有被 setup 就是放錯位置了，要看得見
	await get_tree().process_frame
	if shell == null:
		push_warning("[殼的特性] %s 沒有放在殼（Shell）底下，不會生效" % name)
		printerr("⚠ [殼的特性] 請把 %s 拖進殼（Shell）底下" % name)
