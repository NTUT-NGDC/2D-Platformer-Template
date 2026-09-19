# 01 — W1：12 張機制卡 + 通用 Gym

> 前置：`CLAUDE.md`、`specs/00-foundation.md`（必須先通過地基驗收）

W1 的課堂活動是：學員線上抽一張機制卡 → 把對應的 `.tscn` 拖進 Player → Mechanics →
**拿著這張卡去撞 Gym 裡的每一個東西**，觀察會發生什麼，寫成 3-5 條實驗清單。

所以這 12 張卡的唯一任務是：**跟 Gym 裡的各種物件產生有趣的化學反應。**

---

## 1. 12 張卡總表

全部繼承 `MechanicBase`，全部放在 `mechanics/`，檔名即節點名。
難度維持 ⭐~⭐⭐，**不做地獄難度的卡**。

| # | 檔名 | 中文卡名 | 類別 | 實作方式 |
|---|---|---|---|---|
| 1 | `Mechanic_NoFriction` | 煞車失靈 | 操作 | `ctx.friction_scale` |
| 2 | `Mechanic_AutoRun` | 只能往前 | 操作 | `ctx.auto_run_dir` |
| 3 | `Mechanic_ChargeJump` | 蓄力青蛙跳 | 操作 | 攔截跳躍輸入，`force_jump()` |
| 4 | `Mechanic_RecoilMove` | 只用後座力移動 | 操作 | `ctx.input_locked` + `add_impulse()` |
| 5 | `Mechanic_GravityFlip` | 重力翻轉 | 物理 | `flip_gravity()` |
| 6 | `Mechanic_BouncyWorld` | 彈性宇宙 | 物理 | 撞擊時反向 `add_impulse()` |
| 7 | `Mechanic_SpeedRamp` | 越跑越快 | 物理 | `ctx.speed_scale` 隨時間累加 |
| 8 | `Mechanic_SizeShift` | 忽大忽小 | 物理 | `set_size_factor()` |
| 9 | `Mechanic_TouchDeath` | 碰觸即死 | 規則 | 任何碰撞 → `kill()` |
| 10 | `Mechanic_SurvivalTimer` | 存活計時 | 規則 | 計時 → `Events.level_cleared` |
| 11 | `Mechanic_StopDeath` | 停下即死 | 規則 | 靜止逾時 → `kill()` |
| 12 | `Mechanic_FloorIsLava` | 地板是岩漿 | 規則 | 特定 group 接觸 → `take_damage()` |

---

## 2. 各卡規格

每張卡的 Inspector **最多 4 個欄位**，全部中文、全部是拉桿或下拉或勾選。
`啟用` 由基底提供，不需重複宣告。

### 1. 煞車失靈 `Mechanic_NoFriction`
```gdscript
@export_range(0.0, 1.0) var 剩餘摩擦力: float = 0.0
```
`apply()`：`ctx.friction_scale = 剩餘摩擦力`

### 2. 只能往前 `Mechanic_AutoRun`
```gdscript
@export_enum("向右", "向左") var 方向: int = 0
@export var 允許跳躍: bool = true
```
`apply()`：設定 `ctx.auto_run_dir`；`允許跳躍 == false` 時不影響跳躍輸入（跳躍另走 Player 輸入）

### 3. 蓄力青蛙跳 `Mechanic_ChargeJump`
```gdscript
@export_range(0.2, 2.0) var 最長蓄力秒數: float = 1.0
@export_range(0.3, 1.0) var 最小跳躍比例: float = 0.4
@export var 蓄力時不能移動: bool = true
```
按住跳躍鍵累積，放開時 `player.force_jump(比例)`。手感參考 Jump King。

### 4. 只用後座力移動 `Mechanic_RecoilMove`
```gdscript
@export_range(100.0, 800.0) var 後座力強度: float = 350.0
@export_range(0.1, 1.0) var 冷卻秒數: float = 0.3
```
`ctx.input_locked = true`；滑鼠左鍵點擊 → 往點擊反方向 `add_impulse()`。
**Gym 必須夠開闊**，否則這張卡玩不動。

### 5. 重力翻轉 `Mechanic_GravityFlip`
```gdscript
@export_enum("按下按鍵", "落地時", "撞牆時") var 觸發時機: int = 0
@export_range(0.1, 1.0) var 冷卻秒數: float = 0.3
```
呼叫 `player.flip_gravity()`。翻轉時 `visual` 要同步上下翻（`scale.y *= -1`）。

### 6. 彈性宇宙 `Mechanic_BouncyWorld`
```gdscript
@export_range(0.3, 1.5) var 彈性: float = 0.9
@export var 地板也會彈: bool = true
```
碰撞時取法線反彈。**必須設下限**：速度低於閾值就停止彈跳，否則會永遠抖動。

### 7. 越跑越快 `Mechanic_SpeedRamp`
```gdscript
@export_range(1.0, 5.0) var 最高倍率: float = 3.0
@export_range(1.0, 20.0) var 加速秒數: float = 10.0
@export var 停下會重置: bool = true
```
`apply()`：`ctx.speed_scale = 當前倍率`

### 8. 忽大忽小 `Mechanic_SizeShift`
```gdscript
@export_enum("隨時間", "跳躍時切換", "受傷時") var 觸發時機: int = 0
@export_range(0.3, 1.0) var 最小倍率: float = 0.5
@export_range(1.0, 2.5) var 最大倍率: float = 1.8
```
呼叫 `player.set_size_factor()`。**CollisionShape2D 必須同步縮放**，且變大時要確認不會卡進地形（縮放後若重疊則延後套用）。

### 9. 碰觸即死 `Mechanic_TouchDeath`
```gdscript
@export var 碰到敵人會死: bool = true
@export var 碰到箱子會死: bool = true
@export var 碰到牆壁會死: bool = false
```
用 group 判定（`enemy` / `box` / `wall`），不綁特定物件。

### 10. 存活計時 `Mechanic_SurvivalTimer`
```gdscript
@export_range(10.0, 120.0) var 目標秒數: float = 30.0
@export var 顯示計時器: bool = true
```
達標 emit `Events.level_cleared`。計時器 UI 由組件自己生成 `CanvasLayer`，學員不用擺。

### 11. 停下即死 `Mechanic_StopDeath`
```gdscript
@export_range(0.5, 5.0) var 可停留秒數: float = 1.5
@export_enum("直接死亡", "持續扣血") var 懲罰方式: int = 0
@export var 顯示警告: bool = true
```
`顯示警告` 開啟時，接近逾時讓 `visual` 閃紅。

### 12. 地板是岩漿 `Mechanic_FloorIsLava`
```gdscript
@export_range(0.5, 10.0) var 每秒扣血: float = 2.0
@export_range(1.0, 20.0) var 總血量: float = 10.0
@export var 顯示血條: bool = true
```
接觸 group `lava` 的地形才扣血（Gym 裡會有一部分地板標成 lava）。

---

## 3. 備品庫 `mechanics/_extra/`

學員最常許願的東西，先做好藏著，課堂上有人問就當場拖給他（30 秒解決，不用坐下來寫程式）。
**不列在抽卡池裡，不在課堂上主動介紹。**

| 檔名 | 說明 |
|---|---|
| `Extra_DoubleJump` | 二段跳 |
| `Extra_Dash` | 衝刺 |
| `Extra_WallJump` | 蹬牆跳 |
| `Extra_StickyFloor` | 黏黏地板（踩上去變慢／黏住） |
| `Extra_Magnet` | 磁力吸附附近箱子 |
| `Extra_TimeSlow` | 按鍵子彈時間 |

規格與 12 張卡相同（繼承 `MechanicBase`、中文 Inspector、最多 4 欄）。

---

## 4. 通用 Gym `levels/Gym.tscn`

### 4.1 設計目的

不是關卡，是**實驗場**。學員拿著自己的卡去撞每一個物件，觀察化學反應。
同一個 Gym 配 12 張卡 = 12 種完全不同的結果，只需維護一個場景。

### 4.2 必要物件

每個區塊之間要有清楚的視覺分隔（地板換色即可），並在上方用 `Label` 標示名稱。

| 區塊 | 內容 | 主要用來測 |
|---|---|---|
| 起點平地 | 一段夠長的平坦地面 | 所有卡的基本移動 |
| 斜坡組 | 緩坡 15°、陡坡 40°，上下各一 | 煞車失靈、越跑越快 |
| 垂直牆 | 兩面高牆夾出一道縫 | 彈性宇宙、蹬牆、撞牆觸發 |
| 天花板走廊 | 上下都是實心的長廊 | 重力翻轉 |
| 窄縫 | 只有半個角色高的通道 | 忽大忽小 |
| 深坑 | 掉下去會重生 | 蓄力跳、後座力 |
| 彈簧 | 兩個不同力道的跳床 | 所有卡（觀察疊加） |
| 可推箱子 | 3 個 `RigidBody2D`，group `box` | 碰觸即死、磁力、物理互動 |
| 來回平台 | 水平與垂直各一，固定速度 | 停下即死、計時類 |
| 笨敵人 | 2 隻只會左右走、碰到會扣血，group `enemy` | 碰觸即死、踩怪 |
| 連續小台階 | 5 階等高台階 | 越跑越快、自動前進 |
| 岩漿地板 | 一小段紅色地板，group `lava` | 地板是岩漿 |
| 開闊區 | 最右側一片大空地，無障礙 | 後座力移動（需要空間） |

### 4.3 出廠節點結構

```
Gym
├── Camera2D            [CameraRig.gd，鎖定不跟隨，可用方向鍵平移]
├── TileMapLayer        [地形]
├── Zones/              [各區塊的物件與 Label]
├── Respawn             [Respawn.gd]
└── Player              [player/Player.tscn 的實例]
    ├── Visual          [group: player_visual]
    │   └── Sprite2D    [白色方塊]
    ├── Mechanics       [空的 Node2D]
    └── Juice           [空的 Node2D]
```

### 4.4 鏡頭

Gym 比一個螢幕寬。**不要做鏡頭跟隨**（W2 的理論課會解釋為什麼固定鏡頭）。
做法：`Camera2D` 縮小到能看見約兩個螢幕寬，並允許用方向鍵或滑鼠拖曳平移。
或者更簡單：讓鏡頭只在水平方向跟隨、垂直鎖死，避免跳躍時畫面上下抽動。

---

## 5. W1 的起始場景

`levels/_starts/` 這週不需要內容（W1 本身就是起點）。
但 `_my/MyGym.tscn` 要不要預先建好？**不要。**
W1 開場要教學員做一次「另存新檔到 `_my/`」，這是他後面五週都要用的動作。

---

## 6. 驗收條件

- [ ] 12 個機制卡各自單獨掛上，在 Gym 裡跑得動且不報錯
- [ ] 每張卡至少能跟 Gym 裡**三個以上**不同區塊產生可觀察的不同結果
- [ ] 任選 3 張卡同時掛上，遊戲不崩潰（即使行為很荒謬）
- [ ] 每張卡的 Inspector 都是中文、都不需要打字、欄位不超過 4 個
- [ ] 把任一張卡拖到錯誤位置，輸出面板有中文警告
- [ ] 彈性宇宙不會無限抖動；忽大忽小不會把角色卡進地形
- [ ] 煙霧測試通過（會自動掃 `mechanics/` 底下所有 `.tscn`）
- [ ] Gym 另存到 `_my/MyGym.tscn` 後，`git status` 只有 `_my/` 有變更
- [ ] 整包能成功 Web export，且匯出後的 Gym 在瀏覽器裡玩得動