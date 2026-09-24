# 01a — W1：共用系統

> 前置閱讀：`CLAUDE.md`、`documents/00_foundation.md`
> 這份規格定義 W1 用到的共用系統：輸入路由、數值、死亡與重生、訊號連接。
> `01b_mechanic_cards.md`、`01c_blocks_and_abilities.md`、`01d_showroom_and_toybox.md` 都依賴這裡的定義，
> 要先看這份再看其他三份。

---

## 1. 設計原則補充

- **零件之間統一用 Godot 訊號連動**：學員透過「節點」面板的訊號對話框，把零件的訊號連到其他零件或
  `_my/` 腳本裡的函式。這是 `CLAUDE.md` 零連線原則的**唯一例外**；機制卡、能力一律維持零連線，不受
  這條影響。

---

## 2. 碰撞圖層與 group

機制卡、零件都依照這套判斷，做任何組件之前先定義好。

| 圖層 | 內容 |
|---|---|
| 1 玩家 | Player |
| 2 地形 | TileMap、門、崩塌地板、岩漿、單向平台、移動平台、可破壞方塊、彈射台、開關方塊 |
| 3 箱子 | 可推箱子 |
| 4 敵人 | 笨敵人 |
| 5 感應 | 道具、傳送門、重生點、風扇、終點、按鈕、尖刺判定區 |
| 6 攻擊 | 近戰判定、子彈 |

| group | 誰屬於 | 誰會讀 |
|---|---|---|
| `enemy` | 笨敵人 | 彈珠台體質、碰觸即死 |
| `hazard` | 尖刺、岩漿 | 彈珠台體質、碰觸即死 |
| `box` | 箱子 | 碰觸即死、只能往前 |
| `wall` | 地形的垂直面 | 碰觸即死（選項） |
| `lava` | 岩漿 | 地板是岩漿 |
| `safe` | 標記為安全的平台 | 地板是岩漿（所有地板模式） |
| `signal_source` | 所有會發出訊號給學員連接的零件（自動加入） | 連線驗證器、連線視覺化 |

**感應類零件永遠不算「碰到東西」**：碰觸即死、彈性宇宙、黏黏身體都不對圖層 5 反應。

---

## 3. 輸入路由 `InputRouter`（自動載入）

### 3.1 預先定義的輸入動作

學員不修改 Input Map，只保留最基本、所有卡牌都可能用到的動作，其餘一律不預先註冊，改由各機制卡／
能力自己的 `key: Key` 欄位讓學員自訂（見第 3.2 節），或走 `KeyTrigger` 的零連線訊號（見
`01c_blocks_and_abilities.md`）。

| 動作 | 按鍵 | 用途 |
|---|---|---|
| `move_left` / `move_right` | A、D、← → | 左右移動 |
| `move_up` / `move_down` | W、S、↑ ↓ | 後座力上下噴射 |
| `jump` | Space | 跳躍 |
| `restart` | R | 保留給之後的週次（目前沒有組件使用；不重新載入場景，見 00b） |

現有 `project.godot` 的 `interact`（E 鍵）動作棄用：之後的互動一律改由 `KeyTrigger` 或零件訊號連接
取代，需要從 Input Map 移除。

**鏡頭平移不在這份規格內**：之後會搭配關卡切換另外設計，目前不預留 Input Map 動作，也不是
`InputRouter` 要處理的事。

需要固定觸發鍵、但不是給學員自訂按鍵觸發器用的情境（例如重力翻轉、忽大忽小、近戰、遠程），做法是
該機制卡／能力自己宣告一個 `@export var key: Key` 欄位（見第 3.2 節同一套下拉選單機制），學員在該卡
自己的 Inspector 裡挑鍵，不再透過共用的 Input Map 動作名稱。具體規格見 `01b_mechanic_cards.md`、
`01c_blocks_and_abilities.md` 對應卡片／能力。

這些卡片／能力的 `key` 欄位上方另外有一個「按鍵種類」下拉選單
`@export_enum("鍵盤按鍵", "滑鼠左鍵", "滑鼠右鍵", "滑鼠中鍵") var input_type`，選滑鼠按鍵時 `key` 隱藏；
綁定一律呼叫 `InputRouter.bind_input(self, input_type, key, ...)`，由 Router 決定走 `bind_key()` 或 `bind_mouse()`。

### 3.2 自訂按鍵

按鍵觸發器可以不用預設動作，改由學員自己選按鍵：

- 匯出 `@export var key: Key` 欄位，學員從 Inspector 下拉選單選擇按鍵名稱。**不是即時錄製**：
  Godot 4.7.2 的 Inspector 對 `@export` 欄位沒有原生的按鍵錄製互動，錄製對話框只存在於專案設定的
  Input Map 分頁；要在 Inspector 做到錄製需自製 `EditorProperty`，成本不划算。改用 `Key` enum 下拉
  選單，一樣零打字、確定可行。
- 元件在執行時自行向 `InputMap` 註冊臨時動作，**不修改專案設定**。
- 選到 Ctrl、Tab、F 鍵、Esc 時印中文警告（網頁版會觸發瀏覽器行為）。

### 3.3 三個時機

| 時機 | 觸發頻率 | 傳入參數 |
|---|---|---|
| 按下 `pressed` | 按下的那一幀一次 | 無 |
| 按住 `held` | 按著的每一個物理幀 | 已按住秒數 |
| 放開 `released` | 放開的那一幀一次 | 總共按住秒數 |

### 3.4 程式層註冊與攔截

給機制卡、能力、備品庫與資工生使用：

```gdscript
## 用動作名稱綁定；priority 越大越先收到
InputRouter.bind(owner: Node, action: StringName, phase: int, callback: Callable, priority: int = 0)
## 直接用按鍵綁定
InputRouter.bind_key(owner: Node, key: Key, phase: int, callback: Callable, priority: int = 0)
## 直接用滑鼠按鍵綁定（MOUSE_BUTTON_LEFT / RIGHT / MIDDLE）
InputRouter.bind_mouse(owner: Node, button: MouseButton, phase: int, callback: Callable, priority: int = 0)
## 依「按鍵種類」下拉選單綁定：input_type 0 用 key，1~3 是滑鼠左鍵／右鍵／中鍵
InputRouter.bind_input(owner: Node, input_type: int, key: Key, phase: int, callback: Callable, priority: int = 0)
```

學員按鍵觸發器對應的只聽不搶版本是 `bind_student()`／`bind_student_key()`／`bind_student_mouse()`（見 §3.5）。
滑鼠按鍵跟鍵盤按鍵走同一套優先權與衝突警告。

- 函式回傳 `true` 代表「這個輸入我處理掉了」，更低優先的綁定不會收到。
- Player 的基本移動與跳躍用低優先註冊。蓄力青蛙跳、後座力、彈弓用較高優先攔截，不需要各自寫攔截邏輯
  （見 `01b_mechanic_cards.md` 蓄力青蛙跳的規格）。

### 3.5 學員的按鍵只聽不搶

任何學員自己擺的按鍵觸發器（含 `01d_showroom_and_toybox.md` 的 `MyControls` 底下那些）在路由中
**永遠是最低優先、且不能攔截**。學員即使把觸發器綁在 Space 上，跳躍仍然照常運作。

### 3.6 安全機制

- **自動解除**：`owner` 離開場景樹，或其 `啟用` 被關閉時，自動解除它的所有綁定。
- **衝突警告**：比對實體按鍵而非只比對動作名稱。兩個會攔截輸入的組件綁到同一個按鍵與時機，或學員
  選的按鍵與自己的卡牌、能力重疊時，印中文警告。
- **暫停派發**：玩家死亡到重生之間不派發任何輸入。

---

## 4. 數值系統 `Stats`（自動載入）

### 4.1 數值種類

種類名稱由學員自訂，是一個字串（例如「金幣」「鑰匙」「血量」「分數」，或學員自己取的任何名稱），
不是固定的下拉選單。這是 `CLAUDE.md` 鐵律 4「零打字」在這裡的唯一例外，理由跟防呆機制見
`CLAUDE.md` 該條的例外說明。

`血量`（`Stats.HEALTH_KIND` 常數）是唯一有系統行為綁在名稱上的種類：歸零時觸發玩家死亡（見
4.5 節）。其他名稱純粹是學員自己的分類，系統不理解它們的意義。

**打錯字防呆**：`Stats` 在種類名稱第一次出現時，會跟所有已經用過的名稱比對編輯距離，太像但不
完全一樣（例如「金幣」跟「金幤」）就 `push_warning()` 印中文警告，提醒可能打錯字，但不會阻擋
執行——打錯字的那個名稱一樣會被當成一個新的獨立種類記錄下來。

### 4.2 程式介面

```gdscript
Stats.add(kind: String, amount: int)             ## 增加（負數即減少）
Stats.get_value(kind: String) -> int             ## 查詢
Stats.has_at_least(kind: String, n: int) -> bool ## 是否達標
Stats.consume(kind: String, n: int) -> bool      ## 足夠就扣掉並回傳 true
signal value_changed(kind: String, old_value: int, new_value: int)
```

所有變動同步 emit `Events.value_changed`，供 W3 果汁組件訂閱。

### 4.3 場景設定節點 `ValueSettings`

每個場景可以放一個或多個，沒放就用預設值。每一筆設定對應一個數值種類，欄位：

| 欄位 | 說明 |
|---|---|
| `kind` | 種類名稱（字串，學員自己打；打字防呆見 4.1） |
| `start_value` | 初始值 |
| `max_value` | 上限（0 為不限） |
| `show_in_hud` | 是否顯示在 HUD |

預設（沒有任何 `ValueSettings` 時）：`血量` 初始 3、上限 3；其他種類第一次用到時初始 0、不限。

### 4.4 HUD

- 由另一個自動載入 `StatsHud` 訂閱 `Stats.value_changed` 自動生成 `CanvasLayer`，學員不用擺 UI；
  `Stats` 本身只管數值，不知道也不在意畫面有沒有人在監聽，兩者分開避免混在一起。
- 某個數值第一次在場景中被用到時才出現。
- 血量顯示為血條，其他顯示為圖示加數字。

### 4.5 血量與傷害

- `Player.take_damage(amount: float = 1.0)` 對外簽名不變，機制卡呼叫端不用改。內部改為呼叫
  `Stats.add(Stats.HEALTH_KIND, -amount)`，`ctx.damage_scale` 在呼叫前於 Player 內部生效。
- 血量歸零時由 `Stats` 呼叫 `player.kill()`。
- `kill()` 繞過血量與 `damage_scale`，直接死亡。

---

## 5. 死亡與重生

> 已改成**軟重生**：死亡不重新載入場景。完整規格見 `00b_rooms_and_soft_respawn.md`，這裡只列摘要。

### 5.1 流程

- `Player.kill()` 只宣告死亡（`Events.player_died`），關卡裡的 `RespawnHandler` 聽到後等 `delay` 秒，
  復位零件、退回數值，再呼叫 `player.revive(位置)`。
- 預設「回到目前房間」：只復位目前房間的零件，重生在同房間踩過的重生點，沒有就用房間的重生點。
- 「整關重來」：所有零件復位、數值退回最一開始、清空重生點，玩家回到一開始的位置。
- 場景裡沒有 `Room` 時，整個關卡當成一個房間；重生在踩過的重生點，沒踩過就在一開始的位置。

### 5.2 重生記憶 `RespawnMemory`（自動載入）

| 記錄內容 | 什麼時候記 | 重生時 |
|---|---|---|
| 血量以外、`reset_on_death` 開著的數值 | 進入房間的那一刻（沒有房間時：踩到重生點的那一刻） | 退回記錄當下 |
| 最後踩到的重生點位置 | 踩到重生點 | 同一個房間內才用它當重生位置 |

- **血量永遠補滿**（由 `Player.revive()` 呼叫 `Stats.refill`），避免低血量重生後立刻死亡的無限循環。
- 零件自己的狀態不記錄：有狀態的零件各自實作 `reset()`，由 `RespawnHandler` 呼叫（見 00b §8）。
  按鈕、訊號門等「由訊號控制的開關狀態」不重置，死掉也維持原狀。

### 5.3 清空時機

到達終點、選「整關重來」死亡、重新按下播放時，清空全部記錄。

---

## 6. 訊號連接機制

### 6.1 流程

1. 在場景樹選擇會發出訊號的零件（例如按鈕）。
2. 打開「節點」面板的「訊號」分頁，雙擊要用的訊號（例如 `turned_on`）。
3. 在對話框中選擇目標節點與函式（例如門的 `activate`）。

### 6.2 訊號設計原則

- **給學員連接的訊號一律不帶參數**，避免與目標函式的參數數量對不上。
- 帶參數的訊號（例如按住秒數）只給會寫程式的人用，命名上明確區分。
- 所有會發出訊號的零件自動加入 group `signal_source`。

### 6.3 接收函式（接收介面 `Receiver`）

門、移動平台、風扇等零件實作。每個零件把給學員連接的函式寫在腳本最上方，附一行中文註解。

```gdscript
## 開啟
func activate() -> void
## 關閉
func deactivate() -> void
## 切換
func toggle() -> void
```

### 6.4 受擊介面 `Hittable`

可破壞方塊、笨敵人、按鈕（被攻擊觸發模式）、箱子等零件實作。

```gdscript
## 被攻擊打到
func take_hit(damage: int, knockback: Vector2, source: Node) -> void
```

打中時 emit `Events.hit(target, source)`，供 W3 的頓幀與震動訂閱。

### 6.5 連線驗證器

遊戲開始時掃描所有 `signal_source` 零件與 `MyControls` 的訊號連接，以中文警告回報：

- 連到的函式不存在（改名或打錯）
- 參數數量對不上
- 目標節點已被刪除
- 連到危險的內建函式（例如 `queue_free`、`free`、`set_script`），給溫和提醒

Godot 的訊號對話框本身只能部分過濾（Method 下拉主要列腳本自訂函式，但仍允許手動輸入任意方法名，
不保證擋掉內建方法），所以連線驗證器是**必要的**第二道防線，不能只靠對話框把關。

### 6.6 連線視覺化

`signal_source` 零件使用 `@tool` 腳本，在編輯畫面中讀取自己的訊號連接清單，畫一條虛線到每個目標節點。
連接到 `MyControls` 腳本的函式時，虛線畫到 `MyControls`。

---

## 7. 新增事件一覽

| 事件 | 發出者 | 用途 |
|---|---|---|
| `Events.value_changed(kind, old, new)` | Stats | HUD、W3 果汁 |
| `Events.hit(target, source)` | 受擊介面 | W3 頓幀、震動 |
| `Events.player_died` | Player | 重生處理者（`RespawnHandler`） |
| `Events.room_entered(room)` | 房間 | 鏡頭瞬切、重生處理者、重生記憶（見 00b） |
| `Events.respawn_requested(player)` | 重生處理者 | 重生前一刻，給想在重生時做事的組件聽 |
| `Events.player_respawned(player)` | Player | `revive()` 完成後 |
| `Events.checkpoint_reached(checkpoint)` | 重生點 | 重生記憶 |
| `Events.level_cleared` | 終點、存活計時 | 既有 |
| `Events.mechanic_event(card, event)` | 主限制卡 | 既有（見 `01b_mechanic_cards.md`） |

`Events` 是系統之間的溝通管道；第 6 節各零件的訊號是給學員連接用的，兩者分開。

---

## 8. 驗收條件

- [ ] `InputRouter.bind()` / `bind_key()` 的優先權攔截正確運作：高優先綁定回傳 `true` 後，低優先
      綁定收不到同一次輸入
- [ ] 任何學員自己擺的按鍵觸發器（含 `MyControls` 底下的）即使綁在 `jump` 上，Player 的跳躍仍正常
      運作，證明「只聽不搶」生效
- [ ] `owner` 離開場景樹或 `啟用` 關閉時，它在 `InputRouter` 的綁定會自動解除
- [ ] 兩個攔截輸入的組件綁到同一個按鍵與時機時，輸出面板出現中文警告
- [ ] `Stats.add` / `get_value` / `has_at_least` / `consume` 行為正確，`value_changed` 正確 emit
      並同步 `Events.value_changed`
- [ ] 某數值第一次被用到時，對應的 HUD 元件才出現
- [ ] `Player.take_damage()` 對外簽名不變，內部正確委派給 `Stats.add(Stats.HEALTH_KIND, -amount)`；
      血量歸零時 `Stats` 呼叫 `kill()`；`kill()` 繞過 `damage_scale`
- [ ] 數值種類名稱打錯字（跟已用過的名稱編輯距離很近但不同）時，輸出面板／偵錯器出現中文警告，
      但不會擋住執行
- [ ] 死亡後軟重生（不重新載入場景）：重生在正確位置，第 5.2 節表格列出的數值正確退回，目前房間的零件
      正確復位，血量永遠補滿（細節見 `00b_rooms_and_soft_respawn.md` §9）
- [ ] `signal_source` group 由對應零件自動加入，學員不用手動設定
- [ ] 連線驗證器能抓出：函式不存在、參數數量不對、目標節點已刪除、連到危險內建函式（給溫和提醒）
      四種情況，並印中文警告
- [ ] 拔掉任一個共用系統的自動載入或相關節點，遊戲仍能跑，不崩潰、不卡死
- [ ] `godot --headless --check-only --path .` 無錯誤

---

## 9. 待討論

- [ ] `ctx.input_locked` 是否保留為相容層（原本地基已實作，`InputRouter` 上線後是否還需要這個全鎖
      欄位，或改由 `InputRouter` 完全取代）
