extends RefCounted
class_name MoveContext

var speed_scale: float = 1.0
var jump_scale: float = 1.0
var gravity_scale: float = 1.0
var friction_scale: float = 1.0
var auto_run_dir: int = 0        # 0 = 不強制，-1/1 = 強制方向
var input_locked: bool = false
var damage_scale: float = 1.0    # 受傷倍率，彈珠台體質這類卡拿來把傷害歸零
var push_scale: float = 1.0      # 推箱子的力道倍率，忽大忽小這類卡拿來調整
var knockback_scale: float = 1.0 # 被擊退的程度倍率，忽大忽小這類卡拿來調整
var movement_frozen: bool = false # 徹底鎖死水平和垂直移動，蓋過其他卡對方向／重力的提案，
                                   # 黏黏身體這類「整個人完全不能動」的規則卡拿來蓋過主限制卡
var delta: float = 0.0
