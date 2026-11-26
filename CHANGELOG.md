# Changelog

All notable changes to **Pact Arena (血契竞技场)** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.1] - 2026-11-27

### Balanced
- **无尽模式“等弹性收支平衡”重构（参考 Brotato 无尽 / Risk of Rain 2 经济曲线）**：
  - 修复此前无尽第 11+ 波物价按 `1.22^(wave-10)` 单边指数暴涨、而怪物掉晶与利息上限锁死导致第 15 波后完全买不起装备的问题。
  - 在 [CombatFormulas.gd](src/core/CombatFormulas.gd) 新增 `calc_endless_income_mult(wave)`（第 10 波及以前保持 `1.0x`，无尽第 11+ 波起按 **`1.09^(wave-10)`** 增长），同步作用于怪物击杀血晶掉落（含对小怪整数截断采用随机小数四舍五入保真，[EnemyManager.gd](src/combat/EnemyManager.gd)）、宝箱固定血晶加成（[PickupManager.gd](src/combat/PickupManager.gd)）、波间收获加成与利息封顶上限（[RunState.gd](src/core/RunState.gd) `75 * 1.09^(wave-10)`）。
  - 将无尽模式黑市波次通胀调优为 **`1.12^(wave-10)`**、黑市熔炉调优为 **`1.09^(wave-10)`**、刷新费用随 `calc_endless_income_mult` 同步上浮，保持“每波仅比上波温和收紧约 `2.75%` 实际购买力”，即使打到第 20~30 波，每波结束后仍能稳定购入 1~2 件关键提升对抗高强怪潮。

## [2.4.0] - 2026-11-26

### Changed & Added
- **中后期黑市物价递进通胀**：升级 [CombatFormulas.gd](src/core/CombatFormulas.gd) `calc_wave_inflation()` 为混合线性幂次曲线（`1.0 + 0.24*w + 0.038*w^1.65`，第 10 波约 `4.59×`，无尽第 11+ 波叠乘 `1.22^(wave-10)`），同步强化三大黑市淬炼熔炉（`calc_shop_sink_cost()`）随波次递进消耗；新增商品 `roll_wave` 与武器 `buy_wave`（[ShopGenerator.gd](src/core/ShopGenerator.gd) / [RunState.gd](src/core/RunState.gd)），锁定保留享受当波原价且杜绝低买高卖套利。
- **同款被动道具指数级累购加价**：重复购买同种被动道具新增 `calc_duplicate_item_mult()`（`1.50^已持有数`，最高计至 16 层），通过 `ShopGenerator.calc_live_offer_price()` 在刷出时及购买后实时刷新货架其余同款价格，防止单件高收益道具无限囤积引发属性指数膨胀（武器保留同款合成升阶路线免税）。
- **全局已购道具清单与累计加成追踪**：在 [RunState.gd](src/core/RunState.gd) 新增 `get_item_count()`、`get_item_counts_summary()` 与 `format_item_mods_summary()`；在商店 [ShopScreen.gd](src/ui/ShopScreen.gd) 新增顶部 **「已购道具」** 居中弹窗与武器栏下方横向徽章条（点击可看单件/累计加成及下件同款倍率），并在战斗暂停界面（[BattleHud.gd](src/ui/BattleHud.gd)）与结算报告（[RunSummaryScreen.gd](src/ui/RunSummaryScreen.gd)）完整展示已购道具清单。

## [2.3.0] - 2026-11-25

### Improved & Polished
- **怪物刷怪预警法阵与破阵入场动效**：新增 [EnemyManager.gd](src/combat/EnemyManager.gd) `queue_spawn_enemy()` 与地面着陆法阵 Shader 倒计时（常规怪 `0.65s`、精英 `0.85s`、Boss `0.95s`），入场瞬间带 `0.22s` 缩放浮现动效且期间免疫接触误伤；收紧并拉远安全生成环带至 `310–505px`（[ArenaController.gd](src/combat/ArenaController.gd)），彻底告别贴脸闪现撞怪。
- **全界面触控手感与移动端图标放大升级**：升级 [UiStyles.gd](src/ui/UiStyles.gd) 全局面板阴影、按钮按压回弹缩放动效（`_attach_touch_bounce`）及弹窗渐入动画；放大主界面（[MainMenu.gd](src/ui/MainMenu.gd)）、战斗 HUD（[BattleHud.gd](src/ui/BattleHud.gd) 血晶图标与羁绊徽章）、商店/黑市（[ShopScreen.gd](src/ui/ShopScreen.gd) 72px 商品图与 52px 触控键）、图鉴（[CodexScreen.gd](src/ui/CodexScreen.gd) 80px 武器图与 72px 道具图）及出征备战（[HeroSelectScreen.gd](src/ui/HeroSelectScreen.gd) 96px 头像与初始武器图标栏）。
- **信息分层减负与全界面居中大弹窗重构**：新增通用 `UiStyles.show_detail_modal()` 与 `UiStyles.make_centered_modal_shell()`；出征界面 **「热度加码」**（8 项全宽大卡片 + 全选/清空/确认）、商店 **「羁绊」/「属性」**（2 列大字面板）、图鉴 **「神系羁绊总览」**、设置与暂停界面全部升级为带暗色遮罩的居中大型弹窗，彻底告别窄框内联折叠难操作与文字拥挤问题。同时拓宽 `D0~D5` 难度档位卡片宽度以完整容纳高阶文案。
- **全游戏文案玩家化润色**：全面重写 [GameData.gd](src/autoload/GameData.gd) 与各 UI 文案，剔除开发/AI 式术语（如“通过固有加成生效”、像素数值、生硬括号长句），统一为直白干脆的暗黑肉鸽战斗行话。

## [2.2.1] - 2026-11-25

### Added & Improved
- **全套 18 种被动道具与 3 项黑市淬炼服务 Nano Banana 专属图标**：
  - 使用 **Nano Banana** 生成全套暗黑赛博金属与魔导风格道具图集，并通过 [process_nano_assets.py](tools/process_nano_assets.py) 完成背景透明抠图、去白边/黑晕与居中缩放，输出 21 张 `128×128` 透明 PNG 精灵至 [assets/art/sprites/items](assets/art/sprites/items)。
  - **界面全面实装图标展示**：[ShopScreen.gd](src/ui/ShopScreen.gd)（道具货架卡片 `62×62` 与黑市淬炼卡片 `54×54`）、[CodexScreen.gd](src/ui/CodexScreen.gd)（18 种道具图鉴 `58×58`）与 [LevelUpModal.gd](src/ui/LevelUpModal.gd)（宝箱开出道具弹窗 `78×78`）均已接入配套图标渲染。
  - **资源校验增强**：[TestSuite.gd](tests/TestSuite.gd) 新增全部 18 种道具与 3 项黑市淬炼服务的 `ResourceLoader.exists()` 加载断言。

## [2.2.0] - 2026-11-25

### Changed & Rebalanced
- **深渊难度分级系统 D0 ~ D5**：在保留 8 项自主「热度词缀」基础上新增 **6 阶核心难度（D0 试炼 ~ D5 深渊终焉）**，于出征备战界面（[HeroSelectScreen.gd](src/ui/HeroSelectScreen.gd)）横向选择，支持记忆与通关星标认证；高阶难度全面拉升敌方生命、伤害、移速、刷怪密度、精英数量、商品通胀及 Boss 护卫，同时抑制高难度波间免费回血，并提供高达 **+190%** 的深渊余烬奖励加成。
- **后期多余血晶回收与黑市通胀模型（参考 Brotato / Hades）**：
  - 商店新增无限次递增消费的 **「深渊黑市淬炼」** 三大消耗槽位（[ShopScreen.gd](src/ui/ShopScreen.gd) / [RunState.gd](src/core/RunState.gd)）：`深渊武器淬炼`（全伤害/暴击）、`鲜血铸体仪式`（最大生命/护甲/移速）与 `黑市遗物盲盒`（随机未禁用道具），确保大后期富余血晶可稳定转化为战力成长。
  - 引入随波次与难度递进的商店通胀、刷新费用二次递增机制，抑制低成本无尽白嫖；下调波间利息来源并新增「黄金契约使」持有血晶增伤上限，防止滚雪球失控。
- **战斗数值与 Boss 机制重塑（终结后期秒杀与怪死屏外）**：
  - 紧缩高阶武器与血契的极端乘算膨胀系数，并大幅上调第 4 波以后常规怪物生命值以及第 5 波《赤潮审判官》（6,200 基础血量）、第 10 波《深渊双生主宰》（28,000 基础血量）的复合波次成长。
  - 为高难精英怪与 Boss 加入 **韧性减伤机制（`resilience`）**（可用「血步瞬移」的破甲状态强行穿透）及 **1.2 秒入场护盾** 与击退抗性（[EnemyManager.gd](src/combat/EnemyManager.gd)）；D4/D5 下 Boss 入场携带精英裁决者侍卫。
  - 收紧怪物出生环带至主角周围 `265–480px`（[ArenaController.gd](src/combat/ArenaController.gd)），确保怪潮进入手机视野正面交锋，不再于屏外悄然蒸发光。

## [2.0.3] - 2026-11-25

### Added & Changed
- **场景状态自适应 BGM 套装 v01 落地**：按 [bgm_arena_soundtrack_loop_set_v01_prompt.md](docs/bgm_arena_soundtrack_loop_set_v01_prompt.md) 规格生成并导入三首纯器乐循环配乐——圣所整备 `sanctuary`、常规波次 `combat`、Boss 决战 `boss`；统一 `128 BPM` / `4/4` / `D 小调` / `≈90 s`，44100 Hz 立体声、160 kbps Vorbis，-15.5 LUFS、真峰值 ≤ -1.0 dBTP，1.6 s 等功率首尾交叉淡化无缝循环，替换原程序化临时占位 BGM。
- **后期导入管线升级**（[import_bgm.py](tools/import_bgm.py)）：新增 EBU R128 双通响度归一与真峰值限制、44.1 kHz 16-bit PCM 母带归档、v01 长名与引擎兼容短名双份 OGG 落盘；-60 dBFS 二次深静音裁边、首 20 ms 微淡入防 onset 咔哒、160 kbps ABR 码率锁定；验收报告覆盖集成响度 / 真峰值 / 时长 / 首尾静音 / 码率 / 曲目间响度差。

## [2.1.0] - 2026-11-25

### Improved & Added
- **全套立体声战斗与 UI 短音效重构（27 项）**：升级 [generate_audio.py](tools/generate_audio.py) 为 44.1 kHz 双声道立体声物理/FM 合成管线（`fft_filter` 频谱塑形、`fm_strike` 非谐波金属泛音、`stereo_chorus_sweep` 声场展宽、`saturate` 饱和激励与 `add_early_room` 早期空间混响），全面重做武器开火、暴击、破甲、血步、拾取、祭坛、Boss 预警及 UI 点击手感音效。
- **全面实装豆包 AI 定制高保真主题配乐（3 首 BGM）**：基于 13 章节规范文档 [bgm_arena_soundtrack_loop_set_v01_prompt.md](docs/bgm_arena_soundtrack_loop_set_v01_prompt.md) 与 [import_bgm.py](tools/import_bgm.py)，将三首 ~90 秒、44.1 kHz 立体声 `-15.5 LUFS` 纯器乐原声（`bgm_sanctuary`、`bgm_combat`、`bgm_boss`）接入运行库并开启底层 `loop=true` 无缝循环。
- **测试校验增强**：在 [TestSuite.gd](tests/TestSuite.gd) 中增加全部 27 个 `.ogg` 短音效与 3 首无缝循环 BGM 的加载校验断言。

## [2.0.2] - 2026-11-25

### Improved & Fixed
- **全面补全神系羁绊与融合共鸣效果说明**：
  - [SynergyEngine.gd](src/core/SynergyEngine.gd) 与 [UiStyles.gd](src/ui/UiStyles.gd) 集中定义并格式化三神系（猩红 / 苍蓝 / 虚空）2/4/6 阶具体加成与三项双神融合共鸣（血雷风暴 / 嗜魂诅咒 / 虚空磁暴）。
  - **商店界面（[ShopScreen.gd](src/ui/ShopScreen.gd)）**：顶部实时展示当前已生效的羁绊/共鸣具体数值效果；新增「羁绊」抽屉详情按钮，高亮已激活档位并展示未达成目标，武器货架卡片同步标出所属神系当前持有计数。
  - **图鉴与备战/战斗 HUD（[CodexScreen.gd](src/ui/CodexScreen.gd) / [HeroSelectScreen.gd](src/ui/HeroSelectScreen.gd) / [BattleHud.gd](src/ui/BattleHud.gd)）**：图鉴顶部新增全羁绊与双神共鸣说明；出征备战初始武器按钮标明神系；战斗 HUD 展示阶位进度与共鸣图标，暂停弹窗列出当前生效羁绊详情。
- **修复全界面滚动容器在图标/卡片/按钮上无法拖动的问题（[TouchScrollContainer.gd](src/ui/TouchScrollContainer.gd)）**：
  - 将全部列表及横向选择条迁移至 `TouchScrollContainer`，自动将子树内 `PanelContainer`、`Button`、`CheckButton`、`ColorRect` 等默认 `MOUSE_FILTER_STOP` 控件设为 `MOUSE_FILTER_PASS`（同时保留有意的 `MOUSE_FILTER_IGNORE` 遮罩），并配置 `14px` 滑动死区配合 `NOTIFICATION_SCROLL_BEGIN` 防误触点击，兼顾移动端触控滑动与桌面端鼠标左键拖拽/滚轮滚动。

## [2.0.1] - 2026-11-25

### Fixed
- **高阶武器直接替换机制（修复「独臂修罗」武器锁死问题）**：当武器槽位已满（包含单槽位英雄「独臂修罗」）且商店刷新出高于现有同种武器阶级的商品时，新增 `replace` 替换模式，商店卡片将高亮显示 `▲可替换升阶!` 与 `替换 $价格`，可直接购买并替换队内最低阶的同款武器（替换为 IV 阶红武时正常触发觉醒选择）。
- **修复血契「不灭献祭」隐藏降阶 Bug**：移除 `pact_undying_sacrifice` 中未在文案说明的「全武器阶级 -1」惩罚逻辑，使其效果与描述完全一致（全伤害暂时 -15%、当前生命上限 -10%、获得 1 次深渊免死复活护佑，且每波自动成长 +8% 伤害）。

## [2.0.0] - 2026-11-25

### Changed & Improved
- **Nano Banana 现代美术重制**：全面替换 6 位英雄、8 类敌怪、2 大机制 Boss、14 把武器、掉落物、地面瓷砖、血契法阵及全套 Android UI 图标与主界面 Key Art 背景。
- **全新动画系统重构**：
  - 主角新增待机呼吸、跑步动态倾斜弹跳、踏地微尘、血步拉伸残影与受击压缩反弹动画。
  - 敌怪与 Boss 新增差异化步伐晃动、受击挤压拉伸、脚底投影与环绕法阵旋转脉冲。
  - 武器新增悬浮呼吸、近战弧线大幅挥砍、长矛前冲突刺、枪械后坐力与枪口闪光、阶梯光环特效。
  - 全部界面弹窗与导航页面新增平滑弹性弹出动效 (`animate_pop_in`)。
- **Android 原生风格主界面布局重构**：全屏 Key Art 背景 + 上升余烬光球 + 居中动态英雄展示 + 顶部余烬/设置齿轮栏 + 底部「踏入竞技场」大主按钮与 3 枚大尺寸安卓图标导航瓷砖。
- **血步冷却倒计时可视化升级**：实时显示精确到 `0.1s` 的剩余秒数（0 层时居中大倒计时，1/2 层时保留可用同时展示下一次充能倒计时），搭配按钮内自底向上扫光填充、双格充能进度条与充能就绪弹跳闪烁反馈。

## [1.0.0] - 2026-11-25

### Added
- **核心战斗体系**：基于空间哈希网格与对象池的 Godot 4.7.2 竖屏竞技场，支持 2 层充能「血步瞬移」（穿怪破甲 + 重置近战武器冷却）。
- **构筑与流派内容**：
  - 6 位机制各异的可选英雄（含局内挑战解锁与余烬提前解禁）。
  - 14 把武器 × 4 阶品质 × 28 条四阶红武觉醒分支。
  - 三神系羁绊（猩红 / 苍蓝 / 虚空 2/4/6 阶）与 3 种双系融合共鸣技（血雷风暴、嗜魂诅咒、虚空磁暴）。
  - 18 种正负属性商店道具与 10 种高风险高收益血契祭坛契约。
- **Boss 战与无尽模式**：第 5 波《赤潮审判官》与第 10 波《深渊双生主宰》机制 Boss，支持第 10 波通关撤离或潜入第 11+ 波无尽深渊。
- **局外成长体系**：深渊圣所 12 项三大分支天赋（支持免费 100% 一键洗点）、14 把武器独立击杀精通、流派 Ban 位、Heat 0~8 热度协议与波间断线自动续玩。
- **程序化美术与音频管线**：内置 Python 美术生成器（46 张 PNG）与音频合成器（30 个 OGG 音效与循环 BGM）及 3 个移动兼容着色器。
- **测试与构建**：包含 `tests/TestSuite.gd` 无头自动化测试与 Android APK / Windows 桌面端导出预设。
