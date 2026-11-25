# Changelog

All notable changes to **Pact Arena (血契竞技场)** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
