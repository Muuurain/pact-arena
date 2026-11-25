# Contributing to Pact Arena (血契竞技场)

欢迎为《血契竞技场》提交 Bug 修复、新武器/血契设计或移动端体验优化！

## 开发环境要求
- **引擎**：Godot `4.7.2`（或兼容的 Godot 4.7.x 版本，开启 GL Compatibility 渲染器）
- **脚本规范**：使用强类型 GDScript 2.0（Tab 缩进、明确参数与返回类型标注、避免未类型化集合直接 `:=` 索引推断）
- **资产生成（可选）**：Python 3.11+（`Pillow`、`numpy`）与 `ffmpeg`

## 目录约定
- 纯逻辑与数值公式请放在 `src/core/`，保证不依赖 UI 节点即可进行 `--headless` 单元测试。
- 新武器、道具、血契、英雄请优先通过 `src/autoload/GameData.gd` 数据目录扩展，并同步补充对应的资源文件与断言检查。

## 提交 PR 前检查清单
1. 运行无头自动化测试，确保全部断言通过且无新增错误：
   ```bash
   godot --headless --path . "res://tests/test_runner.tscn"
   ```
2. 若修改了 `assets/` 下的资产生成脚本，请确保重新生成并提交对应的 `.png` / `.ogg` 及 `.import` 文件。
3. 请勿提交 `build/` 下的 `.apk` / `.exe` 体积较大二进制产物（它们由 `.gitignore` 排除并通过 Release 分发）。
4. 填写 `.github/PULL_REQUEST_TEMPLATE.md` 中的修改说明与验证结果。
