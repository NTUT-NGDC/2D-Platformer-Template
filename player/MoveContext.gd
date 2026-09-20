extends RefCounted
class_name MoveContext

var speed_scale: float = 1.0
var jump_scale: float = 1.0
var gravity_scale: float = 1.0
var friction_scale: float = 1.0
var auto_run_dir: int = 0        # 0 = 不強制，-1/1 = 強制方向
var input_locked: bool = false
var jump_locked: bool = false
var delta: float = 0.0
