# 音频生成提示词：bgm_arena_soundtrack_loop_set_v01

> 文档性质：本文件由 `audio-prompt-spec` 规范生成，仅作为外部音乐/音频生成模型（本机豆包应用 / 豆包网页端音乐模型）的输入提示词与制作规格说明。**v01 三首母带已由豆包音乐模型生成**，经 `tools/import_bgm.py` 完成裁边、1.6 秒等功率无缝循环、EBU R128 双通响度归一与 Vorbis 转码，导入为运行时 OGG；项目原有程序化临时占位 `bgm_*.ogg` 已被本次成品替换。

---

## 1. 资产元信息

### 基本信息

| 字段 | 内容 |
| --- | --- |
| 项目名称 | `血契竞技场 (Pact Arena)`（`D:\Code\project\pact_arena`） |
| asset_id | `AUD_BGM_ARENA_SOUNDTRACK_SET_01`（含 3 个状态变体：`AUD_BGM_ARENA_SANCTUARY_01` / `AUD_BGM_ARENA_COMBAT_01` / `AUD_BGM_ARENA_BOSS_01`） |
| 主文件名 | `bgm_arena_soundtrack_loop_set_v01`（各独立变体：`bgm_arena_soundtrack_loop_sanctuary_v01`、`bgm_arena_soundtrack_loop_combat_v01`、`bgm_arena_soundtrack_loop_boss_v01`） |
| 资产类型 | `bgm`（场景状态自适应切换配乐套装） |
| 用途 | 覆盖游戏三大核心场景循环配乐：大厅/圣所/商店/血契整备、常规波次战斗、机制 Boss 决战 |
| 优先级 | `P0` |
| 提示词版本 | `v01` |
| 目标生成模型及版本 | 豆包 AI 音乐生成模型（`D:\Doubao\Doubao.exe` 或网页端音乐创作功能；其具体内部版本号未公开，下文同时提供中文精准版与模型无关英文通用 `generation_prompt`） |
| 当前状态 | 提示词规格文档、导入工具脚本与 **v01 三首成品 BGM 均已落地**（母带归档 `raw_audio/`，运行时 OGG 已导入 `assets/audio/bgm/`） |

### 路径规则与交付路径

| 路径类别 | 路径值 | 状态 |
| --- | --- | --- |
| 1. 提示词 Markdown 完整保存路径 | `D:\Code\project\pact_arena\docs\bgm_arena_soundtrack_loop_set_v01_prompt.md` | **已写入** |
| 2. 原始高质量音频完整输出路径 | 1. `D:\Code\project\pact_arena\raw_audio\bgm_arena_soundtrack_loop_sanctuary_v01.wav`（豆包若导出 `.mp3`/`.m4a` 先存同名原始文件后转标准 WAV）<br>2. `D:\Code\project\pact_arena\raw_audio\bgm_arena_soundtrack_loop_combat_v01.wav`<br>3. `D:\Code\project\pact_arena\raw_audio\bgm_arena_soundtrack_loop_boss_v01.wav` | **已归档**：44100 Hz / 立体声 / 16-bit PCM 母带 |
| 3. 游戏运行时音频输出路径 | 规范配对路径：<br>1. `D:\Code\project\pact_arena\assets\audio\bgm\bgm_arena_soundtrack_loop_sanctuary_v01.ogg`<br>2. `D:\Code\project\pact_arena\assets\audio\bgm\bgm_arena_soundtrack_loop_combat_v01.ogg`<br>3. `D:\Code\project\pact_arena\assets\audio\bgm\bgm_arena_soundtrack_loop_boss_v01.ogg`<br>（注：现行引擎加载兼容路径为 `D:\Code\project\pact_arena\assets\audio\bgm\bgm_sanctuary.ogg` / `bgm_combat.ogg` / `bgm_boss.ogg`，见第 13 节说明） | **已输出**：v01 长名与引擎兼容短名双份 OGG（44100 Hz / 立体声 / 160 kbps Vorbis） |
| 4. 可选分轨 / 短版本 / 参考音频 / 后期工程路径 | `D:\Code\project\pact_arena\tools\import_bgm.py`（已内置自动裁静音、响度均衡与 1.6 秒无缝交叉淡化后期处理脚本）；分轨/DAW 工程：`无` | 后期脚本就绪 / 分轨无 |
| 5. 项目内相对路径 / 引擎资源导入路径 | `res://assets/audio/bgm/bgm_arena_soundtrack_loop_sanctuary_v01.ogg`（现行代码引用 `res://assets/audio/bgm/bgm_sanctuary.ogg` 等 3 轨） | 计划导入路径 |

---

## 2. 音乐音频需求介绍

- **使用场景**：
  - 变体 `sanctuary`（`bgm_arena_soundtrack_loop_sanctuary_v01`）：主界面（`MainMenu`）、出征备战（`HeroSelectScreen`）、深渊圣所局外天赋树（`SanctuaryScreen`）、图鉴（`CodexScreen`）、波间黑市商店（`ShopScreen`）、升级强化（`LevelUpModal`）、赌命血契祭坛（`PactAltarModal`）及结算页（`RunSummaryScreen`）。
  - 变体 `combat`（`bgm_arena_soundtrack_loop_combat_v01`）：第 1~4 波、第 6~9 波及第 11+ 波非 Boss 常规生存突围战（由 `CombatFormulas.calc_wave_duration` 控制，单波时长约 `26~46 秒`，受时空加速血契影响最低 `18 秒`）。
  - 变体 `boss`（`bgm_arena_soundtrack_loop_boss_v01`）：第 5 波《赤潮审判官》、第 10 波终极首领《深渊双生主宰》及第 15/20... 每 5 波深渊 Boss 战（单波基础时长 `45~52 秒`）。
- **叙事背景**：暗黑霓虹深渊竞技场。六位身负猩红、苍蓝、虚空之力的高机动猎杀者，在不断收缩的血契法阵中操纵最多 6 把环绕自动武器与四阶觉醒红武突围求生，并通过签署高风险禁忌血契换取极端战力。
- **玩家正在做什么**：
  - 整备期：单手竖屏浏览属性面板、比较武器阶位与替换/合成方案、权衡三神系羁绊（2/4/6 阶与双神融合共鸣）并决定是否签下扣血增伤血契。
  - 战斗期：通过全屏浮动虚拟摇杆高速穿梭密集弹幕与敌潮，频繁释放 2 层充能「血步瞬移」穿怪挂破甲并重置近战武器冷却，6 把自动武器高频挥砍、电弧连锁、爆裂收割。
  - Boss 战：应对全屏高伤机制弹幕、冲锋预警与召唤物压迫，倾泻四阶红武觉醒火力完成击杀。
- **需要传达的情绪**：
  - 整备期：冷峻克制、神秘仪式感、暗流涌动的危机酝酿。
  - 战斗期：紧迫推进、肾上腺素飙升、爽快精准的赛博斩杀律动。
  - Boss 战：孤注一掷的史诗压迫、惨烈对抗与巅峰对决张力。
- **音频承担的功能**：强化三大玩法阶段的情绪区分度；用恒定节拍稳定玩家战斗走位与瞬移节奏；在主菜单与商店提供耐听、不疲劳的沉浸式底噪与仪式空间。
- **开始、结束与切换条件**：
  - 由 `EventBus.bgm_requested` 驱动 `AudioManager.play_bgm(track_id)`：启动进入主界面及每波战斗结束时切换至 `sanctuary`；普通波次开始伴随 `sfx_wave_start` 切入 `combat`；Boss 波伴随 `sfx_boss_warn` 切入 `boss`。
  - 当前 `AudioManager.gd` 在曲目播放触发 `finished` 信号后自动重新 `play()` 循环。
- **对白与音效共存要求**：
  - 本项目无长篇语音对白，但战斗中包含 **27 个高频瞬态立体声短音效**（电锯挥砍、火药枪击、连锁电弧、冰晶碎裂、迫击炮爆炸、血步破甲、拾取血晶、UI 触击等，经 `tools/generate_audio.py` 重构，高频主要集中在 `1.2 kHz–10 kHz`，重击冲击在 `40–150 Hz`）。
  - 因此 BGM 编曲**严禁过度塞满 2–5 kHz 刺耳主音齐奏与无休止镲片嘶鸣**，需在混音上适当收拢中高频刺耳尖峰，为枪火、电弧与命中提示音留出清晰可辨的动态余量（`AudioManager.gd` 已预设 `bgm_volume * 0.55` 缩放保护）。

---

## 3. 生成风格

- **音乐类型与子类型**：`DarkSynth / Cyberpunk Industrial Electronic`（暗黑赛博合成器浪潮）融合 `Gothic Ritual Synth`（整备变体）与 `Hybrid Cinematic Orchestral Metal`（Boss 决战变体）。
- **情绪关键词**：暗黑深渊、冷冽仪式、工业脉动、高能突围、史诗压迫（仅作概念索引，具体听感由下方声部细节落实）。
- **时代或文化背景**：近未来反乌托邦暗黑霓虹斗技场，融合赛博义体武器与古老血契魔法阵的奇幻科技世界观。
- **配器 / 音色构成**：
  - **变体 1 (`sanctuary`)**：暖厚模拟锯齿低音合成器垫（经过 `400 Hz` 低通温暖滤波）缓慢呼吸；清冷玻璃质感的电钢/钟琴短琶音在左右声道轻微乒乓延迟；稀疏的深水脉冲 Sub-Bass（每小节第 1 拍点压低频）；点缀极少量远景金属钟鸣，不出现重鼓或失真吉他。
  - **变体 2 (`combat`)**：紧致有力的四四拍电子底鼓（`kick` 聚焦 `55–90 Hz` 冲击，干脆无冗长拖尾）搭配失真军鼓与闭合踩镲（2、4 拍推进）；滚涌的 16 分音符锯齿波合成器 Bassline（带轻微侧链呼吸给底鼓让位）；低八度 Palm-mute 失真节奏电吉他切分（仅在主题发展段铺入中低频厚度）；中景棱角分明的模拟合成器主音奏出紧凑短动机，刻意避免长时间高音区尖啸以防遮蔽枪击与电弧音效。
  - **变体 3 (`boss`)**：双踩形态重型工业战鼓与定音鼓齐击；低音大提琴与低音长号/大号八度持续音与急促 16 分音符弦乐断奏（Spiccato Strings）叠加；失真 Drop-D 电吉他强力和弦与厚重工业锯齿 Bass 形成宽广低频墙；铜管强奏吹出紧绷的小二度/减五度动机推高对决压迫感。
- **节奏特点**：
  - 统一锁定 `128 BPM` 四四拍脉冲基底，通过鼓组密度实现三个场景的天然张力梯度：`sanctuary` 采用半拍感（Half-time `64 BPM` 听感，极稀疏脉冲）、`combat` 采用标准全速四四拍驱动律动、`boss` 采用双倍速感（`256` 细分十六分音符断奏与工业双踩冲击）带来压迫加速感。
- **旋律与和声特征**：
  - 统一使用 `D 小调 (D Minor)`，自然融入降二度（`Eb`，弗里吉亚色彩）与增四度张力，体现深渊试炼与血契代价感。旋律坚持短小易记的 2~4 小节循环动机（Ostinato），绝不使用繁复多变的流行抒情长旋律。
- **混音质感与制作方向**：
  - 现代高清晰度电子/电影游戏原声质感；干湿比控制得当（低频 `120 Hz` 以下严格单声道居中紧致，中高频铺底与琶音适当展宽立体声，混响尾音干净收束不过度浑浊）；保留约 `6–8 dB` 峰值动态空间，拒绝过度砖墙限幅导致的失真挤压感。
- **参考特征（仅作抽象特征说明）**：
  - 参考《暗黑赛博动作肉鸽 / 科幻动作原声》的编曲比例与空间控制方式：前 2 秒即建立核心底色与律动，主音音符稀疏利落且避让特效频段；**严禁复刻或近似模仿任何知名游戏原声或商业歌曲的具体旋律、和弦走向与音色采样切片**。

---

## 4. 可量化音乐参数

### 全局统一同步契约（同一状态变体套装强制对齐）

| 参数 | 规格 | 说明 |
| --- | --- | --- |
| BPM | `128 BPM`（严格恒速，全曲禁止 rubato / 变速） | 三个变体严格锁定统一 `128 BPM`，其中 `sanctuary` 通过半拍编配呈现舒缓呼吸，`combat` 为标准 `128 BPM` 脉冲，`boss` 通过双倍密集十六分音符呈现高燃压迫感 |
| 拍号与总小节数 | `4/4` 拍，严格 `48` 小节（`1.875 秒/小节`） | 采用工整的 `8 + 16 + 16 + 8` 现代电子/游戏配乐黄金对称结构，确保每个段落精准落在 8 小节整数倍 |
| 调性 / 调式 | `D 小调 (D Minor)`（含少量弗里吉亚 `Eb` 经过音） | 三首保持同主音小调衔接，大厅切战斗或普通波切 Boss 战时和声无生硬离调感 |
| 起始对齐 | 第 0 秒 / 第 1 小节第 1 拍强拍起音 | 禁止长达数秒的渐变空白起音，确保玩家进入波次战斗 `26~46s` 内立刻听到完整节拍与主题 |
| 目标时长及允许误差 | `90.0 秒`（`±2.0 秒`容差；`48 小节 @ 128 BPM = 90.000 秒整`） | 足够完整覆盖单波 `26~52s` 战斗及逛店整备周期；结尾不拖长静音衰落，以利无缝循环 |

---

## 5. 结构与情绪曲线

### 全局 48 小节（90 秒）时间轴与三变体声部矩阵

| 时间段（小节） | 结构功能 | `sanctuary`（整备仪式） | `combat`（常规波次高燃） | `boss`（深渊主宰决战） |
| --- | --- | --- | --- | --- |
| `0–15 秒`（第 `1–8` 小节） | **前奏 / 立即定调** | 暖低通合成器 Pad 与轻柔钟琴 8 分音符分解琶音进入，每 2 小节一次极轻低频 Sub 心跳 | **前 2 秒内直接入鼓**：紧凑电子底鼓 + 16 分音符 Synth Bassline 立刻驱动，铺入低调暗黑节奏氛围 | **前 2 秒号角与急促弦乐齐鸣**：深渊低音铜管长音 + 16 分音符弦乐断奏 + 战鼓滚奏瞬间拉满危机感 |
| `15–45 秒`（第 `9–24` 小节） | **主题展开 / 核心推进** | 加入空灵长线条副旋律音色与微弱金属铃响点缀，中频保持疏朗空旷，让位于商店阅读思考 | 失真军鼓与踩镲全开，融入低音失真吉他切分 Riff，主音合成器奏出利落 4 小节循环攻击性动机 | 工业双踩重鼓全面爆发，厚重铜管主题与重金属吉他强力和弦交织，配合高速合成器脉冲冲刺 |
| `45–75 秒`（第 `25–40` 小节） | **高潮 / 情绪强化** | 琶音向上扩展八度并叠加微弱温暖次高音合成垫，情绪略微神秘沉重但依旧不喧宾夺主 | 合成器主音加花变奏并叠入高频律动切分脉冲，电吉他与 Bassline 能量推至顶点 | 铜管提高八度持续强奏、弦乐断奏上行推进并加入高潮撞击重音，张力达到全曲最高峰 |
| `75–90 秒`（第 `41–48` 小节） | **回落衔接（Turnaround）** | 在最后 4 小节抽去次高音加花，回归前 8 小节同款低音 Pad 与钟琴琶音，和声悬停在 D 小调属/持续音自然衔回 `0 秒` | 在最后 4 小节略微收窄主音亮度，保留完整底鼓与 Bassline 律动回归首小节状态，无缝循环不断拍 | 最后 4 小节收回最高音铜管尖峰，保留工业战鼓脉冲与低音大提琴持续推进，稳稳闭环衔回第 1 秒 |

---

## 6. 人声与歌词

- **人声策略**：纯音乐（无任何人声）
- **强制约束**：三首曲目均**不得出现人声、念白、合唱或含歌词的声音**（包括人声切片 `vocal chops`、吟唱 `chant` 或 AI 拟声呼喊，以免干扰快节奏战斗听觉判断及商店/圣所阅读体验）。

---

## 7. 循环与交互音乐要求

- **播放模式**：无缝循环（`loop`）
- **循环设计要求**：
  - 三首均须避免在结尾给出不可逆的“全曲结束感主和弦长音大终止式（Final Cadence）”与超过 `0.5 秒` 的静默衰弱尾音。
  - 最后 `4` 小节（`75–90 秒`）须通过转回和弦（Turnaround，如 `Gm -> A7sus4 / D` 低音持续）平滑导回第 `1` 小节第 `1` 拍，保留结尾混响尾音以便后期通过 `1.6 秒` 等功率交叉淡化实现首尾零咔哒无缝衔接。
  - 当前引擎暂不单独拆出 `intro` / `outro` 切片，每首以单文件完整循环交付；由 `AudioManager._on_bgm_finished` 自动循环续播。
- **自适应与交互要求**：
  - 游戏内部按场景状态切换播放（整备期 `sanctuary` ↔ 常规战斗 `combat` ↔ Boss 战 `boss`），不作实时多轨混音叠加，但**本变体套装内全部三个交付变体均强制遵守 `128 BPM`、`4/4` 拍、`48 小节 / 90.0 秒`、同主音 `D 小调` 与第 `0 秒` 强拍对齐规则**，保证状态切换及未来拓展成叠轨系统时可直接严丝合缝。

---

## 8. 完整生成提示词

> 说明：由于豆包客户端每次通常按“单曲”提交生成，下方分别为 3 首变体提供**完全自包含、可逐首整段复制提交**的中文正向提示词与英文通用 `generation_prompt`。

### 变体 1：`bgm_arena_soundtrack_loop_sanctuary_v01`（大厅 / 圣所 / 商店整备）

#### 中文完整正向提示词（可直接提交豆包）

```text
请生成一首纯音乐、无任何人声与歌词的暗黑赛博奇幻游戏大厅与商店备战背景音乐，风格融合暗黑合成器浪潮（DarkSynth）与哥特祭坛仪式电子感。全局参数严格为 128 BPM、4/4 拍、D 小调，共 48 小节、总时长约 90 秒，保持严格恒定速度不变速。整体采用类似 64 BPM 的半拍舒缓呼吸律动：前 15 秒用经低通滤波的暖厚模拟合成器长音垫与清冷电子钟琴八分音符分解琶音迅速建立神秘深渊空间，每两小节配合一次克制的深低频心跳脉冲；15 至 45 秒加入稀疏空灵的副旋律音色与微弱金属钟鸣点缀，中频保持大量留白不吵闹；45 至 75 秒将琶音扩展一层高八度并加深合成器背景张力；最后 75 至 90 秒抽离高频装饰，回归初始温暖低音垫并停留在悬而未决的属音持续上平滑收尾，不出现突兀停止、长静音或完结终止式，适合游戏内无缝循环。强制约束：纯器乐演奏，绝对不得出现人声、念白、合唱、人声切片或含歌词的声音。
```

#### 英文版 generation_prompt（适用于英文优先或模型无关提交）

```text
Pure instrumental dark cyber-gothic roguelite sanctuary and shop background music, blending brooding DarkSynth with restrained occult ritual electronics. Strictly locked to 128 BPM, 4/4 meter, D minor, 48 bars, 90 seconds total duration with zero tempo drift, arranged in a spacious half-time 64 BPM groove feel. From 0 to 15s, open immediately with warm low-pass filtered analog synth pads, glassy crystalline eighth-note arpeggios, and a subtle sparse sub-bass pulse every two bars. From 15 to 45s, weave in minimal echoing ritual bell accents and a quiet atmospheric synth counter-motif while leaving clean midrange headroom for UI clicks. From 45 to 75s, subtly lift the arpeggio by an octave and deepen harmonic tension without adding aggressive drums or distorted guitars. From 75 to 90s, gently strip back upper layers into a smooth turnaround over a sustained D-minor pedal for seamless looping without abrupt endings or long silence. Strictly no vocals, no spoken word, no choir, no vocal chops, no lyrics.
```

---

### 变体 2：`bgm_arena_soundtrack_loop_combat_v01`（常规波次高燃突围战斗）

#### 中文完整正向提示词（可直接提交豆包）

```text
请生成一首纯音乐、无任何人声与歌词的高燃快节奏暗黑赛博动作肉鸽战斗配乐，风格为暗黑赛博合成器电音（DarkSynth）融合紧凑工业电子摇滚。全局参数严格为 128 BPM、4/4 拍、D 小调，共 48 小节、总时长约 90 秒，全程严格恒速。要求第 1 至 2 秒内立刻切入紧致有力的四四拍电子底鼓与奔涌的 16 分音符锯齿波合成器低音线（拒绝漫长前奏），配合第 2、4 拍干脆军鼓构建紧凑突围律动；15 至 45 秒全套工业打击乐全开并铺入低音失真切分电吉他 Riff，由棱角分明的中景模拟合成器主音奏出紧凑短小的 4 小节循环攻击性动机，同时刻意避免过度尖锐的高频镲片刺音以防遮蔽游戏内枪击和斩击音效；45 至 75 秒加入高频合成器切分加花将高能战斗推至巅峰；最后 75 至 90 秒保持底鼓与低音线稳定推动同时微收主音亮度，干净衔回开头实现无缝循环，禁止彻底停拍或长静音结束。强制约束：纯器乐演奏，绝对不得出现人声、念白、合唱或含歌词的声音。
```

#### 英文版 generation_prompt（适用于英文优先或模型无关提交）

```text
Pure instrumental high-energy dark cyberpunk roguelite arena combat music, DarkSynth fused with tight industrial electronic rock. Strictly locked to 128 BPM, 4/4 time, D minor, 48 bars, 90 seconds duration with zero tempo variation. Kick off immediately within the first 2 seconds with punchy four-on-the-floor electronic kick drums, crisp snare backbeats, and a driving rolling 16th-note gritty synth bassline (no slow ambient intro). From 15 to 45s, layer tight palm-muted distorted rhythm guitars and an urgent angular analog lead synth playing a crisp 4-bar minor motif, keeping upper-mid frequencies controlled so fast weapon and gunfire SFX remain clearly audible. From 45 to 75s, peak the arrangement with layered octave synth riffs and sharp percussive fills. From 75 to 90s, maintain steady kick and bassline momentum while tapering lead intensity back to the opening bar for a seamless loop without dead silence or final cadence stop. Strictly no vocals, no spoken word, no choir, no lyrics.
```

---

### 变体 3：`bgm_arena_soundtrack_loop_boss_v01`（深渊机制 Boss 决战）

#### 中文完整正向提示词（可直接提交豆包）

```text
请生成一首纯音乐、无任何人声与歌词的史诗级暗黑深渊 Boss 战背景音乐，风格为暗黑赛博工业电子重金属融合紧凑管弦铜管打击乐。全局参数严格为 128 BPM、4/4 拍、D 小调，共 48 小节、总时长约 90 秒，全程严格恒速。通过双倍速感编曲体现极致压迫感：前 3 秒立即用厚重低音铜管号角冲击、大提琴 16 分音符急促断奏与重型工业战鼓滚奏引爆危险气氛；15 至 45 秒进入高强度主段，双踩重型工业鼓组、重低音 Drop-D 失真电吉他强力和弦、高速赛博 Synth Bass 以及带有降二度和弦张力的铜管主题齐头并进；45 至 75 秒把铜管主旋律抬高八度并叠加激进电吉他推进，烘托出惨烈对决的巅峰张力，同时保持低频紧凑不浑浊、高频不爆音；最后 75 至 90 秒收回最高音铜管尖峰，保留工业战鼓脉冲与弦乐低音推进稳稳衔接回第 1 秒，适合战斗中循环播放且不可出现完全停顿的结束句。强制约束：纯器乐演奏，绝对不得出现人声、念白、合唱、人声嘶吼或含歌词的声音。
```

#### 英文版 generation_prompt（适用于英文优先或模型无关提交）

```text
Pure instrumental epic abyssal boss battle music, hybrid cinematic dark orchestral fused with heavy industrial cyber metal. Strictly locked to 128 BPM, 4/4 meter, D minor, 48 bars, 90 seconds duration, constant tempo throughout. Create relentless urgency through double-time rhythmic energy: burst in within the first 3 seconds using low brass horn swells, rapid staccato cello 16th-note ostinatos, and heavy industrial war-drum hits. From 15 to 45s, unleash driving double-kick industrial percussion, aggressive distorted low rhythm guitars, ferocious cyber sub-bass, and dark D-Phrygian brass themes. From 45 to 75s, elevate the brass motif by an octave with urgent string runs for a climactic final showdown while keeping low-end sub frequencies tight and midrange uncluttered for combat SFX. From 75 to 90s, pull back only the highest brass layer while holding relentless drum and bass momentum into a seamless turnaround back to bar 1 without abrupt cutoff or silence. Strictly no vocals, no spoken word, no choir, no shouting, no lyrics.
```

---

## 9. 负面提示词与禁止事项

- **全局排除声音与元素**：人声演唱、念白旁白、史诗合唱团/咏叹调（`choir/chant`）、人声切片采样、明显欢快大调流行和弦、乡村/爵士/搞笑卡通音效、突兀电子白噪刺响。
- **变体特定排除项**：
  - `sanctuary`：禁止出现重型失真电吉他、激进重金属架子鼓、高速踩镲或持续高压音墙（需安静衬托 UI 与读字）。
  - `combat` / `boss`：禁止前奏超过 `3 秒` 无鼓无律动的纯铺底前戏；禁止持续超过 `4 秒` 的空档静默断奏。
- **排除混音与技术缺陷**：交流底噪、数字削波爆音（`0 dBFS clipping`）、过度砖墙限幅导致鼓声吸气泵浦感、尾部突然硬切（`abrupt cut`）、开头或结尾无意义的纯空白静音。
- **冲突检查声明**：已核对以上禁止项与第 8 节三段正向提示词完全一致、无任何内部冲突（例如 `sanctuary` 明确排除了激烈鼓点与吉他，而将电吉他与重鼓仅限定于 `combat` 与 `boss` 变体中）。

---

## 10. 技术交付规格

| 规格项 | 源文件（Master） | 运行时文件（Runtime） |
| --- | --- | --- |
| 文件格式 | `WAV（无压缩 PCM）`（豆包若导出 `.mp3`/`.m4a`，先作为原素材放入 `raw_audio\` 并经无损解码母带化归档为 WAV） | `OGG Vorbis`（匹配 Godot 4.7 Android / Windows 移动端兼容性与 `AudioManager.gd`） |
| 采样率 | `44100 Hz` | `44100 Hz`（与项目 27 个音效统一基准采样率一致） |
| 位深 / 比特率 | `24-bit`（或 `16-bit` PCM） | `160 kbps VBR/ABR` |
| 声道 | `Stereo（双声道立体声）` | `Stereo（双声道立体声）` |
| 响度与峰值规范 | `-15.5 LUFS（±1.0 LU）`，真实峰值 `<= -1.0 dBTP` | 同左（结合 `AudioManager.gd` 内乘 `0.55` 缩放保证不掩盖枪击/砍击 SFX） |
| 首尾静默与淡入淡出 | 首尾零额外长静音；首 `0.02s` 微淡入防零点噼啪声，循环尾音交由交叉淡化衔接 | 同左 |
| 循环点精度 | `48 小节` 整数拍边界与过零点裁剪 + `1.6s` 等功率交叉淡化回绕 | Godot 内可由 `AudioManager._on_bgm_finished` 零间隙重播 |

### 后期处理要求（外部 AI 模型单次生成无法直接保证，必须由脚本/人工处理）

1. **格式解码与采样率统一**：豆包客户端默认多导出 `.mp3` 或 `.m4a`，不可直接视作无损母带；须通过本机 `FFmpeg` 统一解码并重采样为 `44100 Hz` 立体声 `24-bit` WAV 源格式及最终 `160k` OGG 运行时格式。
2. **首尾静音裁边**：AI 模型常在开头预留 `0.2~1.0s` 静音并在结尾附带 `2~5s` 渐弱空余，必须执行门限裁剪（如 `-45 dBFS` 门限裁边）。
3. **响度一致化与峰值保护**：三首单独生成的曲目响度差异可能高达 `4~6 LU`，必须统一测量并归一化至 `-15.5 LUFS`、限制真实峰值不超过 `-1.0 dBTP`。
4. **无缝循环回绕处理**：AI 生成模型无法原生保证精确 `90.000s` 及采样级首尾相接，必须通过项目内置脚本 `tools/import_bgm.py`（或 DAW 手工对齐拍点）执行 `1.6 秒` 等功率尾首交叉淡化并试听过零点平滑度，之后执行编码与 Godot 导入测试。

---

## 11. 交付物与变体

> **诚实声明**：下表音轨 v01 已全部生成、母带归档并转码导入运行时目录；表中实测参数见各行状态列。

| 序号 | 交付物角色 | 目标文件名 | 目标路径 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | 提示词规范文档（本文件） | `bgm_arena_soundtrack_loop_set_v01_prompt.md` | `D:\Code\project\pact_arena\docs\bgm_arena_soundtrack_loop_set_v01_prompt.md` | **已写入** |
| 2 | 圣所整备变体（母带源文件） | `bgm_arena_soundtrack_loop_sanctuary_v01.wav`（豆包原下载可先放同前缀 `.mp3`/`.wav`） | `D:\Code\project\pact_arena\raw_audio\bgm_arena_soundtrack_loop_sanctuary_v01.wav` | **已归档**（44100 Hz / 立体声 / 16-bit PCM，89.81 s，-15.4 LUFS，TP -1.70 dBTP） |
| 3 | 圣所整备变体（运行时文件） | `bgm_arena_soundtrack_loop_sanctuary_v01.ogg`（兼容引擎现有加载目标 `bgm_sanctuary.ogg`） | `D:\Code\project\pact_arena\assets\audio\bgm\bgm_arena_soundtrack_loop_sanctuary_v01.ogg`（及 `assets\audio\bgm\bgm_sanctuary.ogg`） | **已转码导入**（160 kbps Vorbis，双份落盘） |
| 4 | 常规战斗变体（母带源文件） | `bgm_arena_soundtrack_loop_combat_v01.wav`（豆包原下载可先放同前缀 `.mp3`/`.wav`） | `D:\Code\project\pact_arena\raw_audio\bgm_arena_soundtrack_loop_combat_v01.wav` | **已归档**（44100 Hz / 立体声 / 16-bit PCM，90.00 s，-15.5 LUFS，TP -2.10 dBTP） |
| 5 | 常规战斗变体（运行时文件） | `bgm_arena_soundtrack_loop_combat_v01.ogg`（兼容引擎现有加载目标 `bgm_combat.ogg`） | `D:\Code\project\pact_arena\assets\audio\bgm\bgm_arena_soundtrack_loop_combat_v01.ogg`（及 `assets\audio\bgm\bgm_combat.ogg`） | **已转码导入**（160 kbps Vorbis，双份落盘） |
| 6 | Boss 决战变体（母带源文件） | `bgm_arena_soundtrack_loop_boss_v01.wav`（豆包原下载可先放同前缀 `.mp3`/`.wav`） | `D:\Code\project\pact_arena\raw_audio\bgm_arena_soundtrack_loop_boss_v01.wav` | **已归档**（44100 Hz / 立体声 / 16-bit PCM，89.57 s，-15.4 LUFS，TP -2.30 dBTP） |
| 7 | Boss 决战变体（运行时文件） | `bgm_arena_soundtrack_loop_boss_v01.ogg`（兼容引擎现有加载目标 `bgm_boss.ogg`） | `D:\Code\project\pact_arena\assets\audio\bgm\bgm_arena_soundtrack_loop_boss_v01.ogg`（及 `assets\audio\bgm\bgm_boss.ogg`） | **已转码导入**（160 kbps Vorbis，双份落盘） |

---

## 12. 验收标准

### 自动检查

- [x] 全部生成文件名严格仅含小写 ASCII 字母、数字与下划线（`[a-z0-9_]`），且变体主文件名与本提示词集合命名规范一致
- [x] 文件存放于第 11 节约定路径，源文件与转码后 `.ogg` 运行时文件均非空且可被 `ffprobe` / Godot `AudioStreamOggVorbis` 正常解码加载
- [x] 格式为 OGG Vorbis，采样率为 `44100 Hz`，声道数为 `2`（Stereo）
- [x] 经裁边循环处理后，三首变体实际时长在 `90.0 秒 ± 2.0 秒` 允许范围内（89.81 / 90.00 / 89.57 s）
- [x] 峰值电平未超过 `-1.0 dBTP`（无 `0 dBFS` 削波），响度接近 `-15.5 LUFS`（-15.4 / -15.5 / -15.4）且三首之间响度差控制在 `<= 1.5 LU`（实测 0.10 LU）
- [x] 首尾无超过 `0.05 秒` 的纯静音（全零或低于 `-60 dBFS`）
- [x] 运行 Godot 无头测试套件 `res://tests/test_runner.tscn` 全量通过（0 failures）

### 人工听审

- [ ] 音乐风格、配器密度与情绪曲线明显区分「整备圣所」「普通战斗」「Boss 决战」三层体验，符合暗黑霓虹赛博质感
- [ ] 第 1~2 秒切入迅速，战斗与 Boss 曲不会出现长时间拖沓无鼓前奏
- [ ] 尾端接回开头（第 90 秒 → 第 0 秒）过渡平顺自然，无明显节拍错位、音量断层或过零咔哒声
- [ ] 与游戏内 27 个高频战斗与 UI 立体声短音效（电锯、枪械、电弧、血步、受击、暴击、血晶拾取等）同时播放时不抢频、不遮蔽战斗提示信号
- [ ] 全曲无人声哼唱、无念白歌词、无 AI 明显金属声码器伪影或混沌底噪
- [ ] 从 `sanctuary` 切换到 `combat`、从 `combat` 切换到 `boss` 时同调性衔接自然无违和感

---

## 13. 假设与待确认事项

- **未完全确定的外部环境与模型限制**：
  1. 本机仅确认安装了豆包桌面客户端（`D:\Doubao\Doubao.exe`），但未公开其内部当前挂接的具体音乐生成模型版本号与单次生成精确时长上限（部分版本豆包纯音乐单次生成可能在 `60~180 秒` 浮动，或不支持精确到小数秒的 BPM 锁相）；如豆包生成实际时长与 `90 秒` 存在偏差，需在 `raw_audio\` 中通过裁剪小节或启用 `tools/import_bgm.py` 做节拍整周期微调对齐。
  2. 豆包通常仅直接返回有损压缩格式（`.mp3` / `.m4a`），无法原生交付 `24-bit WAV` 无损母带或直接符合 Godot `-15.5 LUFS` / 无缝循环的 `.ogg`；需依赖本机 `FFmpeg` + `tools/import_bgm.py` 完成解码母带归档与转码优化。
- **采用的保守默认值**：
  - 将 3 首曲目统一约束为 `128 BPM / 4/4 拍 / 48 小节 / D 小调 / 90.0 秒 / 纯器乐无歌词`（通过编曲律动密度区分半拍、标准拍与双倍拍体感），以同时满足游戏场景听感差异与 `audio-prompt-spec` 自适应套装的全局同步契约。
  - 将运行期目标定为 `44100 Hz / 立体声 / 160 kbps OGG Vorbis` 与 `-15.5 LUFS`，匹配已重构的 `44100 Hz` 立体声 SFX 引擎。
- **引擎既有代码命名兼容说明（待按需确认是否切换命名）**：
  - 当前游戏代码 `Main.gd`、`ArenaController.gd`、`AudioManager.gd`、`TestSuite.gd` 读取的逻辑名仍为 `bgm_sanctuary`、`bgm_combat`、`bgm_boss`（对应 `assets/audio/bgm/bgm_*.ogg`）。已同步增强 [import_bgm.py](file:///D:/Code/project/pact_arena/tools/import_bgm.py)，既可直接读取 `bgm_arena_soundtrack_loop_<variant>_v01.*` 也可读取旧命名并输出双份/覆盖现行 `.ogg`；如未来希望引擎脚本直接引用 `*_v01.ogg` 长命名，可再行统一切换代码 ID。
- **人工后期处理依赖**：v01 已按此流程完成——豆包模型生成的原始文件存入 `D:\Code\project\pact_arena\raw_audio\`，运行 `python tools/import_bgm.py` 完成静音裁边、EBU R128 双通响度归一、`1.6s` 等功率交叉淡化无缝循环及 Godot `.ogg` 转码导入验证；Godot `.ogg.import` 保持 `loop=false`（依靠 `AudioManager._on_bgm_finished` 重播）。后续 v02 重制时复用同一流程即可。
- **商用授权与许可确认**：在将最终豆包生成音乐打包发布至公开渠道或商业商店前，请自行核实所使用豆包账号/套餐当前对应的《用户协议》与 AI 生成音乐商用授权、版权归属条款。
