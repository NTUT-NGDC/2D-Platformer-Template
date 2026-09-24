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
      `tests/InputRouterTest.tscn` 點滑鼠左鍵，高優先權與學員都收到、低優先權被擋；放開右鍵印出秒數）
- [x] U65 `KeyTrigger` 按鍵來源可選滑鼠左鍵／右鍵／中鍵（驗證：`tests/KeyTriggerTest.tscn` 按住滑鼠右鍵再放開，
      印出 pressed → released；Inspector 切到滑鼠選項時 action／key 都隱藏）
- [x] U66 攻擊能力（近戰／遠程）與有按鍵欄位的機制卡（重力翻轉／忽大忽小／衝刺）可改用滑鼠按鍵（驗證：
      `tests/Ability_RangedTest.tscn` 點滑鼠左鍵，`Ability_Ranged_Mouse` 發射子彈）
- [x] U67 `Mechanic_Slingshot` 改走 `InputRouter`，不再直接讀滑鼠（驗證：`tests/Mechanic_SlingshotTest.tscn`
      拖曳／放開發射行為跟以前一樣）
- [x] U68 `Mechanic_Slingshot` 比照近戰在 Inspector 選拖曳鍵（`input_type` + `key`，預設滑鼠左鍵）（驗證：
      `tests/Mechanic_SlingshotTest.tscn` 把 `input_type` 改成滑鼠右鍵，右鍵拖曳能發射、左鍵沒反應）
