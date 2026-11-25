## 变更摘要

<!-- 简要说明本次 PR 修复了什么问题或新增了什么玩法/机制 -->

## 变更范围
- [ ] 核心公式 / 构筑逻辑 (`src/core/`, `src/autoload/`)
- [ ] 竞技场战斗 / AI / 特效 (`src/combat/`)
- [ ] 移动端 UI / 交互 (`src/ui/`)
- [ ] 美术 / 音频 / 着色器资产 (`assets/`, `tools/`)
- [ ] 文档 / 测试 / 构建配置 (`docs/`, `tests/`, `.github/`)

## 验证清单
- [ ] 已在无头模式下完整通过 `godot --headless --path . "res://tests/test_runner.tscn"`
- [ ] 未提交体积超限的本地编译二进制文件 (`build/*.apk`, `build/*.exe`)
- [ ] 如改动 `GameData` 目录或资产脚本，已同步验证资源路径与自动化测试断言
