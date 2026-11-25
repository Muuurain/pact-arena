# 《血契竞技场》(Pact Arena) 技术架构说明

## 1. 引擎与渲染选型
- **引擎版本**：Godot 4.7.2 Stable Mono（使用强类型 GDScript 2.0 构建，确保零跨平台 .NET AOT 障碍并具备极致的热重载与打包稳定性）。
- **渲染后端**：`GL Compatibility`（OpenGL ES 3.0），针对中低端 Android GPU 优化功耗与帧率稳定。
- **分辨率适配**：竖屏逻辑分辨率 `720×1280`，`stretch/mode = canvas_items`，`aspect = expand`，HUD 严格接入 `DisplayServer.get_display_safe_area()` 适配刘海屏与底部手势条。

## 2. 目录与分层架构
- `src/autoload/`：轻量化全局服务（`EventBus`、`GameData`、`SaveManager`、`AudioManager`）。
- `src/core/`：零引擎渲染依赖的纯逻辑与数值管线（`StatBlock`、`CombatFormulas`、`SynergyEngine`、`RunState` 等），可直接在 `--headless` 模式下执行自动化单元测试。
- `src/combat/`：竞技场高并发战斗层。采用**空间哈希网格（SpatialHashGrid）+ 池化节点与图形合批**处理敌群、弹幕、掉落物与伤害飘字，避免移动设备频繁实例化/GC 卡顿。
- `src/ui/`：响应事件总线的界面表现层（主菜单、选人、圣所天赋、图鉴、战斗 HUD、波间商店、血契弹窗、觉醒选择、结算复盘）。
- `tools/` & `tests/`：离线资产生成脚本、验证脚本与自动化测试集，通过 `.gdignore` 与 `export_presets.cfg` 排除过滤，不打入最终发行包体。

## 3. 核心数据流
1. `RunState` 持有一局内的英雄、武器列表、道具列表、已激活血契与经济统计，每次变更统一通过 `recompute_effective_stats()` 经由 `StatBlock` + `SynergyEngine` 重新汇总属性。
2. 每次波次/商店切换自动调用 `SaveManager.save_resume_run()` 写入 `user://run_resume.json`，保障手游随时切后台或重开不断档。
3. 结算时通过 `SaveManager.commit_run_results()` 汇总深渊余烬、武器精通击杀、解锁新英雄与最高记录至 `user://meta_save.json`（附带校验摘要防止误损）。
