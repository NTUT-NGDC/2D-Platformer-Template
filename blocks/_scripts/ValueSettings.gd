extends Node

# 場景設定節點：一個場景可以放一個或多個，各自對應一個數值種類，
# 拿來覆蓋 Stats 的預設初始值、上限，以及要不要出現在 HUD。沒放的種類維持 Stats 原本的預設行為。

## 這一筆設定要套用到哪個數值種類，例如「血量」「金幣」（打字防呆見 Stats 的打錯字警告）
@export var kind: String = "血量"

## 初始值
@export_range(0, 999) var start_value: int = 3

## 上限，0 代表不限
@export_range(0, 999) var max_value: int = 3

## 打勾：一開場就顯示在畫面左上角；不勾：永遠不顯示
@export var show_in_hud: bool = true

## 死亡重生時要不要退回踩重生點當下的數值；關閉的話死亡完全不影響這個數值
## （例如累計分數、存活時間這種不該被重置的東西）
@export var reset_on_death: bool = true

# 場景一進樹就套用設定，搶在同一個場景其他節點的 _ready() 用到這個數值之前生效
func _enter_tree() -> void:
	Stats.configure(kind, start_value, max_value, show_in_hud, reset_on_death)
