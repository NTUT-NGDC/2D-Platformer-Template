# 00b — 房間制與軟重生（地基增補）

> 前置：`CLAUDE.md`、`documents/00_foundation.md`
> 這份動到 `player/Player.gd` 與 `mechanics/_base/MechanicBase.gd`（唯讀區），實作於 `progress.md` 階段 16
>（U74～U82）。下面寫的是**實作後的版本**，跟講師最初的草稿不同處都已照講師決定修改。

---

## 為什麼要改

1. **不使用多場景**。切換場景需要填場景路徑或名稱，那是打字，違反 `CLAUDE.md` 鐵律四。改用「同一場景內多個房間 + 鏡頭瞬間切換」。
2. **鏡頭不做平滑跟隨**。玩家進入房間時鏡頭直接設到房間中心，無平滑、無預判、無阻尼。
3. **死亡處理改成訊號驅動**。`Player` 不知道死掉之後會發生什麼事，處理者可以被替換（W2 可能改成回關卡起點、W5 可能改成顯示結算畫面）。
4. **取消 `reload_current_scene()`**，改成軟重生。重載會把玩家丟回第一個房間，等同懲罰；Web 版也要重跑場景初始化。

---

## 1. Events 新增訊號

```gdscript
signal room_entered(room: Node)
signal respawn_requested(player: Node)   # 由死亡處理者發出，表示「現在請重生」
signal player_respawned(player: Node)    # Player.revive() 完成後發出
```

死亡流程固定為：

```
Player.kill()
  → emit died / Events.player_died      ← Player 的責任到此為止
  → [某個處理者] 聽到，決定要做什麼
  → 處理者呼叫 player.revive(位置)
  → Player 重置狀態、通知機制卡 on_respawn()、emit Events.player_respawned
```

Player **不得**自己呼叫重生、不得知道處理者是誰。場景裡沒有任何處理者時，`RespawnMemory` 在輸出面板
印中文提示（死了不會回來，但遊戲不會壞）。

---

## 2. Room 節點 `blocks/Room.tscn`

`Area2D`，`@tool`。節點原點 = 房間左上角。

```gdscript
@export_group("房間設定")
## 房間寬度，以格為單位（16px 一格，30 格 = 一個螢幕寬）
@export_range(16, 128) var width_in_tiles: int = 30
## 房間高度，以格為單位（17 格 ≈ 一個螢幕高，最下面半格會被畫面切掉）
@export_range(9, 64) var height_in_tiles: int = 17
```

- 視窗 480×270、磚 16px，一個螢幕 ≈ 30×16.875 格，預設 30×17，多出的半格被畫面切掉。
- 碰撞框依格數自動產生（內部節點，場景樹看不到、學員拖不壞）；`collision_layer = 0`，
  子彈、近戰判定打不到房間。
- 玩家**中心點**跨進房間時才發 `Events.room_entered`（碰到邊就發的話，站在交界來回走鏡頭會卡在錯的房間）。
- 房間起點（在這個房間死掉回到的位置）：Inspector「房間起點」群組的 `spawn_x`（離左邊幾格，預設 15）、
  `spawn_y`（離底部幾格，預設 2）兩個拉桿，預設＝底部中央往上兩格。拉桿範圍固定，超出房間時夾回房間內，
  並顯示黃色警告。原本拖 `Marker2D` 的做法取消（講師決定：改用拉桿，避免兩種方法並存）；底下還有 `Marker2D`
  時黃色警告＋執行時中文提醒改用拉桿。
- `use_room_start`（預設勾）：這個房間有沒有房間起點。不勾時在這個房間死掉，依序退回：房間裡踩過的 Checkpoint >
  最後踩到的 Checkpoint（可能在別的房間）> 玩家一開始的位置（講師決定：用來做「這段沒存檔，死了退回上一個重生點」）。
  編輯器裡黃點變灰、標「房間起點（不使用）」。Room 執行時加入 `room` group，重生處理者用它找座標落在哪個房間。
- 提供 `get_center()`、`get_spawn_point()`、`uses_room_start()`、`has_point(global_point)`。
- 編輯器裡畫淺藍色邊框、房間名稱、黃色「房間起點」標記（不使用重生點時標註「不使用重生點」）。
  「重生點」這個名稱保留給 Checkpoint 零件，避免學員搞混。

---

## 3. CameraRig 增補

- 接 `Events.room_entered`，`global_position = room.get_center()`，無 tween、無 lerp，並 `reset_smoothing()`。
- 震動是疊加在上面的 `offset`，不會改到房間中心。
- `follow_player` **保留當備用**：只在場景裡沒有任何 Room 時生效（Showroom 用）。一有房間就關掉跟隨，
  若 `follow_player` 有勾則印中文提示。

---

## 4. RespawnHandler `blocks/RespawnHandler.tscn`

放在關卡場景裡，**不做成 Autoload**，學員看得到、刪得掉、換得掉。

```gdscript
@export_group("重生設定")
## 死亡後隔多久重生（秒）
@export_range(0.0, 3.0) var delay: float = 0.8
## 死亡後要怎麼重來：回到目前房間，或是整關從頭開始
@export_enum("回到目前房間", "整關重來") var mode: int = 0
## 重生時把房間裡的箱子、敵人、平台等零件復位（整關重來時復位整個關卡）
@export var reset_room_objects: bool = true
## 每次重生都發出「關卡重新開始」事件，給想在重來時做事的組件聽
@export var send_restart_signal: bool = true
```

**回到目前房間**：

1. 等 `delay` 秒；等待期間玩家已經被別人復活就不處理。
2. `reset_room_objects` 為真時，對**掛在目前房間底下**（Room 的子孫節點）有 `reset()` 的節點逐一呼叫。
   講師決定：物件歸屬看場景樹，不看位置（學員看得到、改得到）。場景裡完全沒有 Room 時＝整個關卡。
   Room 範圍內有會放回去、但沒掛在任何 Room 底下的物件時，Room 顯示黃色驚嘆號並在執行時印中文警告；
   這些物件不會被放回去。
   Room 底下可以放重生分組 `blocks/RespawnGroup.tscn`（Node2D，子物件位置才跟得上），底下的物件套用分組規則：
   `reset_objects` 不勾時，在房間裡死掉不放回這一組；`rewind_values` 不勾時，這一組帶來的數值不倒回。
   巢狀分組以最近的分組為準。整關重來一律全部放回、全部倒回，不看分組。
   有 Room 的關卡裡分組放在 Room 外面時，RespawnHandler 開場印中文警告；沒有 Room 的關卡整個場景一起復位，分組照樣有效。
3. 數值由物件自己倒回（講師決定，取代原本的數值快照）：步驟 2 放回之前，先對同一批物件呼叫 `rewind_values()`。
   Pickup 被撿走過就扣回當初加的數值，Door 開門時付掉的鑰匙／金幣如數還回；同一次只倒回一次（「不放回但倒回」
   的分組下次死掉不會再扣）。`reset_on_death` 關掉的種類不倒回。血量由 `revive()` 補滿。
   物件跟數值永遠一起動，不會出現同一枚金幣撿兩次。**之後新增會改數值的零件，都要實作 `rewind_values()`。**
   `reset_room_objects` 不勾時什麼都不放回、數值也不倒回。
4. 重生位置：同房間內踩過的 Checkpoint > 房間起點（房間勾了 `use_room_start` 才算）> 最後踩到的 Checkpoint（可能在
   別的房間）> 玩家一開始的位置。沒有房間時：踩過的 Checkpoint > 玩家一開始的位置。
   重生到別的房間時，死掉的房間跟重生的房間都放回、倒回；退回玩家一開始的位置時不清空踩過的 Checkpoint。
   沒有房間時第一次死亡印中文提示。
5. 發 `Events.respawn_requested`，呼叫 `player.revive(位置)`；勾了 `send_restart_signal` 再發 `Events.level_restarted`。

**整關重來**（軟重置，不重載場景）：所有 Room 底下的零件 `rewind_values()` + `reset()`（不看分組）、清空 Checkpoint、玩家回到一開始的位置，
Room 會重新發 `room_entered` 讓鏡頭切回第一個房間。

場景裡放了兩個 RespawnHandler 時只有第一個生效，其他的印警告。

---

## 5. RespawnMemory（改寫）

不再跨場景載入，只記「踩過的 Checkpoint 位置」。數值不記：由放回去的物件自己倒回（§4 步驟 3）。

- `restart_level()`：清空所有記錄。
- 踩過的 Checkpoint **每個房間各記一個**（那個房間最後踩到的），另外記「全關卡最後踩到的」一個。
  重生時「同一個房間裡踩過的 Checkpoint」查的是該房間自己的記錄，不會被別的房間後來踩的蓋掉。
- `clear()`（整關重來、過關）時 `call_group("checkpoint", "forget")`，所有 Checkpoint 變回沒踩過，可以再踩一次。
- `ValueSettings` 把 `reset_on_death` 關掉的種類，死亡完全不影響（Pickup／Door 不放回也不倒回）。
- 拿掉 `remember()` / `recall()` 與 `persistent` group（不重載場景就不需要）。
- 拿掉數值快照（進房間／踩 Checkpoint 當下的數值）：數值只會因為物件被放回而倒回。沒有 Room 的關卡整個場景一起
  放回，Checkpoint 前撿的道具也會回來、數值一起扣回，不會重複撿（原本的已知限制因此消失）。

---

## 6. Player 增補

- `kill()`：只設 `_is_dead`、`velocity = Vector2.ZERO`、發 `died` 與 `Events.player_died`。
- `revive(at_position)`：位置、速度、`up_direction = Vector2.UP`、`set_size_factor(1.0)`（同時還原視覺與碰撞框）、
  `Stats.refill(Stats.HEALTH_KIND)`、內部狀態歸零，逐一呼叫機制卡的 `on_respawn()`，發 `Events.player_respawned`。
- `is_dead()`：查詢是否死亡中。
- 血量仍由 `Stats` 管，Player 不另存 `max_health`。
- 拿掉 `_ready()` 裡的 `RespawnMemory.apply_position()`。

---

## 7. MechanicBase 增補與各卡 `on_respawn()`

```gdscript
# 玩家重生時 Player 會呼叫，機制卡在這裡把自己的狀態歸零（例如翻轉狀態、計時、倍率）
func on_respawn() -> void:
	pass
```

各卡要重置什麼見 `01b_mechanic_cards.md` §1 總表的「重生時」欄。

---

## 8. 零件的 `reset()`

```gdscript
# 把自己恢復到關卡開始時的狀態
func reset() -> void:
```

**原則：實體狀態重置，訊號控制的開關狀態不重置。** 按鈕、訊號門、風扇／平台的啟動開關連著別的零件，
重置了會跟控制它的零件對不上而卡關（例如 Room1 的永久按鈕打開 Room2 的門，在 Room2 死掉把門關回去就過不去了）。

| 零件 | `reset()` 做什麼 |
|---|---|
| Box | 回原位、停止移動 |
| Enemy | 回原位、血量補滿、被打倒的復活（被打倒改成藏起來，不刪除） |
| Pickup | 被撿走的放回來（被撿走改成藏起來，不刪除）；數值設成死亡不退回的不放回 |
| Breakable、CrumbleFloor | 碎掉的長回來，取消還在倒數的碎裂／重生計時 |
| MovingPlatform | 回起點；動不動照舊由訊號決定 |
| Door | 只有鑰匙／金幣門關回去；數值設成死亡不退回且會消耗時不重置 |
| Button | 預設不重置；勾了 `reset_on_death` 才回到關著的狀態，原本開著就發出 `turned_off`，連著的零件跟著關掉（學員自己選要不要） |

Fan、Launcher、EnemyShooter、Spike、Lava、Portal、Checkpoint、Goal 等沒有 `reset()`（開關狀態交給控制它的按鈕決定）。

---

## 8.5 事件轉接器 `blocks/EventListener.tscn`

全域事件掛在 `Events` 自動載入上，學員在場景樹看不到、沒辦法用訊號連接。轉接器放在關卡裡，
用下拉選單選要聽的事件，事件發生時發出**不帶參數**的 `triggered`，學員照平常連按鈕的方式連到任何零件。

```gdscript
## 要聽哪一個遊戲事件
@export_enum("玩家死亡時", "玩家重生時", "玩家受傷時", "玩家跳躍時", "進入房間時", "過關時", "撿到道具時", "敵人被打倒時") var event: int = 0
## 事件發生後，隔多久才發出訊號（秒）
@export_range(0.0, 3.0) var delay: float = 0.0
```

- 自動加入 `signal_source`，連線驗證器與虛線都適用；`triggered` 沒連到任何東西時印中文提醒。
- 可以放很多個，各聽各的事件。W2、W5 要做「死了顯示結算畫面」之類的行為，也可以用它接。
- `Events.item_collected` 由 Pickup、`Events.enemy_died` 由 Enemy 發出。

---

## 9. 驗收條件

- [x] `Player.gd` 內沒有任何 `reload_current_scene()` 或重生邏輯
- [x] 刪掉 `RespawnHandler` 節點，玩家死後不會重生，但遊戲不崩潰、不報錯，輸出面板有中文提示
- [x] 拖入兩個 `Room` 並排，玩家走過邊界時鏡頭瞬間切到新房間，沒有平滑位移
- [x] 在第二個房間死亡，重生在第二個房間，不是第一個
- [x] 重生後第一個房間的箱子維持原樣（只重置目前房間）
- [x] 掛重力翻轉卡，翻轉狀態下死亡，重生後重力與角色上下方向都已復位
- [x] 掛忽大忽小卡，變大狀態下死亡，重生後回到卡片一開始的體型（`small_scale`）
- [x] 場景裡一個 `Room` 都沒有時，玩家死亡仍能重生到初始位置，輸出面板有中文提示
- [x] `Room` 的碰撞框由格數自動產生，學員不需手動拉
- [x] 煙霧測試新增：連續 kill / revive 10 次，狀態每次都正確歸零
- [x] SmokeTest 通過、`--import` 無錯誤
