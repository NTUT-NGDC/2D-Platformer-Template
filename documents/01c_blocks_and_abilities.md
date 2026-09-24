# 01c — W1：零件與攻擊能力

> 前置閱讀：`CLAUDE.md`、`documents/00_foundation.md`、`documents/01a_shared_systems.md`

這份規格定義 `blocks/`（互動零件）與 `abilities/`（攻擊能力）。零件跟機制卡不同——零件透過訊號連接
組合出關卡玩法，機制卡規格見 `documents/01b_mechanic_cards.md`。

---

## 1. 設計原則

- **零件是組合出來的**：每個零件在程式內部都是「身體 × 觸發 × 效果」的一組預設。組合只存在程式內部，
  學員永遠只看到包裝好的零件。
- **每個零件最多 4 個欄位**：同機制卡規則。變數名用簡單英文，每個欄位附中文 tooltip（`##` 文件註解），
  下拉選項用中文。
- **傳送門配對不算連動**：傳送門用節點欄位指定另一座，屬於設定而非函式呼叫，不算 `01a_shared_systems.md`
  §6 的訊號連接。
- **外觀交給 Modulate**：零件不額外提供顏色欄位。學員要把尖刺變成「熱平底鍋」，直接改 Visual 的
  `Modulate`（顏色選擇器，不用打字）。
- **死亡不重新載入場景**：有實體狀態的零件（箱子、敵人、道具、可破壞方塊、崩塌地板、移動平台位置、
  鑰匙／金幣門）各自實作 `reset()`，由 `RespawnHandler` 在重生時呼叫；被打倒、被撿走改成藏起來，不刪除節點。
  訊號控制的開關狀態（按鈕、訊號門、風扇與平台的啟動開關）不重置。見 `00b_rooms_and_soft_respawn.md` §8。

零件之間怎麼用訊號連動、`Receiver` / `Hittable` 介面長怎樣、連線驗證器與視覺化怎麼運作，見
`01a_shared_systems.md` §6。

---

## 2. 零件清單 `blocks/`

全部為預製體，拖進場景即可使用。欄位名稱後的括號為中文 tooltip。

### 2.1 觸發類

| 零件 | 檔名 | 身體 | 欄位 | 訊號 |
|---|---|---|---|---|
| 按鈕 | `Button.tscn` | 感應 | `mode`（踩住才開／踩一下切換／踩一下永久開／被攻擊觸發）、`pressed_by`（玩家與箱子／只有玩家／只有箱子） | `turned_on`、`turned_off` |
| 按鍵觸發器 | `KeyTrigger.tscn` | 無 | `key_source`（自訂按鍵／滑鼠左鍵／滑鼠右鍵／滑鼠中鍵／跟基本操作同一顆鍵）、`key` 或 `action`（依來源顯示其一，選滑鼠按鍵時都不顯示）、`trigger`（按下時／放開時／按住時（每一幀）） | `triggered`（學員用）；進階：`pressed`、`released`、`hold_started`、`hold_ended`、`held(seconds)` |
| 傳送門 | `Portal.tscn` | 感應 | `pair`（另一座傳送門）、`keep_velocity`（保留速度，預設開）、`allow_boxes`（箱子也能傳） | `teleported` |
| 重生點 | `Checkpoint.tscn` | 感應 | 無 | `reached` |
| 終點 | `Goal.tscn` | 感應 | 無 | `reached` |

- 按鈕的 `turned_on` / `turned_off` 依模式決定：踩住才開為壓下／離開；切換為每踩一次交替；永久為只發一次 `turned_on`。
- 按鍵觸發器的 `action` 與 `key` 用 `_validate_property` 依 `key_source` 顯示其中一個；選滑鼠按鍵時兩個都隱藏，改用 `InputRouter.bind_student_mouse()`。
- 傳送門：A 指定 B 後，B 自動連回 A；傳送後 0.3 秒內不會再次觸發，避免來回彈。
- 終點 emit `Events.level_cleared`。W1 玩具箱不使用。

### 2.2 接收類

| 零件 | 檔名 | 身體 | 欄位 | 可連接的函式 | 訊號 |
|---|---|---|---|---|---|
| 門 | `Door.tscn` | 實心 | `open_mode`（由訊號控制／鑰匙／金幣數量）、`required_amount`（需要數量）、`consume`（打開時消耗）、`start_open`（一開始是開的） | `activate`、`deactivate`、`toggle` | `opened`、`closed` |
| 移動平台 | `MovingPlatform.tscn` | 會動 | `direction`（水平／垂直）、`distance_tiles`（移動格數）、`speed`（速度）、`start_active`（一開始就在動） | `activate`、`deactivate`、`toggle` | 無 |
| 風扇 | `Fan.tscn` | 感應 | `direction`（上／下／左／右）、`force`（力道）、`range_tiles`（範圍格數）、`start_on`（一開始就開） | `activate`、`deactivate`、`toggle` | 無 |

- 門開啟時關閉碰撞、變半透明。鑰匙與金幣模式由玩家碰到門時檢查 `Stats`（見 `01a_shared_systems.md` §4）。
- 移動平台 `activate` 為開始移動、`deactivate` 為停在原地；按鈕加移動平台即為電梯。

### 2.3 地形類

| 零件 | 檔名 | 身體 | 欄位 | 訊號 |
|---|---|---|---|---|
| 崩塌地板 | `CrumbleFloor.tscn` | 實心 | `break_delay`（碎裂延遲秒數）、`respawn_time`（重生秒數，0 為不重生）、`triggered_by`（只有玩家／任何物體） | `crumbled` |
| 單向平台 | `OneWayPlatform.tscn` | 實心（單向） | `width_tiles`（寬度格數） | 無 |
| 岩漿 | `Lava.tscn` | 實心 | `damage_per_second`（每秒扣血）、`instant_kill`（即死） | 無 |
| 可破壞方塊 | `Breakable.tscn` | 實心 | `durability`（耐久次數）、`respawn_time`（重生秒數，0 為不重生）、`break_by_impact`（高速撞擊也能破壞）、`impact_speed`（撞擊速度門檻） | `broken` |
| 開關方塊 | `SwitchBlock.tscn` | 實心 | `color`（紅／藍） | 無 |

- 崩塌地板碎裂前要有抖動提示。
- 岩漿屬於 group `hazard` 與 `lava`（見 `01a_shared_systems.md` §2），站在上面持續扣血。
- 可破壞方塊實作受擊介面（`Hittable`）；`break_by_impact` 讓越跑越快、彈弓、後座力、彈珠台擊飛、
  落下的箱子都能撞破。
- 開關方塊由規則卡「開關世界」控制，規格見 `01b_mechanic_cards.md` #18。

### 2.4 物件類

| 零件 | 檔名 | 身體 | 欄位 | 訊號 |
|---|---|---|---|---|
| 箱子 | `Box.tscn` | 會動 | `weight`（輕／重） | 無 |
| 道具 | `Pickup.tscn` | 感應 | `kind`（金幣／鑰匙／血包／分數）、`amount`（數量） | `collected` |
| 彈射台 | `Launcher.tscn` | 實心 | `mode`（彈簧／彈跳床）、`direction`（上／左／右）、`force`（力道） | `launched` |
| 尖刺 | `Spike.tscn` | 感應 | `penalty`（扣血／即死）、`damage`（扣血量） | 無 |
| 笨敵人 | `Enemy.tscn` | 會動 | `speed`（速度）、`health`（血量）、`damage`（傷害）、`turn_at_ledge`（走到邊緣會轉身） | `defeated` |

- 箱子實作受擊介面，被攻擊時只受擊退。
- 道具：血包加血量，但不超過上限。
- 彈射台：彈簧為固定力道；彈跳床為反彈落下速度，掉越高彈越高。
- 笨敵人撞牆轉身，實作受擊介面，血量歸零後消失（重生時照常復活）。
- `collected`、`broken`、`defeated` 讓學員可以做出「打倒敵人就開門」「撿到道具就啟動平台」這類組合。

---

## 3. 攻擊能力 `abilities/`

不在卡池內，所有學員可自由使用。掛在 Player → `Abilities`（Player 節點結構新增的空節點，跟
`Mechanics`／`Juice` 平行，比照 `00_foundation.md` §3.1 的零連線發現機制註冊）。

| 能力 | 檔名 | 欄位 |
|---|---|---|
| 近戰 | `Ability_Melee.tscn` | `input_type`（鍵盤／滑鼠按鍵）、`key`（攻擊鍵，選鍵盤時才顯示）、`cooldown`（冷卻秒數）、`knockback`（擊退力道）、`damage`（傷害） |
| 遠程 | `Ability_Ranged.tscn` | `input_type`（鍵盤／滑鼠按鍵）、`key`（攻擊鍵，選鍵盤時才顯示）、`bullet_speed`（子彈速度）、`cooldown`（冷卻秒數）、`lifetime`（存在秒數）、`max_range_tiles`（最大飛行格數，0 不限制）、`use_gravity`（受重力影響）、`aim_at_mouse`（朝滑鼠游標射） |

不預先註冊共用的攻擊動作，`key: Key` 由學員在能力自己的 Inspector 選，透過
`InputRouter.bind_input(self, input_type, key, ...)` 綁定，`input_type` 可改選滑鼠左鍵／右鍵／中鍵（見 `01a_shared_systems.md` §3）。能力不算第 1 節「零件」，
不受「每個零件最多 4 個欄位」限制，5 個欄位是可接受的。

近戰的攻擊判定區跟遠程的子彈一樣是預製場景：`abilities/MeleeHitbox.tscn`（Area2D + CollisionShape2D + Visual），
畫成往右延伸，攻擊時由 `Ability_Melee` 生成、往左攻擊時 `scale.x = -1` 左右翻轉。攻擊範圍的大小與外觀
直接改這個場景，Inspector 不提供範圍拉桿。

- 近戰：按下 `key` 時在面向方向短暫生成判定區。
- 遠程：按下 `key` 時朝面向方向發射子彈，撞到地形或受擊物件即消失。
- 打到實作受擊介面（`Hittable`）的東西時呼叫 `take_hit()`。
- 拖到錯誤位置時印中文警告，規則同機制卡。

---

## 4. 驗收條件

- [ ] `blocks/` 底下每個零件單獨拖進場景即可用，不用連線、不用填節點路徑
- [ ] 門、移動平台、風扇正確實作 `Receiver`（`activate`/`deactivate`/`toggle`），按鈕能透過訊號連接
      控制它們
- [ ] 可破壞方塊、笨敵人、按鈕（被攻擊觸發模式）、箱子正確實作 `Hittable`
- [ ] 崩塌地板碎裂前有抖動提示，`respawn_time` 為 0 時不重生
- [ ] 開關方塊在玩家重疊時延後實體化，不會把玩家卡進方塊
- [ ] 傳送門配對正確（A 指定 B 後 B 自動連回 A），傳送後 0.3 秒內不重複觸發
- [ ] 近戰、遠程能力打中 `Hittable` 物件時正確呼叫 `take_hit()`
- [ ] 把任一個零件或能力拖到錯誤位置，輸出面板有中文警告
- [ ] 任意零件與任意機制卡同時存在時不崩潰、不卡死；拔掉任一個零件遊戲仍能跑
- [ ] 煙霧測試涵蓋 `blocks/` 與 `abilities/` 底下所有 `.tscn`

---

## 5. 待討論

- [ ] 格子大小與角色尺寸（依 W4 素材包決定，會影響 `width_tiles`／`distance_tiles`／`range_tiles`
      等以「格」為單位的欄位怎麼定）
- [ ] 笨敵人是否可以被踩死
- [ ] 可破壞方塊的 `break_by_impact` 預設開或關
- [ ] 遠程攻擊是否只朝面向方向，或允許上下
