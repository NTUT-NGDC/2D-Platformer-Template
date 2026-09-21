# 01 — W1：機制卡 + 通用 Gym

> 前置：`CLAUDE.md`、`documents/00_foundation.md`（必須先通過地基驗收）

W1 的課堂活動是：學員線上抽一張**主限制卡** → 把對應的 `.tscn` 拖進 Player → Mechanics →
**拿著這張卡去撞 Gym 裡的每一個東西**，觀察會發生什麼，寫成 3-5 條實驗清單。

卡牌分成兩種用途：

- **主限制卡（操作類 5 張、物理類 5 張）**：每人選一張，作為整個遊戲的核心玩法。唯一任務是**跟 Gym 裡的各種物件產生有趣的化學反應**。
- **規則卡（8 張）**：W2 關卡設計時用在第三螢幕「轉」，打破玩家前兩個螢幕建立的習慣。W1 有餘力的學員可以先抽一張掛上來試。

抽卡順序：先選主限制卡，再從**相容的**規則卡裡抽（衝突組合見第 4 節）。

---

## 1. 卡牌總表

全部繼承 `MechanicBase`，全部放在 `mechanics/`，檔名即節點名。
難度維持 ⭐~⭐⭐，**不做地獄難度的卡**。

### 主限制卡

| # | 檔名 | 中文卡名 | 類別 | 實作方式 |
|---|---|---|---|---|
| 1 | `Mechanic_NoFriction` | 煞車失靈 | 操作 | `ctx.friction_scale` |
| 2 | `Mechanic_AutoRun` | 只能往前 | 操作 | `ctx.auto_run_dir`，撞牆反轉 |
| 3 | `Mechanic_ChargeJump` | 蓄力青蛙跳 | 操作 | 攔截跳躍輸入，`force_jump()` |
| 4 | `Mechanic_Slingshot` | 只能用滑鼠控制 | 操作 | `ctx.input_locked` + 拖曳放開 `add_impulse()` |
| 5 | `Mechanic_RecoilMove` | 只用後座力移動 | 操作 | `ctx.input_locked` + 方向鍵反向 `add_impulse()` |
| 6 | `Mechanic_PinballBody` | 彈珠台體質 | 物理 | `ctx.damage_scale = 0` + 碰撞擊飛 |
| 7 | `Mechanic_GravityFlip` | 重力翻轉 | 物理 | `flip_gravity()` |
| 8 | `Mechanic_BouncyWorld` | 彈性宇宙 | 物理 | 撞擊時反向 `add_impulse()` |
| 9 | `Mechanic_SpeedRamp` | 越跑越快 | 物理 | `ctx.speed_scale` + `ctx.jump_scale` 隨移動累加 |
| 10 | `Mechanic_SizeShift` | 忽大忽小 | 物理 | `set_size_factor()` |

### 規則卡

| # | 檔名 | 中文卡名 | 實作方式 |
|---|---|---|---|
| 11 | `Mechanic_StickyBody` | 黏黏身體 | 碰撞時 `ctx.gravity_scale = 0` + 鎖住速度 |
| 12 | `Mechanic_Stamina` | 移動會扣血 | 體力條，耗盡時 `ctx.speed_scale` 降低 |
| 13 | `Mechanic_TouchDeath` | 碰觸即死 | 任何碰撞 → `kill()` |
| 14 | `Mechanic_SurvivalTimer` | 存活計時 | 計時 → `Events.level_cleared` |
| 15 | `Mechanic_StopDeath` | 停下即死 | 靜止逾時 → `kill()` |
| 16 | `Mechanic_HealthDrain` | 血量流失 | 自帶血量持續下降，吃金幣回復 |
| 17 | `Mechanic_FloorIsLava` | 地板是岩漿 | 特定地板接觸 → `take_damage()` |
| 18 | `Mechanic_SwitchWorld` | 開關世界 | 計時切換 group `switch_red` / `switch_blue` 方塊 |

---

## 2. 對地基的新增需求

以下是本規格用到、但 `00_foundation.md` 不一定已經有的東西。
**若地基已有等價欄位就沿用；沒有才新增，並同步更新 `documents/00_foundation.md`。** 新增前先在計劃模式列出來給講師確認。

| 項目 | 用途 | 預設值 |
|---|---|---|
| `ctx.damage_scale` | 彈珠台體質把傷害歸零 | `1.0` |
| `ctx.jump_scale` | 越跑越快、忽大忽小調整跳躍力 | `1.0` |
| `ctx.gravity_scale` | 黏黏身體黏住時關閉重力 | `1.0` |
| `ctx.knockback_scale` | 忽大忽小調整被擊退的程度 | `1.0` |
| `ctx.push_scale` | 忽大忽小調整推箱子的力道 | `1.0` |
| 輸入動作 `mechanic_action` | 重力翻轉、忽大忽小的切換鍵 | Shift |
| 輸入動作 `move_up` / `move_down` | 後座力移動的上下噴射 | ↑ / ↓ |
| `Events.mechanic_event(card, event)` | 主限制卡的關鍵瞬間，為 W3 果汁組件預留 | — |

`kill()` 必須**繞過** `ctx.damage_scale`，直接死亡。

---

## 3. 各卡規格

每張卡的 Inspector **最多 4 個欄位**，全部中文、全部是拉桿或下拉或勾選。
`啟用` 由基底提供，不需重複宣告。

**`啟用` 必須可以在執行中切換**：關閉時乾淨還原它對 `ctx` 的所有修改、移除它生成的 UI。W2 會用觸發區在第三螢幕才打開規則卡。

每張主限制卡附一行「事件」，在該瞬間 emit `Events.mechanic_event`。W1 不需要有任何東西訂閱它。

### 主限制卡

#### 1. 煞車失靈 `Mechanic_NoFriction`
```gdscript
@export_range(0.0, 1.0) var 剩餘摩擦力: float = 0.0
```
`apply()`：`ctx.friction_scale = 剩餘摩擦力`
事件：`slide_start`（放開按鍵後仍在滑動的第一幀）

#### 2. 只能往前 `Mechanic_AutoRun`
```gdscript
@export_enum("向右", "向左") var 起始方向: int = 0
@export var 撞牆轉向: bool = true
@export_range(0.05, 0.5) var 轉向冷卻秒數: float = 0.15
```
設定 `ctx.auto_run_dir`，玩家只能按跳躍。
`撞牆轉向` 開啟時，`is_on_wall()` 且牆面法線與前進方向相反 → 反轉方向，`visual.scale.x` 同步翻轉。
可推箱子也算牆（箱子是轉向工具）。冷卻用來避免卡在角落時左右抖動。
事件：`wall_turned`

#### 3. 蓄力青蛙跳 `Mechanic_ChargeJump`
```gdscript
@export_range(0.2, 2.0) var 最長蓄力秒數: float = 1.0
@export_range(0.3, 1.0) var 最小跳躍比例: float = 0.4
@export var 蓄力時不能移動: bool = true
```
按住跳躍鍵累積，放開時 `player.force_jump(比例)`。手感參考 Jump King。
**對外公開 `is_charging: bool`**，停下即死會讀取它（見第 4 節）。
事件：`charge_start`、`charge_release`

#### 4. 只能用滑鼠控制 `Mechanic_Slingshot`
```gdscript
@export_range(200.0, 1200.0) var 最大發射力道: float = 700.0
@export_range(50.0, 300.0) var 最大拖曳距離: float = 150.0
@export var 只能在地面發射: bool = true
@export var 顯示瞄準線: bool = true
```
`ctx.input_locked = true`。按住滑鼠左鍵往後拖，放開時往拖曳的**反方向**
`add_impulse()`，力道 = 拖曳距離比例 × 最大發射力道。
`只能在地面發射` 開啟時，離地期間無法開始拖曳。
瞄準線由組件自己生成 `Line2D`，學員不用擺。
事件：`launched`

#### 5. 只用後座力移動 `Mechanic_RecoilMove`
```gdscript
@export_range(100.0, 800.0) var 後座力強度: float = 350.0
@export_range(1, 5) var 空中次數: int = 3
@export var 落地回充: bool = true
@export_range(0.1, 1.0) var 冷卻秒數: float = 0.3
```
`ctx.input_locked = true`。按下方向鍵（上下左右）→ 往**反方向** `add_impulse()`。
每次噴射消耗一次，`落地回充` 開啟時著地即補滿。次數用完時 `visual` 短暫閃灰提示。
**Gym 必須夠開闊**，否則這張卡玩不動。
事件：`recoil_fired`、`recoil_empty`

#### 6. 彈珠台體質 `Mechanic_PinballBody`
```gdscript
@export_range(300.0, 1500.0) var 擊飛力道: float = 800.0
@export var 敵人會擊飛: bool = true
@export var 尖刺會擊飛: bool = true
@export_range(0.1, 1.0) var 無敵秒數: float = 0.3
```
`ctx.damage_scale = 0`。碰到 group `enemy` / `hazard` 時，沿碰撞法線加一點向上偏移
`add_impulse()`。擊飛後的無敵時間避免同一次碰撞連續觸發。
掉進深坑仍然照常重生。
事件：`knocked`

#### 7. 重力翻轉 `Mechanic_GravityFlip`
```gdscript
@export_enum("按下按鍵", "落地時", "撞牆時") var 觸發時機: int = 0
@export_range(0.1, 1.0) var 冷卻秒數: float = 0.3
```
呼叫 `player.flip_gravity()`，按鍵為 `mechanic_action`。翻轉時 `visual` 要同步上下翻（`scale.y *= -1`）。
事件：`flipped`

#### 8. 彈性宇宙 `Mechanic_BouncyWorld`
```gdscript
@export_range(0.3, 1.5) var 彈性: float = 0.9
@export var 地板也會彈: bool = true
```
碰撞時取法線反彈（`velocity.bounce(normal)`，CharacterBody2D 不吃 PhysicsMaterial）。
**必須設下限**：速度低於閾值就停止彈跳，否則會永遠抖動。
事件：`bounced`

#### 9. 越跑越快 `Mechanic_SpeedRamp`
```gdscript
@export_range(1.0, 5.0) var 最高倍率: float = 3.0
@export_range(1.0, 20.0) var 加速秒數: float = 10.0
@export_range(0.0, 1.0) var 速度影響跳躍: float = 0.5
@export var 停下會重置: bool = true
```
持續移動時倍率累加，`ctx.speed_scale = 當前倍率`。
`ctx.jump_scale = 1 + (當前倍率 - 1) × 速度影響跳躍`，設為 0 時跳躍不受影響。
`停下會重置` 開啟時，水平速度接近 0 即歸零。
事件：`speed_max`（第一次達到最高倍率）、`speed_reset`

#### 10. 忽大忽小 `Mechanic_SizeShift`
```gdscript
@export_enum("按下按鍵", "隨時間") var 觸發時機: int = 0
@export_range(0.3, 1.0) var 小隻倍率: float = 0.5
@export_range(1.0, 2.5) var 大隻倍率: float = 1.8
@export var 體型影響能力: bool = true
```
在大小兩種狀態間切換，按鍵為 `mechanic_action`；`隨時間` 則每 3 秒自動切換。
呼叫 `player.set_size_factor()`。**必須改 CollisionShape2D 的尺寸，不要縮放整個物理節點**；
變大時若會與地形重疊，延後到空間足夠時才套用。

`體型影響能力` 開啟時：

- 大隻：`ctx.push_scale` 提高（推得動箱子）、`ctx.knockback_scale` 降低、`ctx.jump_scale` 降低
- 小隻：`ctx.jump_scale` 提高、`ctx.knockback_scale` 提高（容易被敵人撞飛）

事件：`grew`、`shrank`

### 規則卡

#### 11. 黏黏身體 `Mechanic_StickyBody`
```gdscript
@export_range(0.0, 5.0) var 最長黏著秒數: float = 0.0
@export_range(200.0, 1000.0) var 彈開力道: float = 500.0
@export var 天花板也能黏: bool = true
```
碰到任何表面 → 記下法線、速度歸零、`ctx.gravity_scale = 0`、`ctx.input_locked = true`。
按跳躍 → 往法線方向加一點向上偏移 `add_impulse()`，並給 0.2 秒不可再黏的冷卻。
`最長黏著秒數` 為 0 代表不限；逾時自動脫落。
黏在移動平台上時要跟著平台移動（記錄碰撞物與相對位置）。

#### 12. 移動會扣血 `Mechanic_Stamina`
```gdscript
@export_range(1.0, 10.0) var 體力秒數: float = 3.0
@export_range(0.5, 3.0) var 回復速度倍率: float = 1.0
@export_enum("走不動", "變很慢") var 耗盡懲罰: int = 0
@export var 顯示體力條: bool = true
```
以水平速度判斷是否在移動（而不是讀輸入），這樣搭配任何主限制卡都成立。
移動時扣體力，停下時回復。耗盡時 `ctx.speed_scale` 降到 0 或 0.3，回復到 30% 才解除。
體力條由組件自己生成 `CanvasLayer`。

#### 13. 碰觸即死 `Mechanic_TouchDeath`
```gdscript
@export var 碰到敵人會死: bool = true
@export var 碰到箱子會死: bool = true
@export var 碰到牆壁會死: bool = false
```
用 group 判定（`enemy` / `box` / `wall`），不綁特定物件。`hazard` 一律致死。
直接呼叫 `kill()`，因此不受彈珠台體質的傷害歸零影響。

#### 14. 存活計時 `Mechanic_SurvivalTimer`
```gdscript
@export_range(5.0, 60.0) var 目標秒數: float = 10.0
@export var 顯示計時器: bool = true
```
達標 emit `Events.level_cleared`。計時器 UI 由組件自己生成 `CanvasLayer`，學員不用擺。

#### 15. 停下即死 `Mechanic_StopDeath`
```gdscript
@export_range(0.5, 5.0) var 可停留秒數: float = 1.5
@export_enum("直接死亡", "持續扣血") var 懲罰方式: int = 0
@export var 顯示警告: bool = true
```
`顯示警告` 開啟時，接近逾時讓 `visual` 閃紅。
同一個 Player 上有蓄力青蛙跳且 `is_charging == true` 時，暫停計時。

#### 16. 血量流失 `Mechanic_HealthDrain`
```gdscript
@export_range(0.5, 10.0) var 每秒扣血: float = 1.0
@export_range(1.0, 20.0) var 總血量: float = 10.0
@export_range(0.5, 10.0) var 每枚金幣補血: float = 2.0
@export var 顯示血條: bool = true
```
血量處理方式與地板是岩漿相同，歸零時 `kill()`。
碰到 group `coin` 的物件時補血（若地基已有 `Events.coin_collected` 則直接訂閱）。

#### 17. 地板是岩漿 `Mechanic_FloorIsLava`
```gdscript
@export_range(0.5, 10.0) var 每秒扣血: float = 2.0
@export_range(1.0, 20.0) var 總血量: float = 10.0
@export_enum("只有岩漿地板", "所有地板") var 範圍: int = 0
@export var 顯示血條: bool = true
```
- `只有岩漿地板`：接觸 group `lava` 的地形才扣血。
- `所有地板`：站在任何地面上都扣血，group `safe` 的平台除外。

#### 18. 開關世界 `Mechanic_SwitchWorld`
```gdscript
@export_range(0.5, 5.0) var 切換秒數: float = 2.0
@export_enum("紅色先", "藍色先") var 起始顏色: int = 0
@export var 切換前閃爍: bool = true
```
控制場景中所有 `props/SwitchBlock.tscn`（Inspector 用下拉選紅或藍，自動加入 group `switch_red` / `switch_blue`）。
未啟用的顏色：關閉碰撞、透明度降到 0.3。
**方塊實體化時若與玩家重疊，該方塊延後到玩家離開才實體化**，避免把玩家卡進去。
場景中找不到任何 SwitchBlock 時，輸出中文警告。

---

## 4. 組合衝突處理

原則：**任意組合都不崩潰**；會互相抵銷的組合必須在輸出面板印中文警告，不准靜默失效。
兩者行為衝突時，**規則卡優先**（它是關卡的「轉」）。

| 組合 | 處理方式 |
|---|---|
| 蓄力青蛙跳 × 停下即死 | 自動處理：蓄力中暫停計時 |
| 只能往前 × 移動會扣血 | 自動處理：改為每次跳躍扣固定體力，並印提示 |
| 只能往前 × 停下即死 | 警告：「自動奔跑不會停下，停下即死不會觸發」 |
| 只能往前 × 黏黏身體 | 警告；黏住期間暫停自動奔跑 |
| 彈性宇宙 × 黏黏身體 | 警告；黏黏身體優先，彈性暫停 |
| 彈珠台體質 × 碰觸即死 | 自動處理：`kill()` 繞過傷害歸零，碰觸即死生效 |

線上抽卡工具請直接排除會印警告的組合。

---

## 5. 備品庫 `mechanics/_extra/`

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
| `Extra_StompOnly` | 純靠踩怪起飛（基礎跳躍力為 0，只能踩怪反彈），給想挑戰的老手 |

規格與正式卡相同（繼承 `MechanicBase`、中文 Inspector、最多 4 欄）。

---

## 6. 通用 Gym `levels/Gym.tscn`

### 6.1 設計目的

不是關卡，是**實驗場**。學員拿著自己的卡去撞每一個物件，觀察化學反應。
同一個 Gym 配 10 張主限制卡 = 10 種完全不同的結果，只需維護一個場景。

### 6.2 必要物件

每個區塊之間要有清楚的視覺分隔（地板換色即可），並在上方用 `Label` 標示名稱。

| 區塊 | 內容 | 主要用來測 |
|---|---|---|
| 起點平地 | 一段夠長的平坦地面 | 所有卡的基本移動、越跑越快 |
| 斜坡組 | 緩坡 15°、陡坡 40°，上下各一 | 煞車失靈、越跑越快 |
| 垂直牆 | 兩面高牆夾出一道縫 | 彈性宇宙、只能往前、黏黏身體、重力翻轉（撞牆時） |
| 天花板走廊 | 上下都是實心的長廊 | 重力翻轉、黏黏身體、後座力 |
| 窄縫 | 只有半個角色高的通道 | 忽大忽小、彈性宇宙 |
| 深坑 | 掉下去會重生 | 蓄力跳、只能用滑鼠控制、後座力 |
| 彈簧 | 兩個不同力道的跳床 | 所有卡（觀察疊加） |
| 可推箱子 | 3 個 `RigidBody2D`，group `box` | 只能往前、忽大忽小、碰觸即死 |
| 來回平台 | 水平與垂直各一，固定速度 | 煞車失靈、黏黏身體、停下即死 |
| 笨敵人 | 2 隻只會左右走、碰到會扣血，group `enemy` | 彈珠台體質、忽大忽小、碰觸即死 |
| 尖刺 | 一小排地刺與一面牆刺，group `hazard` | 彈珠台體質、碰觸即死 |
| 連續小台階 | 5 階等高台階 | 蓄力跳、越跑越快、只能往前 |
| 金幣列 | 一排 group `coin` 的金幣 | 血量流失 |
| 岩漿地板 | 一小段紅色地板（group `lava`），上方兩塊小平台（group `safe`） | 地板是岩漿 |
| 開關方塊區 | 紅藍 SwitchBlock 交錯排成一段路 | 開關世界 |
| 開闊區 | 最右側一片大空地，無障礙 | 後座力移動、只能用滑鼠控制 |

### 6.3 出廠節點結構

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

### 6.4 鏡頭

Gym 比一個螢幕寬。**不要做鏡頭跟隨**（W2 的理論課會解釋為什麼固定鏡頭）。
做法：`Camera2D` 縮小到能看見約兩個螢幕寬，並允許用方向鍵或滑鼠拖曳平移。
或者更簡單：讓鏡頭只在水平方向跟隨、垂直鎖死，避免跳躍時畫面上下抽動。

注意：後座力移動與只能用滑鼠控制會佔用方向鍵與滑鼠，鏡頭平移需另外提供按鍵（例如 Q / E），避免衝突。

---

## 7. W1 的起始場景

`levels/_starts/` 這週不需要內容（W1 本身就是起點）。
但 `_my/MyGym.tscn` 要不要預先建好？**不要。**
W1 開場要教學員做一次「另存新檔到 `_my/`」，這是他後面五週都要用的動作。

---

## 8. 驗收條件

- [ ] 18 張卡各自單獨掛上，在 Gym 裡跑得動且不報錯
- [ ] 每張主限制卡至少能跟 Gym 裡**三個以上**不同區塊產生可觀察的不同結果
- [ ] 任選 1 張主限制卡 + 1 張規則卡同時掛上，遊戲不崩潰
- [ ] 第 4 節的衝突組合：自動處理的有正確行為，需要警告的有中文警告
- [ ] 每張卡的 `啟用` 在執行中關閉，`ctx` 完全還原、生成的 UI 被移除
- [ ] 每張卡的 Inspector 都是中文、都不需要打字、欄位不超過 4 個
- [ ] 把任一張卡拖到錯誤位置，輸出面板有中文警告
- [ ] 彈性宇宙不會無限抖動；忽大忽小不會把角色卡進地形；開關世界不會把角色卡進方塊
- [ ] 黏黏身體黏在移動平台上會跟著移動
- [ ] 主限制卡在指定瞬間 emit `Events.mechanic_event`
- [ ] 煙霧測試通過（會自動掃 `mechanics/` 底下所有 `.tscn`）
- [ ] Gym 另存到 `_my/MyGym.tscn` 後，`git status` 只有 `_my/` 有變更
- [ ] 整包能成功 Web export，且匯出後的 Gym 在瀏覽器裡玩得動