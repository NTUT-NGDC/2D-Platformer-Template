class_name Layers
extends RefCounted

# 碰撞圖層常數：設定 collision_layer／collision_mask 一律用這些名字，不要直接寫數字或位元運算。
# 編號對照 documents/01a_shared_systems.md §2，也跟專案設定的圖層名稱一致。
# 多個圖層用 | 合起來，例如 collision_mask = Layers.PLAYER | Layers.BOX

# 圖層 1「玩家」
const PLAYER := 1 << 0
# 圖層 2「地形」：TileMap、門、崩塌地板、岩漿、平台、可破壞方塊、彈射台、開關方塊
const TERRAIN := 1 << 1
# 圖層 3「箱子」
const BOX := 1 << 2
# 圖層 4「敵人」
const ENEMY := 1 << 3
# 圖層 5「感應」：道具、傳送門、重生點、風扇、終點、按鈕、尖刺判定區
const SENSOR := 1 << 4
# 圖層 6「攻擊」：近戰判定、子彈
const ATTACK := 1 << 5
