extends Node2D

# 手動驗證用：Timeline＋TimelineEvent。場景裡有兩條獨立的時間軸，秒數都是從各自開始算起的時間點。
# Timeline_Main：第 3 秒開門、第 6 秒關門（門開 3 秒）、第 10 秒那列故意沒連線；
# Timeline_Loop：loop 開啟，每 2 秒切換一次尖刺。Button_Pause 連到 Timeline_Main 的 toggle（踩一下暫停／繼續）。

func _ready() -> void:
	print("[測試] 這個場景有兩條獨立的時間軸，秒數都是「從開始算起第幾秒」，不是等上一列之後幾秒")
	print("[測試] 先看編輯器：兩個時間軸旁邊列出「第幾秒｜事件名稱」並有黃色虛線連到門、尖刺；TimelineEvent_Stray 有黃色驚嘆號")
	print("[測試] 開場輸出面板：「10秒沒連線」沒連線的警告、TimelineEvent_Stray 沒放在 Timeline 底下的警告")
	print("[測試] 畫面右上角有兩行秒數。第 3 秒 Door_A 打開、第 6 秒關上（門開 3 秒），輸出面板印出「第 3.0 秒：觸發…」")
	print("[測試] Spike_Blink 每 2 秒亮暗切換一次（loop），右上角 Timeline_Loop 的秒數每到 2 秒就回到 0")
	print("[測試] 踩 Button_Pause：Timeline_Main 的秒數停住；再踩一下繼續")
	print("[測試] 走去碰最右邊的即死尖刺：重生後兩個時間軸都從 0 重來，門會在第 3 秒再開一次")
