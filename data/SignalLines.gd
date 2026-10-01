class_name SignalLines
extends RefCounted

# 共用訊號連線虛線工具：零件在編輯畫面幫自己發出的訊號，每條連接畫一條黃色虛線到目標節點，
# 學員一眼看得出「這個按鈕連到哪扇門」。在零件的 _draw() 裡呼叫，只在編輯器裡畫。

# 虛線顏色
const COLOR := Color(1.0, 0.85, 0.2, 0.85)

# 從 canvas 的原點畫虛線到 sig 每條連接的目標節點（目標不是 Node2D 就跳過）
static func draw(canvas: Node2D, sig: Signal) -> void:
	if not Engine.is_editor_hint():
		return
	for conn in sig.get_connections():
		var target: Object = (conn["callable"] as Callable).get_object()
		if target is Node2D:
			canvas.draw_dashed_line(Vector2.ZERO, canvas.to_local((target as Node2D).global_position), COLOR, 2.0, 6.0)
