# 專案：五週遊戲原型工作坊 Godot 實驗包

這是一個給**完全沒寫過程式的大學社團學員**使用的 Godot 教學實驗包。
不是一般遊戲專案。下面每一條鐵律都有對應的實際教學事故，請嚴格遵守。

---

## 環境

- **Godot 4.7.2（非 .NET 版）**，版本鎖死，不要使用 4.8+ 或任何 4.7.2 以後的 API
- GDScript only，不使用 C#
- 目標平台：Windows 桌面 + Web（HTML5）
- 學員在學校電腦教室或自己的筆電，硬體普遍偏弱

---

## 最高原則

> 學員全程只做三個動作：**拖節點、選下拉選單、拉數值拉桿。**

任何設計都用這句話檢驗：這個操作能不能用滑鼠示範完，而且示範一次學員就會？

不能的話就是設計錯了，要改設計，不是改教學。

---

## 溝通語言

Claude Code 在這個專案裡的所有對話回覆、進度回報、驗收結果說明，一律使用**繁體中文**。
程式碼裡的識別字仍照下面「命名規範」執行（英文變數名、`@export` 欄位英文變數名搭配中文 `##` doc comment tooltip），這一條只規範跟使用者的溝通。

---

## 五條鐵律

### 1. 零連線

組件拖進場景就要生效，**學員不得手動連任何一條線、填任何一個節點路徑**。
上期用 Unity 時，講師整堂課都在幫學員檢查 UnityEvent 拉線有沒有拉對。

違反範例：`@export var target_node: NodePath`
正確做法：由 Player 主動發現子節點並呼叫其 `setup()`

### 2. 學員的檔案只在 `_my/`

`res://_my/` 以外的所有檔案都是**唯讀區**。
學員的任何操作（掛機制卡、調數值、蓋關卡、換素材）都必須只寫進 `_my/` 底下的場景檔。

這讓「重灌 SOP」成立：複製 `_my/` → 刪專案 → 重新解壓 → 貼回 `_my/`（30 秒）。

**所以：不要把學員會改的東西做進 `player/Player.tscn`。**
容器節點（Mechanics / Juice）和視覺節點都住在關卡場景裡，當 Player 實例的子節點。

### 3. 不可能出現「靜默失效」

學員拖錯位置、漏掉前置條件時，**必須有看得見的回饋**，不能只是沒反應。
沒反應 = 學員舉手 = 講師巡場時間，這正是要消滅的成本。

所有組件在 `setup()` 失敗時必須 `push_warning()` 並在 `_ready()` 印出中文訊息到輸出面板。

### 4. Inspector 全英文變數名 + 中文說明、零打字

所有 @export 欄位：

變數名用英文 snake_case，選字限定在新手能一眼猜到的簡單字（speed / strength / duration / enabled / delay / min_ / max_），避開 threshold、multiplier 這類詞
每個 @export 上方必須有 ## 文件註解寫中文說明，Inspector 滑過去會顯示為 tooltip
@export_group 的群組名用中文（參數是字串）
@export_enum 的選項用中文（參數是字串）
只能是 @export_enum 下拉、@export_range 拉桿、或 bool 勾選框，不得有需要打字的欄位

### 5. 組件之間不准打架

任意組合、任意數量的機制卡與 Juice 組件同時存在時，遊戲不得崩潰或卡死。
拔掉任何一個組件，遊戲仍必須能跑。

---

## 命名規範

| 對象 | 規範 | 範例 |
|---|---|---|
| 檔案／節點名 | 英文 PascalCase | `Mechanic_GravityFlip.tscn` |
| 腳本內部變數、函式 | 英文 snake_case | `_on_landed`, `impact_force` |
| `@export` 欄位 | 英文 snake_case + 上方 `##` 中文 doc comment | `## 影響跳躍高度，數值越大跳越高`<br>`@export_range(0.0, 2.0) var strength` |
| `@export_enum` 選項字串 | **繁體中文** | `@export_enum("跳躍時", "落地時")` |
| 輸出面板訊息 | **繁體中文** | `print("[重力翻轉] 已啟用")` |
| 程式註解 | 繁體中文，規則見下方「函式註解規則」 | |

### 函式註解規則

- 每個函式上方加一行中文註解，說這個函式**在做什麼**，不解釋怎麼做。私有函式（`_` 開頭）也要加。
- 用 `#`，不要用 `##`——`##` 保留給 `@export` 欄位的 Inspector tooltip，不要跟函式註解混用。
- 公開 API（機制卡／Juice 作者會呼叫或覆寫的函式，例如 Player 提供的那些）要寫成**使用者看得懂的角度**：

  ```gdscript
  # 翻轉重力方向，重力翻轉卡用這個
  func flip_gravity() -> void:
  ```

- 不要加檔頭大段說明，不要加 `# ----` 分隔線以外的裝飾。

---

## 禁止事項

- ❌ 不要在組件裡寫 `get_parent().get_parent()` 或任何往上爬節點樹的程式碼
- ❌ 不要使用 `@onready var x = $"../../Something"` 這類相對路徑
- ❌ 不要讓組件直接寫入 `Player.velocity`，一律透過 Player 提供的公開 API
- ❌ 不要在 `player/Player.gd` 裡寫任何跟特定機制卡有關的邏輯
- ❌ 不要新增需要學員安裝的外掛或 addon
- ❌ 不要用 Godot 3.x 的 API（`KinematicBody2D`、`move_and_slide(velocity, UP)` 舊簽章等）

---

## 驗證方式

Claude Code 無法目視確認畫面，所以每次改動後至少要跑：

```bash
# 語法與資源檢查（不開視窗）
godot --headless --check-only --path .

# 匯入資源並立刻退出，確認沒有匯入錯誤
godot --headless --import --path .

# 跑煙霧測試場景（自動測完退出，錯誤會印在 stdout）
godot --headless --path . res://_tests/SmokeTest.tscn
```

`_tests/SmokeTest.tscn` 的規格見 `documents/00_foundation.md`。
**任何新增的機制卡或 Juice 組件都必須加進煙霧測試的清單。**

---

## 開發順序

一次只做一週。不要提前實作未指定的週次。

1. `documents/00_foundation.md` — 地基（所有週次的前提）
2. W1（依序）：
   - `documents/01a_shared_systems.md` — 共用系統（輸入路由／數值／死亡重生／訊號連接）
   - `documents/01b_mechanic_cards.md` — 18 張機制卡（10 張主限制卡 + 8 張規則卡）+ 備品庫
   - `documents/01c_blocks_and_abilities.md` — 零件（`blocks/`）與攻擊能力（`abilities/`）
   - `documents/01d_showroom_and_toybox.md` — 展示間與玩具箱
3. 之後的週次規格會在該週開課前才提供

---

## 背景脈絡

- 上期用 Unity，環境建置吃掉大半堂課、打包太慢導致最後一週取消上台報告
- 這期改 Godot 就是為了解決這兩件事
- 學員中會有人**中途才加入**，所以每週產出要能獨立展示
- 講師只有一個人加一位助教，現場約 10-15 人
- 課堂上**不鼓勵學員用 AI 寫程式**（新手無法判斷 AI 給的是 Godot 3.x 還是 4.x 的答案）