# 03 — W3：手感果汁（Game Feel Juice）

> 前置閱讀：`CLAUDE.md`、`documents/00_foundation.md`（§4.2 JuiceBase）、`documents/01a_shared_systems.md`（§7 事件一覽）

這份規格定義 `juice/` 底下的手感組件。學員把組件拖進 Player → Juice 底下就生效，
用「觸發時機」下拉選什麼時候播，用拉桿調強度。機制卡、零件的玩法完全不變，只是「看起來、聽起來」更好。

---

## 1. 設計原則

- **Juice 只管表現，不碰玩法**：Juice 組件不得呼叫 `add_impulse()`、`force_jump()` 這類會改變物理的 API，
  也不得改 `Engine.time_scale`（頓幀一律透過 `Events.hitstop_requested`，由 `HitStopManager` 獨佔）。
  拔掉所有 Juice，遊戲的玩法完全一樣。
- **不直接寫 `player.visual`**：`Visual` 本身的 `scale`／`modulate` 已經被機制卡使用（忽大忽小、重力翻轉、
  自動奔跑、停止即死、越跑越快、後座力移動）。Juice 一律透過 Player 的表現層 API（§2.1），作用在 `Visual`
  的**子節點**上，跟卡片疊加，不互相蓋掉。
- **欄位數量不設上限**（講師決定，同機制卡、零件規則）：欄位多時用 `@export_group` 分組，只在某個選項下才有意義的用 `_validate_property()` 隱藏。
- **拖進來預設就好看**：每個組件的 `.tscn` 預先選好最合適的觸發時機與數值，學員不調任何東西也看得出效果。
- **兩種類型**：
  - **一次型**：照觸發時機播一次（震動、頓幀、擠壓、閃色、粒子、音效、鏡頭推近）。
  - **持續型**：拖進來就一直作用（殘影、咕嚕眼）。持續型用 `_validate_property()` 把 `timing` 藏起來。
- **機制卡、零件的事件用訊號連**：觸發時機下拉只列玩家與世界的共通事件。想在「重力翻轉時」播效果，
  選「不自動觸發」，再把卡片的 `flipped` 訊號連到 Juice 的 `play()`（跟 Button → Door 同一套操作）。
- **弱電腦與 Web**：粒子一律用 `CPUParticles2D`，單次噴發上限 64 顆；不用自訂 shader。
- **重生歸零**：玩家重生時，所有 Juice 停止進行中的效果並把外觀還原（擠壓到一半就死掉，重生後不能還是扁的）。

---

## 2. 地基調整

### 2.1 Player 表現層 API

由 `player/JuiceLayer.gd`（Player 內部使用的輔助類別）實作，`Player.gd` 只開出下面幾個函式。
每個請求都帶 `source`（發出請求的組件），同時有多個組件請求時**相乘合成**，任何一個組件移除時只撤掉自己那份。

```gdscript
# 讓角色外觀暫時壓扁或拉長，(1, 1) 是原本的樣子，擠壓拉伸這類 Juice 用這個
func set_juice_squash(source: Node, amount: Vector2) -> void:

# 讓角色外觀暫時疊上一層顏色，亮度超過 1 會變亮（閃白），閃色這類 Juice 用這個
func set_juice_tint(source: Node, color: Color) -> void:

# 讓角色外觀暫時傾斜（弧度），傾斜這類 Juice 用這個
func set_juice_tilt(source: Node, angle: float) -> void:

# 撤掉這個組件對外觀的所有影響，Juice 移除或重生時用這個
func clear_juice(source: Node) -> void:
```

- 作用對象：`Visual` 底下的每一個 `CanvasItem` 子節點（`Sprite2D`、`AnimatedSprite2D`…），第一次套用時記住原本的
  `position`／`scale`／`rotation`／`modulate`，所有請求撤掉時還原。
- 擠壓以**腳底**為中心（重力翻轉後一樣是貼地那一側），壓扁時腳不會浮起來。
- `Visual` 不存在時不做事（Player 已經會印警告）。

### 2.2 鏡頭

- `CameraRig` 收到新的震動請求時，**取比較強的那個**（剩餘強度 vs 新強度），不再直接覆蓋。
- `Events` 新增 `zoom_requested(strength: float, duration: float)`，`CameraRig` 執行：放大到 `1 + strength`
  再回到原本大小，放大時鏡頭往玩家位置偏一點。房間內跟隨模式的限制範圍要用放大後的畫面大小計算。

### 2.3 JuiceBase 擴充

| 項目 | 內容 |
|---|---|
| `timing` 下拉 | 跳躍時、落地時、受傷時、死亡時、撞牆時、開始移動時、轉向時、重生時、打中東西時、打倒敵人時、撿到東西時、過關時、不自動觸發 |
| `follow_impact` 勾選框 | 只在「落地時」出現。勾選時效果強度跟著落地力道變化（輕輕落地小、高處摔下大），預設勾選 |
| `play()` | 公開函式，播放一次效果。可以接受任意數量的參數（忽略），所以任何訊號都能直接連過來；連線驗證器不得對它報參數數量錯誤 |
| 事件位置 | 玩家事件 = 玩家位置；打中東西／打倒敵人／撿到東西 = 事件發生的位置。子類別用 `_trigger_position` 取得 |
| 連發保護 | 同一個組件 0.05 秒內只播一次（內部常數，不給學員調），避免彈性宇宙這類每幀落地的卡塞爆畫面 |
| 重生 | 聽 `Events.player_respawned`，呼叫子類別的 `_on_reset()` 並 `clear_juice(self)` |
| 移除 | `_exit_tree()` 時 `clear_juice(self)`，拔掉組件外觀立刻還原 |

「打中東西時」= `Events.hit` 裡被打的不是玩家自己（玩家被打是「受傷時」）。

### 2.4 Juice 總開關

自動載入 `JuiceSwitch`：按 `0`（`InputRouter.bind_key`，低優先、只聽不搶；不用 F1：F 鍵在網頁版會被瀏覽器攔截）切換全部 Juice 開／關，
畫面右上角顯示「Juice：開」／「Juice：關」兩秒。關掉時一次型不播、持續型隱藏，並撤掉所有外觀影響。
這是教學用的前後對照工具：讓學員自己按按看差多少。

---

## 3. 組件清單 `juice/`

### 3.1 核心組件（上課介紹）

| 檔名 | 中文名 | 類型 | 預設時機 | 欄位 |
|---|---|---|---|---|
| `Juice_ScreenShake` | 螢幕震動 | 一次 | 落地時 | `strength`、`duration` |
| `Juice_HitStop` | 頓幀 | 一次 | 打中東西時 | `duration`（0.03～0.3） |
| `Juice_SquashStretch` | 擠壓拉伸 | 一次 | 落地時 | `shape`（壓扁／拉長）、`strength`、`duration` |
| `Juice_Flash` | 閃色 | 一次 | 受傷時 | `color`（白／紅／黃／黑）、`duration`、`count`（閃幾次） |
| `Juice_Particles` | 粒子噴發 | 一次 | 落地時 | `style`（塵土／火花／星星／碎片／煙霧／自訂場景）、`amount`、`color`（跟著樣式／白／黃／紅／藍／綠）、`custom_particles`（選「自訂場景」才出現，此時 `amount`／`color` 隱藏）、`spawn_at`（腳底／身體中心／事件發生處） |
| `Juice_Sound` | 音效 | 一次 | 跳躍時 | `sound`（內建音效下拉＋「自訂」）、`custom_sound`（選「自訂」才出現）、`volume`、`pitch_random` |
| `Juice_CameraZoom` | 鏡頭推近 | 一次 | 打倒敵人時 | `strength`、`duration` |
| `Juice_Trail` | 殘影 | 持續 | — | `min_speed`（超過才出現）、`spacing`（間隔）、`duration`（殘留時間）、`color` |
| `Juice_TrailLine` | 拖尾線 | 持續 | — | `mode`（速度夠快時／用訊號開關）、`min_speed`（速度模式才出現，預設 450，衝刺這類很快的移動才拖出來）、`duration`（拖尾長度，用時間算）、`color`（有 `Line2D` 樣板時隱藏） |
| `Juice_GooglyEyes` | 咕嚕眼 | 持續 | — | `look`（跟著移動方向轉頭／擺正中間）、`eye_count`（一隻／兩隻）、`eye_size`、`pupil_size`、`wobble`（晃動程度） |

補充：

- **粒子**生成在關卡場景裡（不跟著玩家走），噴完自己刪掉。三種用法（講師決定）：
  - 下拉選內建樣式：`juice/particles/` 底下的五個粒子場景，也是給學員複製來改的範例。四種是一次噴完（塵土、火花、碎片往外噴；
    星星在原地一閃一閃，適合金幣），煙霧是陸續冒出（`explosiveness` 調低）、慢慢往上飄、越飄越大越淡，示範不同的噴法。
  - 選「自訂場景」：學員把自己做的粒子場景（根節點 `CPUParticles2D`，可以放自己的圖）拖進 `custom_particles`，屬於資源欄位
    （見 `CLAUDE.md` 鐵律 4 的資源欄位例外）。空白或根節點不對：編輯器黃色驚嘆號＋執行時中文警告，改噴塵土。
  - 進階：在 `Juice_Particles` 底下放一個 `CPUParticles2D` 子節點，就改用它當樣板（Inspector 只剩 `spawn_at`）；
    樣板本身執行時不噴、不顯示。用 `GPUParticles2D` 會出現黃色驚嘆號。
  - 不管哪種用法都由組件強制一次噴完、噴完刪掉、跟著重力翻轉上下顛倒，單次上限 64 顆（超過自動減到 64 並警告）。
- **殘影**複製 `Visual` 底下圖片當下的樣子（含朝向、體型），淡出後刪掉；同時最多 12 個。
- **拖尾線**（講師決定新增）：像 Unity 的 TrailRenderer。`Line2D` 記下角色身體中心最近 `duration` 秒走過的位置，
  頭粗尾細、頭實尾透明；不拖線之後線的頭仍接在角色身上，從尾巴縮回去。線畫在關卡座標裡，不跟著角色的翻轉、體型變化。
  - 用訊號開關：把訊號連到 `start_trail()`／`stop_trail()`（接受任意參數），例如 `Extra_Dash` 的 `dashed`／`dash_ended`；
    開了 2 秒沒收到 `stop_trail()` 自動停。
  - 粗細固定 6；想調寬度曲線、漸層、貼圖：在組件底下放一個 `Line2D` 子節點當樣板（像 Unity TrailRenderer 的 Width 曲線與 Color 漸層，
    橫軸 0＝靠角色那頭、1＝尾巴）。編輯器裡會自動幫空白的樣板放一條示範線。
- **音效**用 `AudioStreamPlayer`，不受頓幀影響。`custom_sound` 是**資源欄位**：學員把音檔從檔案系統拖進欄位，
  不需要打字（講師決定，見 `CLAUDE.md` 鐵律 4 的資源欄位例外）。選「自訂」但沒放音檔：編輯器黃色驚嘆號＋
  執行時中文警告，改播預設音效。
- **咕嚕眼**：眼白（白圓＋黑框）＋黑眼珠。眼珠有慣性（牛頓第一定律）：角色速度一變，眼珠相對眼眶往反方向跑（起跑往後甩、急停與落地往前衝），
  再由彈簧慢慢拉回中間、稍微往重力方向垂，碰到眼眶邊緣會反彈。`look` 選轉頭時，眼睛整組滑到臉朝最後移動方向的那一側。**眼睛的位置＝這個組件節點的位置**：學員在編輯器裡直接把節點拖到臉上
  （`@tool`，編輯器裡就畫得出眼睛）。執行時跟著 `Visual` 的朝向與體型（翻轉、變大變小）一起變。

### 3.2 備品 `juice/_extra/`（平常不介紹）

| 檔名 | 中文名 | 說明 |
|---|---|---|
| `Juice_TextPopup` | 跳字 | 持續型：數值變化時在玩家頭上跳出「+1 金幣」「-1 血量」，往上飄、淡出。`kind`（全部數值／只有血量／自訂）、`custom_kind`（選「自訂」才出現，打字欄位四點防呆）、`color`（加綠減紅／白／黃）、`size`、`duration`。0.3 秒內同一種數值連續變化合併成一個字；死亡到重生之間的變化不跳 |
| `Juice_ScreenFlash` | 全螢幕閃光 | 整個畫面閃一下顏色（`CanvasLayer` + `ColorRect`），預設受傷時閃紅。`color`（白／紅／黃／黑）、`strength`（濃度）、`duration`；不受頓幀影響 |
| `Juice_Tilt` | 傾斜 | 持續型：跑步時身體往前傾，停下回正（`set_juice_tilt`） |
| `Juice_DeathBurst` | 死亡爆散 | 死亡時角色碎成方塊噴開、角色隱形，重生時恢復 |

**不做慢動作**：`Engine.time_scale` 已經由 `HitStopManager` 獨佔，而且備品卡「時間緩慢」也在用時間，
再加一個會互相打架（鐵律 5）。

---

## 4. 音效素材 `sfx/`

- 只用 **CC0** 素材（例如 Kenney 音效包），或用 sfxr 類工具自己生成（生成的自然是 CC0）。
- 出處與授權寫在 `sfx/CREDITS.md`。
- 內建至少 8 種：跳躍、落地、受傷、爆炸、撿東西、金幣、雷射、嗶。格式 `.wav`（短音效 Web 匯出最穩），
  每個檔案 < 100 KB。

---

## 5. 展示與起始場景

- `levels/_starts/W3_JuiceBox.tscn`：W3 中途加入者的起始場景。一小段有跳台、敵人、金幣、尖刺的路線，
  Player 底下已經掛好全部核心 Juice，按 `0` 對照有／沒有 Juice 的差別。
- `levels/Gym.tscn`：Player 的 Juice 底下示範掛 2～3 個（落地震動＋落地塵土＋跳躍音效）。

---

## 6. 測試

- 系統測試場景放 `tests/systems/`（表現層 API、JuiceBase、總開關），組件測試場景放 `tests/juice/`
  （`.gd` 放 `tests/juice/_scripts/`），備品放 `tests/juice/_extra/`。
- 煙霧測試（`_tests/SmokeTest.gd`）原本就會掃 `juice/`，另外補：
  - 6 個 Juice 同時掛（含咕嚕眼、殘影），把每一種觸發事件都發一次，跑 60 幀
  - 跟忽大忽小、重力翻轉、自動奔跑一起掛，連續 `kill()`／`revive()`，重生後 `Visual` 子節點的
    `scale`／`modulate`／`rotation` 要回到原本的樣子
  - 總開關切換 10 次不崩潰
  - 拔掉所有 Juice 後 `Visual` 子節點外觀完全還原

---

## 7. 驗收條件

- [ ] 每個核心組件拖進 Player → Juice 底下，不調任何東西就看得到（聽得到）效果
- [ ] 拖到錯誤位置有中文警告，遊戲不崩潰
- [ ] 擠壓拉伸＋閃色＋忽大忽小＋重力翻轉同時作用，外觀正確疊加，沒有誰蓋掉誰
- [ ] 把任一卡片的訊號連到 Juice 的 `play()`，連線驗證器不報錯，觸發時播放效果
- [ ] `0` 總開關可以一鍵關掉／開啟全部 Juice
- [ ] 煙霧測試通過
- [ ] Web 匯出後，弱電腦上全部 Juice 同時開啟仍然順暢
