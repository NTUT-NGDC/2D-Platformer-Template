# 00 — 地基

> 前置閱讀：`CLAUDE.md`
> 這份規格是所有週次的前提，必須先完成並通過驗收才進行 `01-week1-mechanics.md`。

---

## 1. 資料夾結構

```
res://
├── _my/                      # 學員的全部身家，唯一可寫區
│   ├── MyGym.tscn            # W1：從 Gym.tscn 另存
│   └── art/                  # W4：學員自己下載的素材
│       └── .gdkeep
├── _help/                    # 操作速查表與 FAQ（放圖文，非程式）
├── _tests/
│   └── SmokeTest.tscn        # 自動化煙霧測試
├── autoload/
│   └── Events.gd             # 全域事件匯流排
├── player/
│   ├── Player.tscn
│   ├── Player.gd             # 唯一的物理腳本，學員禁區
│   └── MoveContext.gd
├── mechanics/                # W1：一張卡 = 一個 .tscn
│   ├── _base/
│   │   └── MechanicBase.gd
│   └── _extra/               # 備品庫，平常不介紹
├── juice/                    # W3
│   └── _base/
│       └── JuiceBase.gd
├── blocks/                   # W2：平台、機關、敵人
├── levels/
│   ├── Gym.tscn              # W1 通用測試場
│   ├── _Template.tscn        # W2 已框好的空關卡
│   ├── _starts/              # 中途加入者的起始場景
│   │   └── .gdkeep
│   └── examples/             # W2 臨摹範例
├── art/                      # 講師提供的素材自助餐
└── sfx/
```

`.gdkeep` 是空檔案，用來讓 Godot 保留空資料夾。

---

## 2. Autoload：Events

`autoload/Events.gd`，在 Project Settings 註冊為 Autoload，名稱 `Events`。

```gdscript
extends Node

# 玩家事件（由 Player 轉發，方便跨場景組件接收）
signal player_jumped
signal player_landed(impact_force: float)
signal player_hurt
signal player_died

# 世界事件
signal enemy_died(pos: Vector2)
signal item_collected(pos: Vector2)
signal level_cleared
signal level_restarted

# 表現層請求（W3 Juice 用，讓組件不必知道攝影機在哪）
signal shake_requested(strength: float, duration: float)
signal hitstop_requested(duration: float)
```

**設計理由**：ScreenShake 組件掛在 Player 底下，但攝影機在關卡場景裡。透過匯流排，組件只負責 emit，實際執行由關卡裡的接收器負責，學員完全不需要連線。

---

## 3. Player

### 3.1 節點結構

`player/Player.tscn`（唯讀區，出廠就這樣，學員不會編輯它）：

```
Player (CharacterBody2D)  [script: Player.gd]
└── CollisionShape2D
```

**注意：`Sprite2D` 不放在這裡。** 視覺節點住在關卡場景裡（見 3.5），這樣 W4 換皮改的是學員自己的檔案。

關卡場景裡的 Player 實例長這樣（由 `Gym.tscn` / `_Template.tscn` 出廠附好）：

```
Player (player/Player.tscn 的實例)
├── Visual (Node2D)      [group: "player_visual"]
│   └── Sprite2D
├── Mechanics (Node2D)   ← W1：機制卡拖進來
└── Juice (Node2D)       ← W3：手感組件拖進來
```

這三個子節點存在**關卡場景檔**裡，所以學員的所有操作都寫進 `_my/`。

### 3.2 訊號

```gdscript
signal jumped
signal landed(impact_force: float)   # impact_force = 落地瞬間的 velocity.y 絕對值
signal hurt
signal died
signal direction_changed(dir: int)   # -1 左, 1 右
signal wall_hit
signal started_moving
signal stopped_moving
```

每個訊號 emit 時，同步轉發對應的 `Events.player_*`。

### 3.3 匯出參數

```gdscript
@export_group("移動參數")
## 水平移動速度，數值愈大角色跑得愈快。
@export_range(50.0, 500.0) var 移動速度: float = 200.0
## 跳躍瞬間的初始速度，數值愈大跳得愈高。
@export_range(100.0, 800.0) var 跳躍力: float = 400.0
## 重力加速度，數值愈大角色下墜（或重力翻轉後上升）愈快。
@export_range(200.0, 2000.0) var 重力: float = 980.0
## 地面摩擦係數：0 = 像冰面一樣滑不停，1 = 放開方向鍵立刻煞停。
@export_range(0.0, 1.0) var 地面摩擦: float = 0.8
```

這是課程規則，不是物件身分的一部分，所以群組名稱用平實的「移動參數」，預設展開，不用警示圖示——紅色禁止圖示對新手來說容易被誤認成錯誤訊息。W1 一開始就要讓學員自己調跳躍／移動手感，每個變數上方用 `##` 寫中文說明，滑鼠停在 Inspector 欄位上會顯示成 tooltip。

**機制卡的參數一律不放在這裡**，放在各自的機制節點上（見 `01-week1-mechanics.md`）。

### 3.4 零連線的發現機制

Player 在 `_ready()` 自己找子節點並主動註冊，組件完全不需要知道 Player 在哪：

```gdscript
func _ready() -> void:
    _register_children($Mechanics if has_node("Mechanics") else null)
    _register_children($Juice if has_node("Juice") else null)

func _register_children(container: Node) -> void:
    if container == null:
        return
    for child in container.get_children():
        if child.has_method("setup"):
            child.setup(self)
        else:
            push_warning("[Player] %s 沒有 setup()，可能不是合法的組件" % child.name)
    # 學員在執行中拖入節點時也要生效
    container.child_entered_tree.connect(func(n):
        if n.has_method("setup"):
            n.setup(self)
    )
```

**這是整份架構的核心，不要改成讓組件自己往上找 Player。**

### 3.5 視覺節點

Player 用群組找視覺節點，不用路徑：

```gdscript
var visual: Node2D = null

func _ready() -> void:
    for n in get_tree().get_nodes_in_group("player_visual"):
        if is_ancestor_of(n):
            visual = n
            break
```

W3 的 SquashStretch 等組件透過 `player.visual` 操作，所以換皮後仍然有效。

### 3.6 提供給機制卡的公開 API

機制卡**不得直接寫 `velocity`**，只能呼叫這些方法：

```gdscript
func flip_gravity() -> void          # 重力翻轉
func add_impulse(v: Vector2) -> void # 施加瞬間衝量（後座力、彈跳）
func set_size_factor(f: float) -> void
func take_damage(amount: float = 1.0) -> void
func kill() -> void
func force_jump(power_scale: float = 1.0) -> void
func is_on_ground() -> bool
func get_move_input() -> float       # -1 ~ 1
```

### 3.7 MoveContext：每幀的修改管線

`player/MoveContext.gd`，是一個 `RefCounted`：

```gdscript
extends RefCounted
class_name MoveContext

var speed_scale: float = 1.0
var jump_scale: float = 1.0
var gravity_scale: float = 1.0
var friction_scale: float = 1.0
var auto_run_dir: int = 0        # 0 = 不強制，-1/1 = 強制方向
var input_locked: bool = false
var delta: float = 0.0
```

Player 的 `_physics_process` 流程固定為：

1. 建立 `MoveContext`，填入 `delta`
2. 依序呼叫每張機制卡的 `apply(ctx)`（有實作才呼叫）
3. 用 ctx 裡的倍率計算最終 velocity
4. `move_and_slide()`
5. 偵測狀態變化並 emit 訊號

**好處**：機制卡只能調整倍率與旗標，物理計算的權責完全留在 Player，所以學員掛任何組合都不會把物理弄壞。

---

## 4. 組件基底類別

### 4.1 MechanicBase

`mechanics/_base/MechanicBase.gd`：

```gdscript
extends Node2D
class_name MechanicBase

@export var 啟用: bool = true

var player: Node = null

func setup(p: Node) -> void:
    player = p
    _on_setup()
    print("[%s] 已啟用" % name)

## 子類別覆寫：接訊號、初始化
func _on_setup() -> void:
    pass

## 子類別覆寫：每個物理幀修改移動參數
func apply(_ctx: MoveContext) -> void:
    pass

func _ready() -> void:
    # 沒有被 setup 就是掛錯位置了，要看得見
    await get_tree().process_frame
    if player == null:
        push_warning("[%s] 沒有掛在 Player 的 Mechanics 底下，不會生效" % name)
        printerr("⚠ [%s] 請把這個節點拖進 Player → Mechanics 底下" % name)
```

### 4.2 JuiceBase

`juice/_base/JuiceBase.gd`，同樣的 `setup()` / `player` / `_ready()` 警告結構，加上：

```gdscript
@export_enum("跳躍時", "落地時", "受傷時", "死亡時", "撞牆時", "不自動觸發")
var 觸發時機: int = 1

func _connect_trigger(callback: Callable) -> void:
    match 觸發時機:
        0: player.jumped.connect(callback)
        1: player.landed.connect(func(_f): callback.call())
        2: player.hurt.connect(callback)
        3: player.died.connect(callback)
        4: player.wall_hit.connect(callback)
        5: pass
```

---

## 5. 關卡場景

### 5.1 共用元件

`Gym.tscn` 與 `_Template.tscn` 都必須內建（學員不會碰到）：

- `Camera2D`，掛 `CameraRig.gd`：接 `Events.shake_requested`，執行螢幕震動
  - **固定視角，不跟隨玩家。** `Camera2D` 是關卡場景根節點底下的獨立節點，**不掛在 Player 實例底下**，跟 Player 之間沒有父子關係。
  - 每個關卡場景自行決定 `Camera2D` 要放在哪個座標（通常對準該關卡的可視範圍中心），之後所有週次的新關卡都比照辦理，不會因為切場景而改成跟隨。
  - 螢幕震動照樣透過 `Events.shake_requested` 接收，跟掛在哪裡無關，所以這個規則不影響零連線設計。
- `HitStopManager`（Autoload 或關卡節點）：接 `Events.hitstop_requested`
  - **`Engine.time_scale` 是全域的，必須有單例保護**
  - 時長上限鎖 `0.3` 秒
  - 已在頓幀中時，新請求直接忽略，不得疊加
  - 結束後必須保證 `Engine.time_scale = 1.0`
- `Respawn.gd`：玩家死亡後 1 秒自動重生，emit `Events.level_restarted`

### 5.2 `_my/MyGym.tscn`

W1 開場時學員做的第一件事是把 `levels/Gym.tscn` 另存為 `_my/MyGym.tscn`。
Gym 的內容規格見 `01-week1-mechanics.md`。

---

## 6. 匯出設定

`export_presets.cfg` **必須隨包發出，不得列入 .gitignore**。

預先建立兩個 preset：

| 名稱 | 平台 | 輸出路徑 |
|---|---|---|
| `Web` | Web | `build/web/index.html` |
| `Windows` | Windows Desktop | `build/windows/game.exe` |

Web preset 要求：
- `Head Include` 留空即可，SharedArrayBuffer 由 itch.io 端設定
- 確認 `Export With Debug` 關閉

學員每週的上傳流程必須是：**Project → Export → 選 Web → Export Project → 按一個按鈕**，不做任何設定。

### .gitignore

```gitignore
# Godot 4
.godot/
/android/

# 匯出產物
build/

# 保留匯出設定（學員需要它才能一鍵打包）
!export_presets.cfg
```

---

## 7. 煙霧測試

`_tests/SmokeTest.tscn` + `SmokeTest.gd`，用 `--headless` 執行，要求：

1. 載入 Player，逐一實例化 `mechanics/` 底下**每一個** `.tscn`，各自掛上跑 60 幀
2. 隨機組合 3 個機制卡同時掛載，跑 60 幀
3. 逐一實例化 `juice/` 底下每一個組件，跑 60 幀
4. 同時掛 6 個 Juice 組件，跑 60 幀
5. 觸發 `Events.hitstop_requested` 10 次，確認結束後 `Engine.time_scale == 1.0`
6. 每個階段結束後拔掉所有組件，確認 Player 仍能正常移動
7. 任何一項失敗：`printerr` 說明 + `get_tree().quit(1)`
8. 全部通過：`print("SMOKE TEST PASSED")` + `quit(0)`

**新增任何機制卡或 Juice 組件時，測試會自動掃資料夾，不需要手動維護清單。**

---

## 8. 驗收條件

全部通過才算地基完成：

- [ ] `godot --headless --check-only --path .` 無錯誤
- [ ] `godot --headless --path . res://_tests/SmokeTest.tscn` 印出 `SMOKE TEST PASSED`
- [ ] 把任一 `MechanicBase` 子類別拖進 Player → Mechanics 底下，**不連任何線**即生效
- [ ] 把同一個組件拖到**錯誤位置**（例如直接拖到關卡根節點），輸出面板出現中文警告，遊戲不崩潰
- [ ] 刪掉 Mechanics 與 Juice 兩個容器節點，遊戲仍能跑
- [ ] `player/Player.gd` 裡沒有任何具名機制卡的邏輯
- [ ] 存檔關卡後，`git status` 只顯示 `_my/` 底下的檔案有變更
- [ ] Web 與 Windows 兩個 preset 都能成功匯出