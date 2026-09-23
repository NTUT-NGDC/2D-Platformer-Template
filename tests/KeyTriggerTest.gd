extends Node2D

# 手動驗證用：KeyTrigger 的兩種按鍵來源。
# 「_validate_property 正確顯示對應欄位」這件事要在編輯器的 Inspector 裡肉眼確認：
# 選 KeyTrigger_Action 節點，切換 key_source 下拉選單，應該只看到 action 或 key 其中一個欄位。
#
# 執行期行為：KeyTrigger_Action 用預設動作 jump（跟角色跳躍共用 Space 鍵，驗證「只聽不搶」，
# 按空白鍵角色照樣會跳，同時這裡也會印出訊息）；KeyTrigger_Key 用自訂按鍵 P。

@onready var _action_trigger: Node = $KeyTrigger_Action
@onready var _key_trigger: Node = $KeyTrigger_Key

func _ready() -> void:
	_action_trigger.pressed.connect(func(): print("[測試] KeyTrigger_Action（jump）：pressed，角色應該同時正常跳躍"))
	_action_trigger.released.connect(func(s): print("[測試] KeyTrigger_Action：released，按住了 %.2f 秒" % s))
	_key_trigger.pressed.connect(func(): print("[測試] KeyTrigger_Key（P 鍵）：pressed"))
	_key_trigger.held.connect(func(s): print("[測試] KeyTrigger_Key：held，已經按住 %.2f 秒" % s))
	_key_trigger.released.connect(func(s): print("[測試] KeyTrigger_Key：released，按住了 %.2f 秒" % s))
	print("[測試] 按空白鍵（jump）：角色應該正常跳躍，同時印出 KeyTrigger_Action 的訊息")
	print("[測試] 按住 P 鍵幾秒再放開：應該印出 pressed → 多行 held → released")
