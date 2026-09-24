extends Node2D

# 手動驗證用：EventListener 事件轉接器。
# Listener_Died（玩家死亡時）連到 Door_OnDeath 的 activate；
# Listener_Jump_WrongMethod（玩家跳躍時）故意連到不存在的 open_door；
# Listener_Hurt_NotConnected（玩家受傷時）故意沒連線。按 H 扣 1 血、按 K 立刻死亡。

@onready var _player: CharacterBody2D = $Player

# 印出操作說明
func _ready() -> void:
	print("[測試] 一開始輸出面板應該有兩則中文警告：")
	print("[測試]   連線驗證器：Listener_Jump_WrongMethod 的 triggered 連到的 open_door() 不存在")
	print("[測試]   事件轉接器：Listener_Hurt_NotConnected 還沒連線")
	print("[測試] 按 K 死亡：Door_OnDeath（左邊那扇）應該打開變半透明，0.8 秒後玩家重生")
	print("[測試] 按 H 扣血、按空白鍵跳躍：不會壞、不會報紅字（兩個轉接器連錯或沒連，只是沒效果）")
	print("[測試] 另外在編輯器看：三個紫色圓點各自寫著事件名稱，Listener_Died 有一條黃色虛線連到門")

# 除錯按鍵
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_H:
		_player.take_damage(1.0)
		print("[測試] 扣 1 血")
	elif event.physical_keycode == KEY_K:
		print("[測試] 模擬死亡")
		_player.kill()
