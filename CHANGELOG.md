# Changelog

All notable changes to **Pact Arena (血契竞技场)** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
