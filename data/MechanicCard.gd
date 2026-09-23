extends Resource
class_name MechanicCard

# 一張主限制卡的顯示資料。抽卡場景 CardDraw.tscn 只讀這些欄位，
# 難度是我自己先評的一版（01b_mechanic_cards.md 沒有逐卡難度資料），覺得不準就直接在這裡改數字。

## 中文卡名
@export var card_name: String = ""
## mechanics/ 底下的檔名，不含副檔名
@export var file_name: String = ""
## 操作類／物理類（目前抽卡場景沒有顯示這欄，留著方便之後篩選用）
@export var category: String = ""
## 規則說明，玩家看得懂的白話版，一到兩句
@export_multiline var rule_text: String = ""
## 技術難度：操作上手難不難，1～2
@export_range(1, 2) var difficulty_technical: int = 1
## 設計難度：拿這張卡設計關卡難不難，1～2
@export_range(1, 2) var difficulty_design: int = 1
