extends Node

# 場景設定節點：一個場景可以放一個或多個，各自對應一個數值種類，
# 拿來覆蓋 Stats 的預設初始值、上限，以及要不要出現在 HUD。沒放的種類維持 Stats 原本的預設行為。

## 這一筆設定要套用到哪個數值種類，例如「血量」「金幣」（打字防呆見 Stats 的打錯字警告）
@export var kind: String = "血量"

## 初始值
@export_range(0, 999) var start_value: int = 3

## 上限，0 代表不限
@export_range(0, 999) var max_value: int = 3

## 是否顯示在畫面左上角的數值列
@export var show_in_hud: bool = true

# 場景一進樹就套用設定，搶在同一個場景其他節點的 _ready() 用到這個數值之前生效
func _enter_tree() -> void:
	Stats.configure(kind, start_value, max_value, show_in_hud)
