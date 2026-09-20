extends Node

# 頓幀單例：Engine.time_scale 是全域的，集中在這裡管理避免多處搶著改。

const 時長上限 := 0.3

var _active: bool = false

func _ready() -> void:
	Events.hitstop_requested.connect(_on_hitstop_requested)

func _on_hitstop_requested(duration: float) -> void:
	if _active:
		return
	var clamped_duration: float = clampf(duration, 0.0, 時長上限)
	if clamped_duration <= 0.0:
		return
	_active = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(clamped_duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_active = false
