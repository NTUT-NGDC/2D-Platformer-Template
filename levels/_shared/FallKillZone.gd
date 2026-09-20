extends Area2D

# Gym 專用的墜落安全網：掉出地圖底部時視同死亡，觸發 Respawn 重生整個關卡。
# 這不是機制卡，是關卡自己的道具，學員不會碰到這個腳本。

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("kill"):
		body.kill()
