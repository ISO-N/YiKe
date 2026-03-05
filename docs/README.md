# 忆刻 (YiKe) — 文档索引

## 项目概述

基于艾宾浩斯遗忘曲线的学习任务规划应用，支持 Android / iOS 移动端与 Windows 桌面端。

## 文档清单

### 汇总文档（建议优先阅读）

| 文档 | 路径 | 说明 |
|------|------|------|
| **PRD（汇总版）** | `prd.md` | 产品需求与验收口径汇总（以本文件为单一事实源） |
| **UI/UX（汇总版）** | `UI-UX.md` | 设计体系、页面规范与验收清单汇总 |
| **技术设计（汇总版）** | `技术设计.md` | 架构、数据模型、同步/桌面端等关键方案汇总 |

### 专题文档

| 文档 | 路径 | 说明 |
|------|------|------|
| **忆刻学习指南** | `prd/忆刻学习指南.md` | 用户使用指南（单一事实源，通过脚本同步到应用 assets） |

### 规格文档（设计/实现过程的分项沉淀）

> `docs/spec/` 用于记录某个主题的完整规格、边界条件与验收用例；其最终结论会被合并回三份汇总文档。

| 文档 | 路径 | 说明 |
|------|------|------|
| **备份与恢复** | `spec/spec-backup-restore.md` | 备份文件格式、合并/覆盖策略、快照回滚与验收 |
| **体验增强 v1.1.0** | `spec/spec-enhancement-v1.1.0.md` | 长按/右键菜单、空状态、动效、左滑与间隔预览 |
| **性能优化** | `spec/spec-performance-optimization.md` | 列表虚拟化、毛玻璃降级、数据库后台化、搜索可取消等 |
| **任务历史/全量查看** | `spec/spec-task-history.md` | 今日/全量视角、撤销副作用、时间线口径与验收 |
| **任务操作增强** | `spec/spec-task-operation-enhancement.md` | 编辑/停用/调整计划/轮次管理等闭环规格 |
| **任务结构升级** | `spec/spec-task-structure-enhancement.md` | description/subtasks 迁移、导入模板、主题说明等 |
| **UI 布局精简** | `spec/spec-ui-layout-simplification.md` | IA 收敛、路由兼容、入口聚合与实施计划 |
| **非数据库体验改进** | `spec/spec-user-experience-improvements.md` | 不改 Schema 的改进清单（统计/交互/通知/主题等） |

### 归档说明

- 自 **2026-02-28** 起，历史版本化文档（`prd-v*`、`UI-UX-v*`、`技术设计-v*`）已合并沉淀到上述三份汇总文档并删除。
- 如需追溯历史细节，请通过 Git 记录查看（避免产生多份“真相”导致口径漂移）。

## 快速导航

### 快速概览
- 想要快速了解产品全貌 → `prd.md`
- 想要快速了解设计全貌 → `UI-UX.md`
- 想要快速了解技术全貌 → `技术设计.md`
- 想要了解使用方法 → `prd/忆刻学习指南.md`

### 内容同步规则
- **学习指南**：以 `docs/prd/忆刻学习指南.md` 为唯一源，同步到 `assets/markdown/learning_guide.md`
- **注意**：`assets/markdown/learning_guide.md` 为生成文件，不手工编辑，避免双向内容漂移
- **同步脚本**：使用 `tool/sync_learning_guide.dart` 一键同步学习指南到 assets
