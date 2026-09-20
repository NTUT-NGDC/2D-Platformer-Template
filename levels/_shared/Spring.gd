extends Area2D

# Gym 專用的彈簧：偵測到玩家進入時往上噴出一次衝量。
# 這不是機制卡，是關卡自己的道具，學員不會碰到這個腳本。

@export var bounce_force: float = 500.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_impulse"):
		body.add_impulse(Vector2.UP * bounce_force)
