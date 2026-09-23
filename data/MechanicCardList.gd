extends Resource
class_name MechanicCardList

# 一整份卡池，抽卡場景 CardDraw.tscn 從這裡隨機抽一張。

## 卡片清單（每個元素是 MechanicCard）
@export var cards: Array[Resource] = []
