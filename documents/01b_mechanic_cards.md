# 01b — W1：機制卡

> 前置閱讀：`CLAUDE.md`、`documents/00_foundation.md`、`documents/01a_shared_systems.md`

W1 的課堂活動是：學員線上抽一張**主限制卡** → 把對應的 `.tscn` 拖進 Player → Mechanics →
拿著這張卡去體驗各種情境，觀察會發生什麼，寫成 3-5 條實驗清單（實際練習場景見
`documents/01d_showroom_and_toybox.md`）。

卡牌分成兩種用途：

- **主限制卡（操作類 5 張、物理類 5 張）**：每人選一張，作為整個遊戲的核心玩法。
- **規則卡（8 張）**：W2 關卡設計時用在第三螢幕「轉」，打破玩家前兩個螢幕建立的習慣。W1 有餘力的學員
  可以先抽一張掛上來試。

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
| 3 | `Mechanic_ChargeJump` | 蓄力青蛙跳 | 操作 | `InputRouter` 高優先攔截跳躍鍵，`force_jump()` |
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
| 16 | `Mechanic_HealthDrain` | 血量流失 | `Stats` 血量持續下降，吃金幣回復 |
| 17 | `Mechanic_FloorIsLava` | 地板是岩漿 | 特定地板接觸 → `take_damage()` |
| 18 | `Mechanic_SwitchWorld` | 開關世界 | 計時切換 group `switch_red` / `switch_blue` 方塊 |

---

## 2. 本規格新增使用的欄位

以下是本規格用到、需要確認地基有沒有的東西。

| 項目 | 用途 | 預設值 | 定義位置 |
|---|---|---|---|
| `ctx.damage_scale` | 彈珠台體質把傷害歸零 | `1.0` | 本規格新增，需加進 `player/MoveContext.gd` |
| `ctx.knockback_scale` | 忽大忽小調整被擊退的程度 | `1.0` | 本規格新增 |
| `ctx.push_scale` | 忽大忽小調整推箱子的力道 | `1.0` | 本規格新增 |
| `ctx.jump_scale` / `ctx.gravity_scale` | 越跑越快、黏黏身體等調整跳躍力／重力 | `1.0` | 地基已實作，沿用 |
| 輸入動作 `move_up` / `move_down` | 後座力上下噴射 | — | 見 `01a_shared_systems.md` §3.1 |
| `Events.mechanic_event(card, event)` | 主限制卡的關鍵瞬間，為 W3 果汁組件預留 | — | 見 `01a_shared_systems.md` §7 |

`kill()` 必須**繞過** `ctx.damage_scale`，直接死亡。

---

## 3. 各卡規格

每張卡的 Inspector **最多 4 個欄位**，全部英文變數名 + 中文 `##` tooltip，全部是拉桿或下拉或勾選。
`enabled` 由基底提供，不需重複宣告。

**`enabled` 必須可以在執行中切換**：關閉時乾淨還原它對 `ctx` 的所有修改、移除它生成的 UI。W2 會用
觸發區在第三螢幕才打開規則卡。

每張主限制卡附一行「事件」，在該瞬間 emit `Events.mechanic_event`。W1 不需要有任何東西訂閱它。

### 主限制卡

#### 1. 煞車失靈 `Mechanic_NoFriction`
```gdscript
## 放開方向鍵後還剩多少摩擦力，0 表示完全不減速
@export_range(0.0, 1.0) var remaining_friction: float = 0.0
```
`apply()`：`ctx.friction_scale = remaining_friction`
事件：`slide_start`（放開按鍵後仍在滑動的第一幀）

#### 2. 只能往前 `Mechanic_AutoRun`
```gdscript
## 遊戲開始時往哪個方向跑
@export_enum("向右", "向左") var start_direction: int = 0
## 撞到牆壁或箱子時要不要自動轉向
@export var turn_at_wall: bool = true
## 轉向後多久內不能再轉向，避免卡在角落抖動
@export_range(0.05, 0.5) var turn_cooldown: float = 0.15
```
設定 `ctx.auto_run_dir`，玩家只能按跳躍。
`turn_at_wall` 開啟時，`is_on_wall()` 且牆面法線與前進方向相反 → 反轉方向，`visual.scale.x` 同步翻轉。
可推箱子也算牆（箱子是轉向工具）。
事件：`wall_turned`

#### 3. 蓄力青蛙跳 `Mechanic_ChargeJump`
```gdscript
## 最多可以蓄力幾秒
@export_range(0.2, 2.0) var max_charge_seconds: float = 1.0
## 完全沒蓄力時，跳躍力是滿力的多少倍
@export_range(0.3, 1.0) var min_jump_ratio: float = 0.4
## 蓄力的時候要不要禁止左右移動
@export var lock_move_while_charging: bool = true
```
用 `InputRouter.bind(self, "jump", ...)` 以較高優先攔截跳躍鍵：按住累積，放開時
`player.force_jump(比例)`，Player 自己的低優先跳躍綁定不會再收到這次按鍵。手感參考 Jump King。
`lock_move_while_charging` 只影響移動，不用 `ctx.input_locked`（那會連跳躍鍵一起鎖住）。
**對外公開 `is_charging: bool`**，停下即死會讀取它（見第 4 節）。
事件：`charge_start`、`charge_release`

#### 4. 只能用滑鼠控制 `Mechanic_Slingshot`
```gdscript
## 拖到最遠時發射的力道上限
@export_range(200.0, 1200.0) var max_launch_force: float = 700.0
## 拖曳超過這個距離，力道就不會再增加
@export_range(50.0, 300.0) var max_drag_distance: float = 150.0
## 開啟後只有站在地面上才能開始拖曳瞄準
@export var ground_only: bool = true
## 拖曳時要不要畫出瞄準線
@export var show_aim_line: bool = true
```
`ctx.input_locked = true`。用 `InputRouter.bind_mouse(self, MOUSE_BUTTON_LEFT, ...)` 以較高優先綁定滑鼠左鍵的
按下／放開（滑鼠是這張卡的核心玩法，沒有讓學員換成別的按鍵的必要），跟其他綁左鍵的組件同時存在時會印衝突警告。按住往後拖，放開時
往拖曳的**反方向** `add_impulse()`，力道 = 拖曳距離比例 × `max_launch_force`。
`ground_only` 開啟時，離地期間無法開始拖曳。
瞄準線由組件自己生成 `Line2D`，學員不用擺。
事件：`launched`

#### 5. 只用後座力移動 `Mechanic_RecoilMove`
```gdscript
## 每次噴射的力道大小
@export_range(100.0, 800.0) var recoil_strength: float = 350.0
## 落地前最多能噴射幾次
@export_range(1, 5) var air_charges: int = 3
## 著地時要不要把噴射次數補滿
@export var refill_on_land: bool = true
## 每次噴射之後，多久才能再噴一次
@export_range(0.1, 1.0) var cooldown: float = 0.3
```
`ctx.input_locked = true`。按下方向鍵（上下左右）→ 往**反方向** `add_impulse()`。
每次噴射消耗一次，`refill_on_land` 開啟時著地即補滿。次數用完時 `visual` 短暫閃灰提示。
**遊玩空間必須夠開闊**，否則這張卡玩不動。
事件：`recoil_fired`、`recoil_empty`

#### 6. 彈珠台體質 `Mechanic_PinballBody`
```gdscript
## 碰到敵人或尖刺時被彈開的力道
@export_range(300.0, 1500.0) var knock_force: float = 800.0
## 碰到敵人時要不要被擊飛
@export var enemy_knocks: bool = true
## 碰到尖刺、岩漿時要不要被擊飛
@export var hazard_knocks: bool = true
## 被擊飛後幾秒內不會被同一次碰撞連續觸發
@export_range(0.1, 1.0) var invincible_seconds: float = 0.3
```
`ctx.damage_scale = 0`。碰到 group `enemy` / `hazard` 時，沿碰撞法線加一點向上偏移
`add_impulse()`。擊飛後的無敵時間避免同一次碰撞連續觸發（見 `01a_shared_systems.md` §2 的
group 定義）。
掉進深坑仍然照常重生。
事件：`knocked`

#### 7. 重力翻轉 `Mechanic_GravityFlip`
```gdscript
## 什麼時候會翻轉重力
@export_enum("按下按鍵", "落地時", "撞牆時") var trigger_timing: int = 0
## 按下按鍵時要按哪一鍵翻轉（只有「觸發時機」選按下按鍵時才會顯示這一欄）
@export var key: Key = KEY_SHIFT
## 翻轉之後多久內不能再翻轉
@export_range(0.1, 1.0) var cooldown: float = 0.3
```
`trigger_timing` 為「按下按鍵」時，用 `InputRouter.bind_input(self, input_type, key, ...)` 綁定學員自選的按鍵（`input_type` 可選滑鼠按鍵，見 `01a_shared_systems.md` §3.1）；
`key` 欄位用 `_validate_property` 依 `trigger_timing` 決定要不要顯示，同 `01c_blocks_and_abilities.md`
的 `KeyTrigger` 手法。呼叫 `player.flip_gravity()`。翻轉時 `visual` 要同步上下翻（`scale.y *= -1`）。
事件：`flipped`

#### 8. 彈性宇宙 `Mechanic_BouncyWorld`
```gdscript
## 碰撞後反彈的速度保留比例，數值越大彈越高
@export_range(0.3, 1.5) var bounciness: float = 0.9
## 站在地板上時要不要也會彈起來
@export var floor_bounces: bool = true
```
碰撞時取法線反彈（`velocity.bounce(normal)`，CharacterBody2D 不吃 PhysicsMaterial）。
**必須設下限**：速度低於閾值就停止彈跳，否則會永遠抖動。
事件：`bounced`

#### 9. 越跑越快 `Mechanic_SpeedRamp`
```gdscript
## 速度最多可以加到原本的幾倍
@export_range(1.0, 5.0) var max_multiplier: float = 3.0
## 從最低速加到最高倍率要花幾秒
@export_range(1.0, 20.0) var ramp_seconds: float = 10.0
## 目前的速度倍率會讓跳躍力增加多少，0 表示跳躍不受影響
@export_range(0.0, 1.0) var speed_affects_jump: float = 0.5
## 停下來時倍率要不要歸零重新累積
@export var reset_on_stop: bool = true
```
持續移動時倍率累加，`ctx.speed_scale = 當前倍率`。
`ctx.jump_scale = 1 + (當前倍率 - 1) × speed_affects_jump`，設為 0 時跳躍不受影響。
`reset_on_stop` 開啟時，水平速度接近 0 即歸零。
事件：`speed_max`（第一次達到最高倍率）、`speed_reset`

#### 10. 忽大忽小 `Mechanic_SizeShift`
```gdscript
## 什麼時候切換大小
@export_enum("按下按鍵", "隨時間") var trigger_timing: int = 0
## 按下按鍵時要按哪一鍵切換（只有「觸發時機」選按下按鍵時才會顯示這一欄）
@export var key: Key = KEY_SHIFT
## 變小時的體型倍率
@export_range(0.3, 1.0) var small_scale: float = 0.5
## 變大時的體型倍率
@export_range(1.0, 2.5) var big_scale: float = 1.8
## 體型是否連動推力、擊退、跳躍力
@export var size_affects_stats: bool = true
```
`trigger_timing` 為「按下按鍵」時用 `InputRouter.bind_input(self, input_type, key, ...)` 綁定學員自選的按鍵，
`key` 欄位同重力翻轉卡用 `_validate_property` 依 `trigger_timing` 決定要不要顯示；「隨時間」則每 3 秒
自動切換，不顯示 `key`。**這張卡「按下按鍵」模式下同時顯示 5 個欄位（超出其餘卡片的 4 欄慣例）**，
是本規格唯一的例外，因為要同時保留既有的雙觸發模式與可自訂按鍵，兩者都不宜拿掉。
呼叫 `player.set_size_factor()`。**必須改 CollisionShape2D 的尺寸，不要縮放整個物理節點**；
變大時若會與地形重疊，延後到空間足夠時才套用。

`size_affects_stats` 開啟時：

- 大隻：`ctx.push_scale` 提高（推得動箱子）、`ctx.knockback_scale` 降低、`ctx.jump_scale` 降低
- 小隻：`ctx.jump_scale` 提高、`ctx.knockback_scale` 提高（容易被敵人撞飛）

事件：`grew`、`shrank`

### 規則卡

#### 11. 黏黏身體 `Mechanic_StickyBody`
```gdscript
## 最多可以黏著幾秒，0 表示不限時間
@export_range(0.0, 5.0) var max_stick_seconds: float = 0.0
## 按跳躍脫離黏著時的力道
@export_range(200.0, 1000.0) var release_force: float = 500.0
## 天花板要不要也能黏住
@export var ceiling_sticks: bool = true
```
碰到任何表面 → 記下法線、速度歸零、`ctx.gravity_scale = 0`、`ctx.input_locked = true`。
按跳躍 → 往法線方向加一點向上偏移 `add_impulse()`，並給 0.2 秒不可再黏的冷卻。
`max_stick_seconds` 為 0 代表不限；逾時自動脫落。
黏在移動平台上時要跟著平台移動（記錄碰撞物與相對位置）。

#### 12. 移動會扣血 `Mechanic_Stamina`
```gdscript
## 體力可以支撐移動幾秒
@export_range(1.0, 10.0) var stamina_seconds: float = 3.0
## 停下來時體力回復的速度倍率
@export_range(0.5, 3.0) var regen_rate: float = 1.0
## 體力耗盡時的懲罰方式
@export_enum("走不動", "變很慢") var penalty_mode: int = 0
## 要不要在畫面上顯示體力條
@export var show_stamina_bar: bool = true
```
以水平速度判斷是否在移動（而不是讀輸入），這樣搭配任何主限制卡都成立。
移動時扣體力，停下時回復。耗盡時 `ctx.speed_scale` 降到 0 或 0.3，回復到 30% 才解除。
體力條由組件自己生成 `CanvasLayer`。

#### 13. 碰觸即死 `Mechanic_TouchDeath`
```gdscript
## 碰到 group enemy 的物件會不會死
@export var die_on_enemy: bool = true
## 碰到 group box 的物件會不會死
@export var die_on_box: bool = true
## 碰到 group wall 的物件會不會死
@export var die_on_wall: bool = false
```
用 group 判定（`enemy` / `box` / `wall`，定義見 `01a_shared_systems.md` §2），不綁特定物件。
`hazard` 一律致死。
直接呼叫 `kill()`，因此不受彈珠台體質的傷害歸零影響。

#### 14. 存活計時 `Mechanic_SurvivalTimer`
```gdscript
## 存活幾秒後算過關
@export_range(5.0, 60.0) var target_seconds: float = 10.0
## 要不要在畫面上顯示倒數計時
@export var show_timer: bool = true
```
達標 emit `Events.level_cleared`。計時器 UI 由組件自己生成 `CanvasLayer`，學員不用擺。

#### 15. 停下即死 `Mechanic_StopDeath`
```gdscript
## 最多可以靜止不動幾秒
@export_range(0.5, 5.0) var max_idle_seconds: float = 1.5
## 超過時間之後的懲罰方式
@export_enum("直接死亡", "持續扣血") var penalty_mode: int = 0
## 快要超過時間時角色要不要閃紅警告
@export var show_warning: bool = true
```
`show_warning` 開啟時，接近逾時讓 `visual` 閃紅。
同一個 Player 上有蓄力青蛙跳且 `is_charging == true` 時，暫停計時。

#### 16. 血量流失 `Mechanic_HealthDrain`
```gdscript
## 每秒自動扣多少血
@export_range(0.5, 10.0) var damage_per_second: float = 1.0
## 撿到一枚金幣補多少血
@export_range(0.5, 10.0) var heal_per_coin: float = 2.0
## 要不要在畫面上顯示血條
@export var show_health_bar: bool = true
```
持續呼叫 `player.take_damage(damage_per_second * delta)`，血量走 `01a_shared_systems.md` §4.5
的 `Stats` 流程，本卡**不自帶血量上限**（血量上限由場景的 `ValueSettings` 設定）。
歸零時走既有的 `kill()` 流程。
碰到 group `coin` 的物件時補血（若地基已有 `Events.item_collected` 則直接訂閱）。

#### 17. 地板是岩漿 `Mechanic_FloorIsLava`
```gdscript
## 站在扣血地板上時每秒扣多少血
@export_range(0.5, 10.0) var damage_per_second: float = 2.0
## 扣血地板的判定範圍
@export_enum("只有岩漿地板", "所有地板") var scope: int = 0
## 要不要在畫面上顯示血條
@export var show_health_bar: bool = true
```
- `只有岩漿地板`：接觸 group `lava` 的地形才扣血。
- `所有地板`：站在任何地面上都扣血，group `safe` 的平台除外。

同樣透過 `player.take_damage()` 走 `Stats` 的血量，**不自帶血量上限**。

#### 18. 開關世界 `Mechanic_SwitchWorld`
```gdscript
## 紅藍方塊多久切換一次
@export_range(0.5, 5.0) var switch_seconds: float = 2.0
## 遊戲開始時哪個顏色是實體
@export_enum("紅色先", "藍色先") var start_color: int = 0
## 切換前方塊要不要先閃爍提示
@export var blink_before_switch: bool = true
```
控制場景中所有 `blocks/SwitchBlock.tscn`（Inspector 用下拉選紅或藍，自動加入 group `switch_red` /
`switch_blue`，見 `01c_blocks_and_abilities.md`）。
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

規格與正式卡相同（繼承 `MechanicBase`、中文 tooltip、英文變數名、最多 4 欄）。

---

## 6. 驗收條件

- [ ] 18 張卡各自單獨掛上，跑滿 60 幀不報錯（煙霧測試會自動掃 `mechanics/` 底下所有 `.tscn`）
- [ ] 任選 1 張主限制卡 + 1 張規則卡同時掛上，遊戲不崩潰
- [ ] 第 4 節的衝突組合：自動處理的有正確行為，需要警告的有中文警告
- [ ] 每張卡的 `enabled` 在執行中關閉，`ctx` 完全還原、生成的 UI 被移除
- [ ] 每張卡的 Inspector 都是英文變數名 + 中文 tooltip、都不需要打字、欄位不超過 4 個（忽大忽小在
      「按下按鍵」模式下例外為 5 個，見該卡規格）
- [ ] 把任一張卡拖到錯誤位置，輸出面板有中文警告
- [ ] 彈性宇宙不會無限抖動；忽大忽小不會把角色卡進地形；開關世界不會把角色卡進方塊
- [ ] 黏黏身體黏在移動平台上會跟著移動
- [ ] 主限制卡在指定瞬間 emit `Events.mechanic_event`
- [ ] 血量流失、地板是岩漿正確讀寫 `Stats` 的血量，不自帶「總血量」欄位
- [ ] 蓄力青蛙跳只攔截跳躍鍵、不影響移動（除非 `lock_move_while_charging` 開啟）
- [ ] 重力翻轉、忽大忽小在「按下按鍵」模式下，`key` 欄位可以正常切換按鍵並生效；改成其他觸發時機時
      `key` 欄位正確隱藏
- [ ] 整包能成功 Web export
- [ ] 每張主限制卡至少能跟三個以上不同情境產生可觀察的不同結果 —— **實際練習場景待
      `01d_showroom_and_toybox.md` 的 Gym/Showroom 定位討論後才能定出具體驗收方式，此項暫列為待驗證**

---

## 7. 待討論

（本規格未新增獨立的待討論項目；跟卡牌相關的開放問題已併入第 6 節最後一條，實際場景定位見
`01d_showroom_and_toybox.md` 的待討論清單。）
