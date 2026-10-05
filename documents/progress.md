# 實作進度清單

> 依 `01a_shared_systems.md`～`01d_showroom_and_toybox.md` 拆成可逐一驗收的小單位。
> 每個單位對應一個能在 Godot 編輯器裡親眼驗證的東西（一個系統行為、一張卡、一個零件）。
> 完成一個就打勾，順序已經照依賴關係排好，原則上照順序做；如果要跳著做，注意標註的依賴。

---

## 階段 0：環境設定

- [x] U01 `project.godot` 碰撞圖層命名（Project Settings → Layer Names → 2D Physics，依
	  `01a_shared_systems.md` §2 的 6 個圖層）
- [x] U02 `project.godot` Input Map 精簡：保留 `move_left`/`move_right`/`move_up`/`move_down`/
	  `jump`/`restart`，移除 `interact`（驗證：Input Map 分頁只剩這 6 個動作）

## 階段 1：InputRouter

- [x] U03 `InputRouter` 自動載入：`bind()` / `bind_key()` 基本攔截與優先權（驗證：寫一個臨時測試
	  節點，兩個不同優先權綁同一個按鍵，確認只有高優先的收到）
- [x] U04 `InputRouter`：`owner` 離場自動解除綁定、按鍵衝突印中文警告、學員按鍵「只聽不搶」規則
	  （驗證：臨時測試節點模擬學員綁定，確認搶不走高優先輸入）

## 階段 2：Stats

- [x] U05 `Stats` 自動載入：`add`/`get_value`/`has_at_least`/`consume` 四個 API + `value_changed`
	  + 同步 `Events.value_changed`（驗證：在輸出面板印數值變化）
	  　　→ 數值種類改成學員自訂字串（原規格是固定 enum），細節見 `CLAUDE.md` 鐵律 4 例外說明
- [x] U06 `Stats` HUD 自動生成：數值第一次被用到時才出現 `CanvasLayer`（驗證：畫面上看到血條/圖示）
	  　　→ HUD 邏輯拆成獨立的 `StatsHud` 自動載入，訂閱 `Stats.value_changed`，`Stats` 本身不管畫面
- [x] U07 `ValueSettings` 場景設定節點（`start_value`/`max_value`/`show_in_hud`，驗證：改血量上限，
	  HUD 顯示對應變化）
- [x] U08 `Player.take_damage()` 改內部委派給 `Stats.add(血量, -amount)`，`MoveContext` 新增
	  `damage_scale` 欄位（驗證：扣血後 HUD 血條同步減少，血量歸零觸發 `kill()`）

## 階段 3：零件基礎設施（先做兩個零件，才能驗證訊號系統）

- [x] U09 `Button.tscn`（`01c_blocks_and_abilities.md` §2.1，驗證三種模式 + `turned_on`/`turned_off`）
- [x] U10 `Door.tscn` + `Receiver` 介面（`activate`/`deactivate`/`toggle`，驗證：手動在編輯器把
	  `Button.turned_on` 連到 `Door.activate`，踩按鈕門會開）
- [x] U11 連線驗證器：函式不存在／參數數量不對／目標節點已刪除／連到危險內建函式，四種情況各測一次
	  （驗證：故意接錯，看輸出面板中文警告）
- [x] U12 `Checkpoint.tscn`（`01c` §2.1，驗證：踩到時 emit `reached`，`Events.checkpoint_reached`
	  正確轉發）

## 階段 4：死亡與重生

- [x] U13 `RespawnMemory` 自動載入 + 死亡重生流程（依賴 U12 的 Checkpoint；驗證：踩重生點後死亡，
	  在重生點復活、血量補滿、`01a` §5.2 表格列的項目正確還原）
	  　　→ `ValueSettings` 加上 `reset_on_death` 欄位，讓每個數值種類可以個別決定死亡要不要退回

## 階段 5：其餘觸發／接收零件

- [x] U14 `KeyTrigger.tscn`（驗證：`key_source` 切換預設動作／自訂按鍵，`_validate_property` 正確
	  顯示對應欄位）
- [x] U15 `Portal.tscn`（驗證：A→B 傳送、B 自動連回 A、0.3 秒內不重複觸發）
- [x] U16 `Goal.tscn`（驗證：踩到 emit `Events.level_cleared`）
- [x] U17 `MovingPlatform.tscn`（驗證：`activate`/`deactivate`/`toggle` 正確控制移動）
- [x] U18 `Fan.tscn`（驗證：`activate`/`deactivate`/`toggle` 正確控制風力）

## 階段 6：地形類／物件類零件

- [x] U19 `Breakable.tscn` + `Hittable` 介面（驗證：`take_hit()` 扣耐久，歸零時 `broken`；
	  `Events.hit` 正確 emit）
- [x] U20 `CrumbleFloor.tscn`（驗證：踩上去抖動→碎裂→依 `respawn_time` 重生或不重生）
- [x] U21 `OneWayPlatform.tscn`（驗證：下方穿過、上方可站立）
- [x] U22 `Lava.tscn`（驗證：站上去依 `instant_kill` 扣血或即死）
- [x] U23 `SwitchBlock.tscn`（驗證：手動改 `color` 欄位，`switch_red`/`switch_blue` group 正確加入；
	  玩家重疊時延後實體化）
- [x] U24 `Box.tscn`（驗證：可推動、受擊只擊退不受傷）
- [x] U25 `Pickup.tscn`（驗證：四種 `kind` 各自正確加值，血包不超過上限）
- [x] U26 `Launcher.tscn`（驗證：彈簧固定力道、彈跳床依落下速度反彈）
- [x] U27 `Spike.tscn`（驗證：依 `penalty` 扣血或即死）
- [x] U28 `Enemy.tscn`（驗證：左右巡邏、撞牆轉身、受擊、血量歸零消失、重生後復活）

## 階段 7：攻擊能力

- [x] U29 Player 節點結構新增 `Abilities` 容器（零連線發現機制註冊，驗證：印出「已啟用」訊息）
- [x] U30 `Ability_Melee.tscn`（驗證：`key` 欄位可自訂，攻擊判定命中 `Hittable` 物件）
- [x] U31 `Ability_Ranged.tscn`（驗證：`key` 欄位可自訂，子彈飛行、命中消失）

## 階段 8：機制卡 — 主限制卡

- [x] U32 煞車失靈 `Mechanic_NoFriction`
- [x] U33 只能往前 `Mechanic_AutoRun`
- [x] U34 彈珠台體質 `Mechanic_PinballBody`（`MoveContext` 新增 `damage_scale` 已在 U08 加過，這裡
	  驗證擊飛行為）
- [x] U35 重力翻轉 `Mechanic_GravityFlip`（本卡第一次用到 `key` 欄位 + `_validate_property` 顯示
	  規則，之後幾張卡沿用同一手法）
- [x] U36 彈性宇宙 `Mechanic_BouncyWorld`（驗證：不會無限抖動）
- [x] U37 越跑越快 `Mechanic_SpeedRamp`
- [x] U38 忽大忽小 `Mechanic_SizeShift`（`MoveContext` 新增 `knockback_scale`/`push_scale`；驗證：
	  不會卡進地形，5 欄位版面正常顯示）
- [x] U39 蓄力青蛙跳 `Mechanic_ChargeJump`（用 `InputRouter.bind()` 優先權攔截 `jump`，驗證：攔截
	  期間 Player 自己的低優先跳躍不會誤觸發）
- [x] U40 只能用滑鼠控制 `Mechanic_Slingshot`
- [x] U41 只用後座力移動 `Mechanic_RecoilMove`

## 階段 9：機制卡 — 規則卡

- [x] U42 黏黏身體 `Mechanic_StickyBody`（驗證：黏在移動平台上會跟著移動）
	  　　→ 新增 `MoveContext.movement_frozen` 通用欄位，讓規則卡能蓋過主限制卡對方向／重力的提案
- [x] U43 移動會扣血 `Mechanic_Stamina`
	  　　→ 搭配「只能往前」時自動切換成跳躍扣體力模式 + 持續被動回復，避免卡死在懲罰狀態
- [x] U44 碰觸即死 `Mechanic_TouchDeath`
	  　　→ 敵人／箱子不在玩家碰撞遮罩內，改用貼著玩家的 Area2D 偵測；牆用碰撞法線方向判斷
- [x] U45 存活計時 `Mechanic_SurvivalTimer`
- [x] U46 停下即死 `Mechanic_StopDeath`（跟 U39 蓄力青蛙跳同時掛上時，蓄力中應暫停計時）
- [x] U47 血量流失 `Mechanic_HealthDrain`（驗證：讀寫 `Stats` 血量，沒有自己的「總血量」欄位）
	  　　→ 補血改訂閱 `Stats.value_changed`（金幣），因為 `Events.item_collected` 目前沒有任何地方會發出
- [x] U48 地板是岩漿 `Mechanic_FloorIsLava`
	  　　→ 偵測岩漿時額外檢查父節點（Lava.gd 把 lava group 加在根節點，玩家碰到的是子節點 Body）
- [x] U49 開關世界 `Mechanic_SwitchWorld`（依賴 U23 `SwitchBlock`）
	  　　→ 閃爍效果只用 CanvasItem 公開的 modulate，未動 SwitchBlock.gd；該卡目前是全隱藏不是降到 0.3 透明度

## 階段 10：備品庫（可延後，非正式卡池）

- [x] U50 `Extra_DoubleJump`
- [x] U51 `Extra_Dash`
- [x] U52 `Extra_WallJump`
- [x] U53 `Extra_StickyFloor`
- [x] U54 `Extra_Magnet`
	  　　→ 箱子是 RigidBody2D，站在地上摩擦力遠大於合理施力範圍，改成直接拉 global_position.x（不透過施力）
- [x] U55 `Extra_TimeSlow`
	  　　→ 直接改 Engine.time_scale，沒有整合進 HitStopManager（已跟使用者確認的取捨）
- [x] U56 `Extra_StompOnly`

## 階段 11：訊號連接收尾

- [x] U57 連線視覺化 `@tool` 虛線（`signal_source` 零件讀取自己的訊號連接，畫線到目標節點；驗證：
	  在編輯器裡打開 U09/U10 的 Button→Door 連接，看得到虛線）
	  　　→ 9 個有實際發訊號的零件都加了；Fan.gd 沒訊號可畫，沒動

## 階段 12：展示間與玩具箱

- [x] U58 `Showroom.tscn` 地形區（高牆、天花板走廊、窄縫、深坑、連續台階、開闊空地，驗證：帶一張機制卡走過去看物理反應）
	  　　→ 高牆改放在出生點左邊當死路岔路，不擋往零件區的主線（原本卡在路中間會擋死）
- [x] U59 `Showroom.tscn` 零件區 + 2-3 個組合小劇場（驗證：小劇場可玩，虛線正確顯示；整體維持單一螢幕內）
	  　　→ 改用鏡頭跟隨（`CameraRig.gd` 新增 `follow_player`），不是單一定格畫面；零件區跟地形區一樣
	  　　　排成一條橫向路線逛過去，不必再把兩區塞進同一個畫面
- [x] U60 `levels/_starts/W1_ToyBox.tscn` + `MyControls` 節點 + `_my/my_controls.gd` 範例（驗證：
	  另存到 `_my/` 後 `git status` 只有 `_my/` 變更）

## 階段 13：整體收尾

- [x] U61 `_tests/SmokeTest.gd` 掃到所有新增的 `mechanics/`／`juice/`（沿用既有掃描邏輯，確認新卡片都能跑滿 60 幀不報錯）
	  　　→ 既有掃描邏輯是遞迴掃資料夾，不用改程式；純驗證，沒有程式改動
- [x] U62 Web export 驗證：整包成功匯出並在瀏覽器可玩

## 階段 14：課堂輔助工具

- [x] U63 抽卡場景 `levels/CardDraw.tscn`（獨立場景，F6 直接執行；只抽 10 張主限制卡，卡面顯示卡名／
	  規則／難度／拖拽提示；卡片資料在 `data/mechanic_cards.tres`，方便事後改文字。驗證：F6 執行，按
	  「抽卡」隨機出一張，按「重抽一張」可以無限重抽，文字看得清楚）
	  　　→ 難度（技術／設計）01b 沒有逐卡資料，我先評一版 1~2 星放進 `data/mechanic_cards.tres`，
	  　　　覺得不準直接在那個檔案改數字；視窗開到 960x540（專案本體是 480x270 不是 320x180，這個
	  　　　視窗獨立於遊戲本體，不影響其他場景解析度）
	  　　→ 修過一次：`window/stretch/mode="viewport"` 會強制任何主視窗場景內部都先用 480x270 算畫面
	  　　　再縮放，跟 Window 節點自己的 size 是兩回事，害文字被裁切。`CardDraw.gd` 的 `_ready()` 執行
	  　　　時改寫 `get_tree().root.content_scale_mode` 為 DISABLED 解決，不影響遊戲本體其他場景

## 階段 15：滑鼠按鍵支援

- [x] U64 `InputRouter` 新增 `bind_mouse()`／`bind_student_mouse()`，滑鼠按鍵納入優先權與衝突警告（驗證：
	  `tests/systems/InputRouterTest.tscn` 點滑鼠左鍵，高優先權與學員都收到、低優先權被擋；放開右鍵印出秒數）
- [x] U65 `KeyTrigger` 按鍵來源可選滑鼠左鍵／右鍵／中鍵（驗證：`tests/blocks/KeyTriggerTest.tscn` 按住滑鼠右鍵再放開，
	  印出 pressed → released；Inspector 切到滑鼠選項時 action／key 都隱藏）
- [x] U66 攻擊能力（近戰／遠程）與有按鍵欄位的機制卡（重力翻轉／忽大忽小／衝刺）可改用滑鼠按鍵（驗證：
	  `tests/abilities/Ability_RangedTest.tscn` 點滑鼠左鍵，`Ability_Ranged_Mouse` 發射子彈）
- [x] U67 `Mechanic_Slingshot` 改走 `InputRouter`，不再直接讀滑鼠（驗證：`tests/mechanics/Mechanic_SlingshotTest.tscn`
	  拖曳／放開發射行為跟以前一樣）
- [x] U68 `Mechanic_Slingshot` 比照近戰在 Inspector 選拖曳鍵（`input_type` + `key`，預設滑鼠左鍵）（驗證：
	  `tests/mechanics/Mechanic_SlingshotTest.tscn` 把 `input_type` 改成滑鼠右鍵，右鍵拖曳能發射、左鍵沒反應）
- [x] U69 `Ability_Ranged` 新增 `aim_at_mouse` 勾選框，開啟後子彈朝滑鼠游標方向射（驗證：`tests/abilities/Ability_RangedTest.tscn`
	  點滑鼠左鍵，子彈跟著游標方向飛）
- [x] U70 `Ability_Ranged` 新增 `max_range_tiles` 最大飛行格數，0 代表不限制（驗證：`tests/abilities/Ability_RangedTest.tscn`
	  點滑鼠左鍵，子彈飛約 5 格就消失；G／H 照舊飛到撞牆或時間到）
- [x] U71 近戰判定區改成預製場景 `abilities/MeleeHitbox.tscn`，拿掉 `range_tiles` 拉桿，範圍與外觀改預製場景
	  （驗證：`tests/abilities/Ability_MeleeTest.tscn` 按 F，左右兩邊都看得到黃色判定區，打中會扣血／擊退；
	  改 `MeleeHitbox.tscn` 的形狀大小後再跑，判定區跟著變）
- [x] U72 `W1_ToyBox`／`Gym`／`_Template`／`Showroom` 的 Player 底下補上 `Abilities` 空節點（01c §3 要求，
	  之前漏做；驗證：打開四個場景，Player 底下都有 Mechanics／Juice／Abilities 三個節點）
- [x] U73 `mechanics/`（含 `_extra/`）、`blocks/`、`abilities/` 的 `.gd` 收進各自的 `_scripts/`，外層只留學員要拖的 `.tscn`
	  （驗證：煙霧測試通過；109 個 `.tscn` 全部能載入並實例化）

## 階段 16：房間制與軟重生（00b 地基增補）

> 講師決定（與 00b 原稿不同處）：視窗維持 480x270，房間預設 30x17 格，多出來的半格被切掉沒關係；
> 房間重生點改成拖 `Marker2D` 子節點（取代打字的 `spawn_offset`），沒放就用底部中央往上兩格；
> 血量仍由 `Stats` 管，Player 不另存 `max_health`；同房間內踩過的 Checkpoint 優先於房間重生點；
> `level_restarted` 要不要發由 `RespawnHandler` 的勾選框決定；18 張卡＋`_extra/` 全部檢查 `on_respawn()`；
> 所有有狀態的零件都各自實作 `reset()`，`RespawnHandler` 只負責呼叫。

- [x] U74 `Events` 新增 `room_entered`／`respawn_requested`／`player_respawned`；`Player.kill()` 只宣告死亡、
	  新增 `revive()`；`MechanicBase` 新增 `on_respawn()`（驗證：`tests/systems/ReviveTest.tscn` 按 K 死亡、按 R 復活到起點）
- [x] U75 `blocks/Room.tscn`：`@tool` 編輯器畫邊框、依格數自動產生碰撞框、玩家進入發 `room_entered`、
	  `Marker2D` 子節點當重生點（驗證：拖兩個 Room 並排，編輯器看得到邊框，走過邊界輸出面板印房間名）
- [x] U76 `CameraRig` 接 `room_entered` 瞬間切到房間中心，震動疊加在上面
	  （驗證：兩個房間並排，走過邊界鏡頭瞬切）
	  　　→ 講師決定保留 `follow_player` 當備用：場景裡沒有任何 Room 時才生效（Showroom 繼續用），
	  　　　一有 Room 進入就關掉跟隨、印中文提示，改成房間瞬切
- [x] U77 `blocks/RespawnHandler.tscn` 取代 `levels/_shared/Respawn`，改寫 `RespawnMemory` 配合軟重生，
	  替換所有關卡與測試場景；`mode` 下拉選單「回到目前房間／整關重來」，整關重來＝軟重置（玩家回初始位置、
	  所有房間零件 `reset()`、數值退回最初值、清空 Checkpoint），不重載場景（驗證：第二個房間死亡重生在
	  第二個房間；切到整關重來則回第一個房間；刪掉 RespawnHandler 死亡不重生也不報錯；沒有 Room 時重生在
	  初始位置並印中文提示）
	  　　→ 數值存檔點改成「進入房間的那一刻」（沒有房間的場景才用踩重生點那一刻），跟「只復位目前房間」
	  　　　對齊，避免金幣被扣但道具沒回來、或同一枚金幣撿兩次；`Player.gd` 拿掉 `RespawnMemory.apply_position`、
	  　　　新增 `is_dead()`；場景裡沒有 RespawnHandler 時，死亡由 `RespawnMemory` 印中文提示；
	  　　　放兩個 RespawnHandler 只有第一個生效並警告。零件的 `reset()` 要到 U79 才有，這之前死亡後
	  　　　敵人、可破壞方塊等不會復原
- [x] U78 18 張機制卡＋`_extra/` 有狀態的都實作 `on_respawn()`（驗證：重力翻轉、忽大忽小狀態下死亡，重生後復位）
	  　　→ 18 張裡有 16 張補了（TouchDeath、NoFriction 沒有要歸零的狀態）；`_extra/` 補了 Dash／DoubleJump／WallJump
	  　　　（Magnet、StickyFloor、StompOnly 沒狀態，TimeSlow 自己會在時間到時恢復）。忽大忽小重生回到卡片
	  　　　一開始的小體型（`small_scale`），不是 1；開關世界的紅藍方塊回到一開始的顏色
- [x] U79 有狀態的零件都實作 `reset()`（驗證：推走箱子後死亡，箱子回原位；別的房間的箱子不動）
	  　　→ 原則：實體狀態重置（位置、生命、被撿走、被打破），訊號控制的開關狀態不重置（按鈕、訊號門、
	  　　　風扇／平台的啟動開關），不然會跟控制它的零件對不上而卡關。有 `reset()` 的：Box、Enemy、
	  　　　MovingPlatform（只回起點）、Pickup、Breakable、CrumbleFloor、Door（只有鑰匙／金幣門）。
	  　　　Enemy 被打倒、Pickup 被撿走改成藏起來不刪除；會移動的零件用 `get_reset_position()` 回報
	  　　　原本位置，被推到別的房間也算原本的房間。數值設成「死亡不退回」時，付掉的鑰匙門不重置、
	  　　　撿走的道具不放回。`RespawnMemory` 的 `remember()`／`recall()` 與 `persistent` group 拿掉
	  　　　（不重載場景就不需要）
- [x] U80 煙霧測試新增連續 kill／revive 10 次檢查狀態歸零，跑完整份煙霧測試
	  　　→ 掛重力翻轉／忽大忽小／越跑越快，每輪先翻轉、變大、扣血再 kill／revive，檢查位置、重力、角色圖方向、
	  　　　體型、血量、is_dead、player_respawned 次數；`SMOKE TEST PASSED`，`--import` 無錯誤
- [x] U81 文件：`CLAUDE.md` 禁止事項、`01b` 卡片規格補 `on_respawn()`、`_help/` 補「怎麼拖一個房間」、
	  `00_foundation.md` 與 `01a` §5 改寫成軟重生（原本寫死亡＝重新載入場景）；`00_foundation.md` §7 煙霧測試補第 6 步；
	  速查表註明「有 Checkpoint 的關卡請拖 Room」（沒有 Room 時，Checkpoint 前撿的道具重生後會再出現，
	  可以重複撿；講師決定先不處理，列為已知限制）
	  　　→ 新增 `documents/00b_rooms_and_soft_respawn.md`（照實作後的版本寫，CLAUDE.md 開發順序也列進去）；
	  　　　學員操作速查表實際上是 `README.md`，「怎麼拖一個房間」寫在 README §5.1，「沒反應怎麼辦」補兩列；
	  　　　`_help/講師流程.md` 補「這次更新刪了 Respawn.gd，要發第一次安裝包，學員要換節點」；
	  　　　01c §1 補零件 `reset()` 原則
- [x] U82 `blocks/EventListener.tscn` 事件轉接器：下拉選單選要聽的 `Events` 事件（玩家死亡／重生／受傷／跳躍、
	  進入房間、過關、撿到道具、敵人死亡），發出不帶參數的 `triggered` 給學員用訊號連接，加入 `signal_source`
	  （驗證：放一個「玩家死亡時」轉接器連到門的 `activate`，死亡時門打開；連錯函式時連線驗證器印中文警告）
	  　　→ 「撿到道具」「敵人死亡」的 `Events.item_collected`／`enemy_died` 原本沒人發出，補在 Pickup／Enemy；
	  　　　`triggered` 沒連到任何東西時印中文提醒；編輯器畫紫色圓點＋事件名稱讓學員看得到、點得到
- [x] U83 `levels/_Template.tscn` 預放一個對齊畫面的 `Room1`（(-240,-80)、30x17 格，地板是房間最下面一列），
	  鏡頭位置改成房間中心 (0,56)；README §5.1 改成「開 Grid Snap、格線步長 16」（驗證：打開 `_Template.tscn`，
	  淺藍框剛好框住畫面、黃點在地板正上方；F6 執行鏡頭不會跳動、輸出面板印「玩家進入 Room1」）
	  　　→ 講師決定：Room 不做自動吸附（靠 Godot 的 Grid Snap）；Room 大小範圍維持開放，比畫面大時學員
	  　　　自己調鏡頭縮放；重疊警告不做

## 階段 17：場景設定節點整理

> 講師決定：ValueSettings 搬到 `blocks/` 並預先放在範本裡；拿掉 `MyControls` 與 `_my/my_controls.gd`
>（KeyTrigger 直接放在關卡底下就能用）；新增按鍵設定節點，讓學員改基本操作按鍵，設定存在 `_my/` 的關卡裡。

- [x] U84 `ValueSettings` 從 `levels/_shared/` 搬到 `blocks/`（`.gd` 放 `blocks/_scripts/`），`_Template`／`W1_ToyBox`
	  預先放一個 `ValueSettings_Health`，README 補 §5.2（驗證：打開 `_Template.tscn`，點 `ValueSettings_Health` 把
	  `max_value`、`start_value` 拉到 5，F6 執行左上角血量是 5）
	  　　→ 修正：原本 HUD 要等數值第一次變動才出現，一開場看不到血量。`show_in_hud` 改成「打勾一開場就顯示、
	  　　　不勾永遠不顯示」（`Stats` 新增 `configured` 訊號，`StatsHud` 訂閱）；沒有 ValueSettings 的種類維持
	  　　　第一次變動才出現
- [x] U85 `MyControls` 合併進 `KeySettings`：KeySettings 的 Inspector「預設操作」改基本按鍵，子節點 KeyTrigger 是
	  自訂按鍵清單（一列＝名稱＋按鍵＋觸發方式＋triggered 連到函式）；KeyTrigger 新增 `trigger` 下拉（按下時／
	  放開時／按住時（每一幀））與不帶參數的 `triggered`；拿掉 `_my/my_controls.gd` 與 W1_ToyBox 的 MyControls
	  （驗證：`tests/blocks/KeySettingsTest.tscn` 按 E 左門一按就開關、按住 Q 右門放開才開關；KeySettings 底下的
	  非按鍵節點印警告）
	  　　→ 講師決定：自訂按鍵用子節點當清單（Inspector 陣列無法指定場景節點、函式名要打字，違反鐵律一、四）。
	  　　　KeyTrigger 加入 `signal_source`（原本沒加，連線驗證器從沒檢查過它），順便抓到 Showroom 的
	  　　　`released(seconds)` 連到 `Fan.deactivate()` 參數數量不對，改連 `hold_ended`；KeyTrigger 一條訊號都沒連時
	  　　　印中文提醒。KeyTrigger 是 Node 沒有座標，畫不出連線虛線（驗證器仍會檢查）
- [x] U86 按鍵設定節點 `blocks/KeySettings.tscn`：下拉選單改 move_left／move_right／move_up／move_down／jump 的按鍵，
	  執行時改寫 InputMap（驗證：`tests/blocks/KeySettingsTest.tscn` 往左 J、往右 L、跳躍 Shift，A／D／空白鍵沒反應、
	  方向鍵照樣能走，輸出面板有 Shift 跟重力翻轉卡衝突的警告）
	  　　→ 講師決定：方向鍵永遠保留，只換字母鍵／空白鍵；下拉預設 None = 不改。在 `_enter_tree` 改寫，
	  　　　搶在組件向 InputRouter 註冊之前，衝突警告才會用新按鍵判斷；離開場景只還原自己改過的動作
	  　　　（不動 InputRouter 的臨時動作）；兩個基本動作撞鍵、選到瀏覽器會攔截的鍵、放兩個 KeySettings
	  　　　都印中文警告。`_Template`／`W1_ToyBox` 預放一個，README 補 §5.3。欄位 5 個（超過零件 4 個上限，
	  　　　同 ValueSettings 屬於設定節點）
- [x] U87 KeyTrigger 的 `key_source` 改成「自訂按鍵」優先：順序改為自訂按鍵／滑鼠左鍵／右鍵／中鍵／跟基本操作同一顆鍵
	  （原「預設動作」改名移到最後），預設自訂按鍵，拖進來看不到 `action: jump`；順序跟卡片、能力的 `input_type`
	  一致。Showroom、KeyTriggerTest、KeySettingsTest、KeyKillDemo 裡的數字跟著重排（驗證：headless 模擬按空白鍵、
	  P、滑鼠右鍵、1、E，5 個 KeyTrigger 都還綁在原本的按鍵上）
- [x] U88 KeyTrigger 的 `action` 改名 `same_key_as`：這個欄位只決定「聽哪一顆鍵」（Input Map 的動作），叫 action 會被
	  誤會成「要觸發的函式」；要觸發什麼只由 `triggered` 訊號決定。tooltip 註明基本操作照樣會做（只聽不搶）
	  （驗證：KeyTrigger 的 `key_source` 切到「跟基本操作同一顆鍵」，欄位名稱顯示 Same Key As）

## 階段 18：名稱欄位開放打字

> 講師決定：完全零打字讓組件無法擴充，改成「名稱／標籤」類欄位可以打字，但每個打字欄位都要有四點防呆
>（不打字也能用、編輯器黃色警告、執行時中文警告附近似建議、自動整理空白與全形）。數值、節點路徑、函式名仍禁止打字。
> Button 的偵測對象第一個開放：學員自己在「節點」面板加群組，Button 填群組名稱。

- [x] U89 修改 `CLAUDE.md` 鐵律 4（零打字 → 打字只限名稱＋四點防呆＋打字欄位清單）、`01a` §4.1、`01c` 按鈕規格
	  （驗證：讀過三份文件，確認規則寫法跟講師決定一致）
- [x] U90 共用名稱檢查工具 `NameCheck`：整理名稱（去頭尾空白、全形轉半形）、找近似名稱；`Stats` 的打錯字檢查改用它
	  （驗證：`tests/systems/StatsTest.tscn` 打錯字警告照舊出現；新測試場景印出整理與近似比對結果）
- [x] U91 Button 的 `pressed_by` 新增「指定群組」＋ `tag` 欄位（只在該選項顯示），編輯器黃色警告、執行時中文警告
	  （驗證：`tests/blocks/ButtonGroupTest.tscn` 鑰匙箱子推上按鈕會變綠、普通箱子跟玩家踩沒反應；Button_Typo／Button_Empty
	  在場景樹有黃色驚嘆號，執行時各印一則中文警告，Typo 那則建議「鑰匙」）
	  　　→ 選「指定群組」時多偵測敵人圖層；player／box／enemy 是執行時才加的群組，編輯器檢查當作存在；
	  　　　群組只算玩家／箱子／敵人本體身上的（加在底下圖片不算，警告會提醒）；被攻擊觸發模式不看群組；
	  　　　零件手冊補上操作步驟

## 階段 19：網頁版中文字型

> 講師決定：網頁版借不到系統字型，中文會變方框。內建繁中像素字型「俐方體 11 號」（Cubic 11，OFL 授權，woff2 約 400 KB）
> 設成全專案預設字型，學員不用做任何事。

- [x] U92 `art/fonts/` 放 `Cubic_11.woff2`＋授權檔；匯入設定關掉反鋸齒／hinting／次像素定位；`DefaultTheme.tres` 預設字級 12；
	  `project.godot` 設 `gui/theme/custom` 與 `gui/theme/custom_font`（驗證：開專案等匯入完，F5 看 HUD「血量」是清楚的像素字；
	  匯出 Web 版用瀏覽器開，HUD、展示間、抽卡畫面的中文都正常顯示）
	  　　→ 比對過專案所有字元，字型只缺 ⚠ ≈ ✗ ⭐；前三個只在輸出面板／tooltip／註解（編輯器字型），
	  　　　抽卡畫面的難度星星 ⭐（emoji）改成 ★

## 階段 20：機制卡可以用訊號連動

> 講師決定：學員想改卡片行為（例如「彈弓拉的時候動能歸零」）時，不再一個個加選項，改成「卡片發訊號 → 連到 Player 的
> 動作函式」，用節點面板拖拉連線就能組合出來。全部 18 張卡＋備品卡都加訊號；連線目標直接是 Player（先例：KeyKillDemo）。
> 規則：訊號一律不帶參數；會推玩家的訊號（射出、噴射、衝刺、跳…）在推力施加「之前」發出，連 `stop_motion` 才會是
> 「先歸零再推」。

- [x] U93 Player 新增可連線的動作函式 `stop_motion()`（動能歸零一次）、`freeze()`／`unfreeze()`（停在空中不受重力、
	  不能移動，死亡重生自動解除）；`01a` §6.6、零件手冊列出學員可以連的 Player 函式
	  （驗證：`tests/systems/PlayerActionsTest.tscn` 按 Z 歸零、按 X 凍住、按 C 解除）
- [x] U94 機制卡訊號共用規則：`MechanicBase` 自動加入 `signal_source`（連線驗證器會檢查）、`01b` §3 補訊號總表與發出時機規則
	  （驗證：讀 `01b` §3 的訊號表；任一張卡的測試場景 F6 照常運作，輸出面板沒有新的警告）
- [x] U95 彈弓卡 `drag_started`、`launched`（射出前發出）（驗證：`tests/mechanics/Mechanic_Slingshot_StopOnDragTest`／
	  `_StopOnLaunchTest`／`_FreezeWhileDragTest` 三個場景，照輸出面板的「預期」操作）
	  　　→ `launched` 拉的距離是 0 也發，不然學員「拉時凍住、射出解凍」會卡在空中
- [x] U96 其餘 9 張主限制卡訊號：NoFriction、AutoRun、ChargeJump、RecoilMove、PinballBody、GravityFlip、BouncyWorld、SpeedRamp、SizeShift
	  （驗證：9 張卡各自的 `tests/mechanics/Mechanic_*Test.tscn` 已放 `MechanicSignalPrinter`，F6 開場印出卡片訊號清單，
	  觸發時印「XX 發出 YY」）
	  　　→ BouncyWorld 原本的區域變數 `bounced` 跟新訊號同名，改名 `bounce_velocity`
- [x] U97 8 張規則卡訊號：StickyBody、Stamina、TouchDeath、SurvivalTimer、StopDeath、HealthDrain、FloorIsLava、SwitchWorld
	  （驗證：8 張卡各自的 `tests/mechanics/Mechanic_*Test.tscn` 已放 `MechanicSignalPrinter`，觸發時印「XX 發出 YY」）
	  　　→ StopDeath 扣血模式事件原本每幀發，`punished` 只在開始懲罰時發一次；StickyBody 時間到自動脫落也發
	  　　　`released`；FloorIsLava 新增踩上／離開的狀態追蹤；順手修 HealthDrain `enabled` 關閉時仍會撿金幣補血
- [x] U98 備品卡訊號：衝刺、二段跳、踩怪起飛、子彈時間、蹬牆跳
	  （驗證：5 張卡各自的 `tests/mechanics/_extra/Extra_*Test.tscn` 已放 `MechanicSignalPrinter`，觸發時印「XX 發出 YY」）
	  　　→ StompOnly 的 `stomped` 要在讀目前向上速度之前發，連 `stop_motion` 時彈跳高度才算得對；零件手冊補「機制卡也能連線」

## 階段 21：房間起點與重生點

> 講師決定：Room 用拉桿調房間起點（取代拖 Marker2D），黃點改名「房間起點」、「重生點」只指 Checkpoint；
> Room 可以選要不要讓房間裡的重生點優先。多個 Room＋多個重生點同時出現的情況要再多測。

- [x] U99 Room 新增 `spawn_x`／`spawn_y` 拉桿（格，spawn_y 從底部算）、`use_room_start` 勾選框；拿掉 Marker2D
	  （底下還有的話黃色警告＋中文提醒）；超出房間夾回並警告；RespawnHandler 看 `use_room_start`；`00b` §2 §4、零件手冊更新
	  （驗證：`tests/blocks/RoomTest.tscn` Room2 的黃點「房間起點」在小平台上，拉 `spawn_x` 黃點跟著動、拉超過 30 出現黃色驚嘆號；
	  `tests/blocks/RespawnHandlerTest.tscn` 照原本步驟死在 Room2 會回到小平台）
	  　　→ 三個測試場景的 Marker2D (120,160) 換成 spawn_x 8、spawn_y 7（x 從 120 變 128，差半格）
	  　　→ 講師修正：勾選框是「這個房間的起點要不要用」，不是關掉 Checkpoint。不用時退回：房間內踩過的 Checkpoint
	  　　　> 最後踩到的 Checkpoint（可能在別的房間）> 玩家一開始的位置；重生到別的房間時死掉的房間跟重生的房間都
	  　　　復位；數值退回最後踩到 Checkpoint 當下（`RespawnMemory` 每次踩到都記一份）
- [x] U100 多個 Room＋多個 Checkpoint 測試場景；修「只記得最後踩的重生點」（改成每個房間各記一個）與「整關重來後
	  重生點失效」（Checkpoint 跟著復位）
	  （驗證：`tests/blocks/MultiRoomRespawnTest.tscn` 照輸出面板 ①～⑨ 操作）
	  　　→ `RespawnMemory` 每個房間各記最後踩到的重生點（`has_checkpoint_in`／`get_checkpoint_position_in`）；
	  　　　`clear()` 時 call_group("checkpoint", "forget") 讓重生點變回沒踩過（整關重來、過關都會清）
	  　　→ 發現：Pickup `reset()` 一律放回地上，存檔點之後撿的跟之前撿的分不出來 → 同一枚金幣可以撿兩次
	  　　　（重回房間、退回別房間的重生點都會發生），待講師決定
- [x] U101 物件歸屬改成「拖到 Room 底下」：RespawnHandler 只復位 Room 子孫節點裡有 `reset()` 的（沒有 Room 的關卡照舊整個場景）；
	  Room 範圍內有沒掛進任何 Room 的會復位物件時黃色驚嘆號＋執行時中文警告（每秒重新檢查）；拿掉 Box／Enemy 的
	  `get_reset_position()`；RoomResetTest、MultiRoomRespawnTest 的物件搬進 Room 底下
	  （驗證：`tests/blocks/RoomResetTest.tscn` 照原本步驟在 Room2 死掉，箱子／敵人／金幣／可破壞方塊都復原；把 Coin_1 拖出
	  Room2 放到關卡底下，Room2 出現黃色驚嘆號、F6 死掉後 Coin_1 不會回來）
	  　　→ 講師決定：物件歸屬看場景樹不看位置；沒掛進 Room 的不復位＋警告；Showroom／W1_ToyBox 沒有 Room，不用搬
- [x] U102 `RespawnGroup` 分組節點（放在 Room 底下，底下的物件套用分組規則）＋ `reset_objects`
	  （驗證：`tests/blocks/RoomResetTest.tscn` 敵人放在「不放回」分組 OneTime，照輸出面板 ①～⑤ 操作）
	  　　→ 分組做成 Node2D；整關重來不看分組；編輯器在分組的子物件頭上標分組名稱；有 Room 的關卡分組放在 Room 外面時
	  　　　開場印警告。順手修 U101 造成的 RoomResetTest X 鍵打不到 Room 底下的敵人（改用 find_children）
- [x] U103 數值改成「物件放回時自己退還」（Pickup 扣回、Door 還回），拿掉 RespawnMemory 的數值快照；`RespawnGroup` 加 `rewind_values`
	  （驗證：`tests/blocks/RoomResetTest.tscn` Coin_3 在「數值不倒回」分組 Farm；`RespawnHandlerTest`、`MultiRoomRespawnTest`、
	  `tests/systems/RespawnMemoryTest.tscn` 都改用場景裡的金幣，照輸出面板步驟看金幣數）
	  　　→ 先 `rewind_values()` 再 `reset()`（靠「還沒放回」判斷有沒有被撿過）；同一次只倒回一次（`_value_returned`／`_paid` 歸零）；
	  　　　巢狀分組以最近的為準；`reset_room_objects` 不勾＝不放回也不倒回；除錯按鍵直接加的數值不會倒回，
	  　　　RespawnHandlerTest／RespawnMemoryTest 的 C 鍵改成場景裡的金幣；00b §5「沒有 Room 會重複撿」的已知限制消失

## 階段 22：射擊擴充（W1 補充）

> 講師決定：學員想要「滑鼠控制的後座力移動」「開槍有後座力」「敵人會朝玩家射擊」。射擊只做一份共用：子彈分陣營、
> 產生子彈與瞄準方向都走共用函式；玩家受擊也走 `take_hit()`，扣血照舊交給 Stats。開槍後座力做兩種讓學員選：
> 遠程的後座力拉桿（一般射擊帶一點後座），或把後座力卡的 `fired` 訊號連到遠程的 `shoot()`（只能靠開槍移動）。
> 敵人子彈會不會打壞可破壞方塊／按下按鈕做成選用勾選框，預設不會。

- [x] U104 射擊地基：`Bullet` 加 `class_name`、陣營（玩家方／敵方）、`damage`、`hit_objects`、共用 `Bullet.spawn()`；
	  共用瞄準工具 `Aim`；Player 實作 `take_hit()`（扣血交給 `take_damage()`＝Stats，再加擊退）；`Ability_Ranged` 改用共用函式，行為不變；
	  箱子新增 `block_bullets`（會不會擋子彈，預設會）
	  （驗證：`tests/abilities/Ability_RangedTest.tscn` 照舊；`tests/abilities/BulletTeamTest.tscn` 照輸出面板步驟）
- [x] U105 後座力卡新增 `input_type`（方向鍵／滑鼠左鍵／右鍵／中鍵），選滑鼠時按滑鼠鍵往游標反方向噴；輸入改走 InputRouter
	  （驗證：`tests/mechanics/Mechanic_RecoilMoveTest.tscn` 方向鍵照舊（含斜角）；`tests/mechanics/Mechanic_RecoilMove_MouseTest.tscn` 照輸出面板步驟）
- [x] U106 `Ability_Ranged` 新增 `shoot()`（給訊號連線用，不看冷卻）、`recoil_strength` 後座力拉桿、`damage` 傷害拉桿、
	  `input_type`「只用訊號觸發」（沒連線時開場警告）
	  （驗證：`tests/abilities/Ability_Ranged_RecoilTest.tscn` 照輸出面板 ①② 操作；`Ability_RangedTest.tscn` 照舊）
- [x] U107 `blocks/EnemyShooter` 敵人射擊組件：拖到關卡裡的 Enemy 底下就生效（Enemy 主動找子節點 `setup()`），8 個欄位分「射擊」
	  「子彈」兩組；放錯位置黃色驚嘆號＋中文警告；Enemy 新增 `is_defeated()`／`get_facing()`／`hold_still()`；玩家重生時敵方子彈消失；
	  煙霧測試新增第 7 步、零件手冊
	  （驗證：`tests/blocks/EnemyShooterTest.tscn` 照輸出面板步驟；`tests/blocks/EnemyTest.tscn` 照舊）
	  　　→ 講師決定：放 `blocks/`、欄位不限 4 個（8 個全留）

## 階段 23：擴充性整理（W1 補充）

> 講師決定：擴充性檢查找到的問題全部處理，並加入可切換的鏡頭模式。
> 順序：先修會讓組件打架的 bug（U108），再做不改行為的重構（U109–U111），最後才是新功能（U112–U117）。

- [x] U108 `MoveContext` 倍率改成乘上去（`*=`），修「兩張卡調同一個倍率只有後面的生效」（越跑越快＋體力、越跑越快＋忽大忽小、
	  衝刺、黏黏地板）；`auto_run_dir` 維持後面蓋前面並寫進文件；`00_foundation` 補機制卡寫 `MoveContext` 的規則
	  （驗證：`tests/systems/MoveContextStackTest.tscn` 照輸出面板步驟）
- [x] U109 危險按鍵清單＋警告收進 InputRouter（`InputRouter.warn_if_dangerous_key()`），9 份重複的刪掉；行為不變
- [x] U110 編輯器訊號連線虛線抽成共用工具 `SignalLines`，11 個零件改用（含 U107 的 EnemyShooter）；行為不變
- [x] U111 碰撞層常數 `Layers`（`Layers.PLAYER`、`Layers.TERRAIN`…），56 處位元運算改用（21 個腳本）；`01a` §2 對照；行為不變
- [x] U112 瞬間傷害統一走 `take_hit()`：碰到敵人、尖刺扣血改成 `take_hit()`（有擊退、會發 `Events.hit`）；
	  持續傷害（岩漿每秒扣血、血量流失、地板是岩漿）維持 `take_damage()`，不算「被打到」
	  　　→ 講師決定：Enemy、Spike 各新增 `knockback` 拉桿（0 = 不擊退）；方向「從敵人／尖刺指向玩家再往上偏」；
	  　　　Player.take_hit() 的擊退乘上 `ctx.knockback_scale`，彈珠台體質設成 0（只留自己的彈開，不疊加）
- [x] U113 `Pickup` 種類新增「自訂」，選了才出現打字欄位（數值種類名稱），照鐵律 4 四點防呆、用 `NameCheck`；
	  補進 `CLAUDE.md` 打字欄位清單
- [x] U114 `Door` 開門方式新增「自訂數值」，同 U113 的打字欄位與防呆
	  （跟道具不同：場景裡沒有別人用這個名稱也要警告，因為只有道具、ValueSettings 會給數值，找不到 = 門永遠打不開）
- [x] U115 可以用訊號開關的零件（Receiver）：EnemyShooter、Launcher 新增 `activate`／`deactivate`／`toggle`＋`start_on`
	  　　→ 講師決定（驗收時發現死亡後開火按鈕沒重置）：Button 新增 `reset_on_death`（預設不勾＝維持 00b §8 原則），
	  　　　勾了在重生時回到關著並發出 `turned_off`，連著的零件跟著關；被控制的零件本身不重置，避免跟按鈕對不上
- [x] U116 可以用訊號開關的零件（Receiver）：Spike、Lava、Portal 新增 `activate`／`deactivate`／`toggle`＋`start_on`
- [x] U117 `CameraRig` 鏡頭模式下拉：瞬切（預設，現在的行為）／房間內跟隨（跟著玩家但不超出目前房間，房間比畫面小的那一軸
	  固定在中心，換房間瞬切）／自由跟隨（忽略房間）；拿掉 `follow_player`（Showroom 改用自由跟隨）；`00b` §1 §3 更新

## 階段 24：時間軸（W1 補充）

> 講師決定：要一個方便擴增事件的計時器，像時間軸一樣「第 10 秒觸發某個事件」。
> 結構沿用 KeySettings＋KeyTrigger：`Timeline` 父節點底下放 `TimelineEvent` 子節點，一個子節點一列（`time` 拉桿＋`triggered` 訊號），
> 加一列就複製一個子節點。開始／死亡行為用欄位讓學員選，時間可勾選顯示在畫面上。

- [x] U118 `blocks/Timeline` ＋ `blocks/TimelineEvent`：`start_on`（開場就跑）、`on_death`（從 0 重來／繼續跑）、`loop`（跑完最後一個事件從頭再來）、
	  `show_time`（畫面右上角顯示秒數）；Receiver：`activate`（開始／繼續）、`deactivate`（暫停）、`toggle`、`restart`（從 0 重來）；
	  TimelineEvent 沒放在 Timeline 底下、Timeline 底下沒有事件、事件的 triggered 沒連線時有黃色驚嘆號／中文警告；
	  編輯器裡在 Timeline 旁列出「第幾秒｜事件名稱」並畫訊號虛線
	  　　→ 講師決定：秒數是「從時間軸開始算起的時間點」，不做「等上一列之後幾秒」的間隔模式；欄位說明與清單文字寫清楚

## 階段 25：規則卡抽卡（課堂輔助工具）

> 講師決定：規則卡另開一個專用場景，原本的 `CardDraw.tscn`（主限制卡）不動。

- [x] U119 抽規則卡場景 `levels/RuleCardDraw.tscn`（獨立場景，F6 直接執行）：上方下拉選自己的主限制卡（可以「不指定」），
	  按「抽規則卡」從 8 張隨機抽一張，自動排除 01b §4 會印警告的組合（只能往前×停下即死、只能往前×黏黏身體、
	  彈性宇宙×黏黏身體）；卡片資料 `data/rule_cards.tres`，`MechanicCard` 新增 `conflicts_with`（衝突的主限制卡檔名）

## 階段 26：過關畫面

> 講師決定：終點踩到之後畫面上什麼都不會發生（只有重生記憶清空），改成有一個簡單的過關畫面給終點接。
> 做成拖進關卡的零件；過關後暫停、按 R（專案既有的 restart 動作）整關重來；顯示用了幾秒、死了幾次，
> 再加一行製作者選填的文字。開關方塊沒卡、接收類零件關著沒人控制的警告先不做。

- [x] U120 `blocks/ClearScreen.tscn`：拖進關卡就自動接 `Events.level_cleared`（終點、存活計時卡），不用連線；也有 `activate()` 給訊號叫出來。
	  畫面：「過關！」、用了幾秒（`show_time`）、死了幾次（`show_deaths`）、選填一行 `message`、「按 R 再玩一次」；
	  過關時暫停遊戲，按 R 呼叫 RespawnHandler 新增的 `restart_level_now()` 整關重來（沒有 RespawnHandler 時印中文提醒、只關掉畫面）。
	  終點踩到後變色、整關重來時恢復；場景裡沒有過關畫面時，終點有黃色驚嘆號、過關當下印中文提醒

## 階段 27：最大速度

> 講師決定：學員反映反彈太快會穿牆（Player 沒有速度上限，彈性宇宙 bounciness > 1 時越彈越快）。
> Player「移動參數」群組加 `max_speed` 拉桿（400～2000，預設 1200），每幀移動前把總速度限制在這以內；
> 彈性宇宙 bounciness 維持 0.3～1.5（越彈越快當成玩法保留，由最大速度擋住）。

- [x] U121 `Player.max_speed`：`move_and_slide()` 前 `velocity.limit_length(max_speed)`，所有機制卡、零件推出來的速度一起限制；
	  `00_foundation` 與零件手冊補上這個參數

## 階段 28：不反彈方塊

> 講師決定：彈性宇宙卡沒辦法指定「撞到這個就停下來」，改 Layer 會變成穿過去。做一個拖進關卡的「不反彈方塊」：
> 實心地形，掛彈性宇宙卡的玩家撞到它照一般碰撞停下來，撞到其他地方照常反彈。

- [x] U122 `blocks/NoBounceBlock.tscn`：實心（圖層 2 地形），`width_tiles`／`height_tiles` 拉桿調大小（編輯器即時顯示），加入 group `no_bounce`；
	  彈性宇宙卡跳過撞到 `no_bounce` 的碰撞；`01a` §2 group 表、`01b` 彈性宇宙、`01c` 地形類、零件手冊補上

## 階段 29：傳送門目的地放寬

> 講師決定：傳送門的 pair 可以指定傳送門以外的東西，一樣傳得過去，但要有警告。

- [x] U123 `Portal.pair` 指定傳送門：照舊雙向配對；指定其他 2D 節點：傳到它的位置、只能單向，編輯器黃色驚嘆號＋執行時中文警告；
	  指定沒有位置的節點（不是 2D）：不傳送＋警告。被別座指到的傳送門不用自己設 pair（不再誤報）。編輯器畫一條紫色細虛線到目的地

## 階段 30：唯一的重生位置

> 講師決定：社課上學員在 Room1 踩了重生點，死掉卻回到 Room1 的房間起點（重生點擺在房間範圍外，順位輸給房間起點）。
> 改成全關卡只有一個「重生位置」，房間（進入時記房間起點）和重生點（踩到時記重生點）都能覆蓋它，死掉一律回到最後記下的那個；
> 學員可以各自設定什麼時候覆蓋。取代 U100「每個房間各記一個重生點」。

- [x] U124 `RespawnMemory` 改成只記一個重生位置；Room 新增 `start_trigger`（每次進入／只有第一次進入，預設每次，`use_room_start` 不勾時隱藏）；
	  Checkpoint 新增 `save_trigger`（每次踩到／只有第一次踩到，預設只有第一次；`repeatable` 只管 `reached` 訊號）；
	  重生造成的「進房間」不算存檔；RespawnHandler 重生位置＝記下的位置，沒有就回玩家一開始的位置；
	  `00b` §2 §4、零件手冊、README 更新；MultiRoomRespawnTest 步驟改寫

## 階段 31：脫殼卡

> 講師決定：社員提案「放大縮小（脫殼）」做成備品卡 `mechanics/_extra/Extra_Molt`，不加進抽卡資料。縮小時在原地留下一顆殼，Q/E 切換要留哪種殼，
> 脫殼時依方向鍵決定玩家從哪個方向脫出。設計重點是擴充性，分三層：
> 觸發（什麼時候脫殼、往哪脫出）＝脫殼卡；管理（選哪種殼、數量限制、死亡處理）＝脫殼卡；殼本身的特性＝殼模板＋特性組件。
> - 殼的種類＝脫殼卡底下的 `Shell` 子節點（子節點順序＝Q/E 切換順序），脫殼時複製一份放進場景；學員不用連線、不用填路徑。
>   卡片底下沒有任何殼時，自動使用內建的三種殼（蟬殼、塑膠殼、蜘蛛殼），拖進來就能玩。
> - 殼的特性用「特性組件」組合（`Shell` 底下拖 `Trait_*`），不在程式裡寫 `if 殼種類 == …`；重力、能不能推是 `Shell` 本身的勾選框。
> - 舊殼規則不寫死（講師猜是「同一種殼生出新的一顆時，舊的碎掉」）：每種殼各自設定數量上限、計算範圍（每個房間／整個關卡）、
>   滿了怎麼辦（最舊的碎掉／不能再脫）、可以脫幾次（0＝無限）。預設＝每個房間 1 顆、最舊的碎掉、無限次。
> - 玩家死亡時殼怎麼處理做成下拉（全部清掉／保留），另外提供公開函式 `clear_shells()`，也可以被訊號呼叫。
> - 「縮小時脫殼」聽 `Events.mechanic_event("Mechanic_SizeShift", "shrank")` 廣播，不直接引用忽大忽小卡；
>   也可以選「按下按鍵」脫殼，沒有忽大忽小卡也能用。選「縮小時」但場景裡沒有忽大忽小卡要有中文警告。

- [x] U125 殼本體 `Shell`（RigidBody2D，跟箱子同一圖層）：`use_gravity`、`can_push` 勾選框（蜘蛛殼＝兩個都關）、
	  數量上限／計算範圍／滿了怎麼辦／可脫次數欄位；`break_shell()` 碎掉；特性組件基底 `ShellTrait`（殼找自己底下的子節點呼叫 `setup(shell)`，
	  跟 Player 找機制卡同一個模式）；殼模板與特性放 `mechanics/_extra/_molt/`，冒煙測試掃 `mechanics/` 時跳過根節點不是機制卡的場景
	  （驗證：`tests/mechanics/_extra/ShellTest.tscn` 直接擺幾顆不同設定的殼）
- [x] U126 `Extra_Molt` 脫殼卡：觸發時機下拉（縮小時／按下按鍵）；在玩家位置複製目前選中的殼模板，剛生出來時不跟玩家互撞；
	  脫出方向依方向鍵，優先順序下拉（預設 上 > 左右 > 下）＋脫出力道拉桿；卡片底下沒有殼就用內建三種；
	  卡片底下放了不是 `Shell` 的東西、選縮小時但沒有忽大忽小卡 → 黃色驚嘆號／中文警告
	  　　→ 講師決定：驗收時發現站在地上按 Shift 不會變大、再按一次卻脫出一顆小殼。忽大忽小卡改成腳底不動、往頭頂伸縮
	  　　（站在地上也能變大，頭頂卡住才延後）；等待變大時再按一次＝取消變大，不發 `shrank`，改發新訊號 `grow_canceled`
	  　　（學員之後可以接「無效」提示）
	  　　→ 講師決定：脫殼後玩家窩在殼裡也符合意象，做成勾選框 `start_inside`（預設勾＝窩在殼裡慢慢鑽出來；
	  　　不勾＝直接擠到殼外面、緊貼脫出方向那一側，那裡被地形擋住時退回窩在殼裡）；
	  　　不勾時多一個下拉 `default_direction`（上／面向的方向／背對的方向／下），沒按方向鍵就往這個方向脫出
	  　　→ 講師決定：殼的顏色下拉多一個「自訂」，選了才出現 `custom_color` 調色盤（可以貼色碼）
- [x] U127 Q/E 切換（按鍵可改，預設 Q／E）＋目前選中的殼在畫面上看得到；數量上限照殼的設定執行（依「殼模板＋所在房間」計數）；
	  死亡處理下拉（全部清掉／保留，清掉時可脫次數一起恢復）＋公開 `clear_shells()`；`shell_created`、`shell_changed` 訊號給學員接特效
	  　　→ 講師決定：選中的殼怎麼顯示、死亡時什麼時候清掉都做成選項。`show_selected`（玩家頭上／畫面右上角／兩個都要／不顯示，
	  　　預設玩家頭上；只有一種殼又不限次數時頭上不顯示）；`on_death`（重生時清掉／死掉時馬上清掉／保留，預設重生時清掉）。
	  　　另外加 `molt_blocked` 訊號（次數用完、數量滿了又不能再脫），可以接「無效」提示。
	  　　數量上限的房間＝脫殼當下殼所在的房間（之後被推到別的房間也還算原本的房間）
- [x] U128 內建三種殼：蟬殼（什麼都不加）、塑膠殼（`Trait_Bouncy`：玩家、箱子、其他殼碰到會自動彈起，比一般跳躍高）、
	  蜘蛛殼（不受重力、推不動）
- [x] U129 文件：`01b` §5 備品庫新增脫殼卡與「自己做一種殼」的步驟、訊號表、零件手冊、速查表

---

# W3：手感果汁（`03_game_feel_juice.md`）

> 講師決定：規格放 `documents/03_game_feel_juice.md`；音效先由 Claude 找 CC0 素材；學員可以把自己的音檔拖進 `Juice_Sound` 的欄位（資源欄位例外，見 `CLAUDE.md`）；
> 機制卡、零件的事件不做成觸發時機下拉，一律用訊號連到 Juice 的 `play()`；核心組件加上「咕嚕眼」。

## 階段 32：果汁地基

- [ ] U130 Player 表現層 API：`set_juice_squash`／`set_juice_tint`／`set_juice_tilt`／`clear_juice`（`player/JuiceLayer.gd`，依 source 相乘合成，
      作用在 `Visual` 的子節點、腳底為中心、全部撤掉時還原）（驗證：`tests/systems/JuiceLayerTest.tscn`，跟忽大忽小、重力翻轉、自動奔跑一起作用不互蓋）
　　→ 已實作、已 commit，**尚未驗收**（驗收通過後再打勾）
- [ ] U131 `JuiceBase` 擴充：觸發時機 13 種、`follow_impact`、`play()` 接受任意參數（連線驗證器不誤報）、事件位置、0.05 秒連發保護、
      重生 `_on_reset()`、`_exit_tree()` 還原；持續型隱藏 `timing`（驗證：`tests/systems/JuiceBaseTest.tscn`，每種時機印出一行）
- [ ] U132 `JuiceSwitch` 自動載入：`F1` 切換全部 Juice、右上角顯示兩秒（驗證：`tests/systems/JuiceSwitchTest.tscn`）
- [ ] U133 `CameraRig` 震動改成取比較強的、`Events.zoom_requested` 鏡頭推近（含房間內跟隨的範圍計算）；`00_foundation` §2、`01a` §7 事件表補上

## 階段 33：核心組件

- [ ] U134 `Juice_ScreenShake` 螢幕震動
- [ ] U135 `Juice_HitStop` 頓幀
- [ ] U136 `Juice_SquashStretch` 擠壓拉伸
- [ ] U137 `Juice_Flash` 閃色
- [ ] U138 `Juice_Particles` 粒子噴發（`CPUParticles2D`，四種樣式）
- [ ] U139 音效素材：找 CC0 音效（或 sfxr 生成）至少 8 種放 `sfx/`，`sfx/CREDITS.md` 寫出處與授權
- [ ] U140 `Juice_Sound` 音效（內建下拉＋「自訂」資源欄位四點防呆中適用的部分）
- [ ] U141 `Juice_CameraZoom` 鏡頭推近
- [ ] U142 `Juice_Trail` 殘影
- [ ] U143 `Juice_GooglyEyes` 咕嚕眼（`@tool` 編輯器預覽、拖節點決定眼睛位置、彈簧眼珠、跟著翻轉／體型）

## 階段 34：備品與收尾

- [ ] U144 備品 `Juice_TextPopup` 跳字、`Juice_ScreenFlash` 全螢幕閃光
- [ ] U145 備品 `Juice_Tilt` 傾斜、`Juice_DeathBurst` 死亡爆散
- [ ] U146 `levels/_starts/W3_JuiceBox.tscn` 起始場景、`Gym.tscn` 示範佈置
- [ ] U147 煙霧測試補上 §6 的項目、零件手冊／速查表／README 補 W3，跑一次煙霧測試
