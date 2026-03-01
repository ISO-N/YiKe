# 忆刻（YiKe）— UI布局精简重构规范

## 文档信息

- 用途：定义 UI 布局精简重构的具体方案，解决当前界面臃肿、入口分散的问题
- 作者：YiKe 团队
- 创建日期：2026-03-01
- 最后更新：2026-03-01
- 关联需求：每个功能仅保留一个入口，避免界面复杂化

---

## 0. 范围定义

### 0.1 本次重构范围

| 范围 | 说明 |
|------|------|
| **底部导航** | 5 Tab → 3 Tab 重构 |
| **入口合并** | 首页+任务中心合并、日历+统计合并、设置聚合 |
| **路由迁移** | 旧路由通过重定向兼容，新路由结构落地 |

### 0.2 本次重构不做

| 不做 | 说明 |
|------|------|
| **业务逻辑变更** | 不修改数据库结构、不改任务/统计算法 |
| **UI风格变更** | 保持现有 GlassCard/GradientBackground 体系 |
| **全新设计** | 不重新设计交互范式，只做收敛与整合 |

### 0.3 平台差异处理

- **桌面端**：使用 `dialog/bottomSheetPageIfDesktop` 策略（`lib/infrastructure/router/app_router.dart:111` 起）
- **移动端**：使用原生底部 Sheet
- **规范原则**：复杂流程（导出/备份/同步）在桌面端可用对话框，移动端优先用底部 Sheet

---

## 1. 现状问题分析

### 1.1 当前问题

| 问题 | 现状代码位置 | 影响 |
|------|--------------|------|
| **底部Tab过多** | ShellScaffold destinations 为 5 项（`lib/presentation/pages/shell/shell_scaffold.dart:61`） | 用户选择困难，视觉疲劳 |
| **功能入口分散** | 任务中心与首页功能重叠 | 用户需要在多页面切换 |
| **设置独立路由页过多** | /settings/export、/settings/backup、/settings/sync、/settings/help、`/topics` 等独立路由 | 功能发现困难，导航效率低 |
| **路由层级复杂** | 最深3级跳转（如 /settings/debug/mock-data） | 导航效率低 |

### 1.2 核心矛盾

- **首页 vs 任务中心**：两者都展示任务，只是范围不同（今日 vs 全量）
- **统计独立页面**：仅有2-3个指标，却占用一个独立Tab
- **设置入口分散**：导出、备份、同步、帮助各自独立路由页

---

## 2. 设计目标

### 2.1 核心原则

- **单一入口**：每个功能只保留一个明确入口
- **入口聚合优先**：将分散入口收敛到统一页面
- **交互形态以可用性优先**：Sheet/全屏二选一，不强制简化复杂流程
- **路由兼容优先**：旧路由通过重定向兼容，避免直接删除导致断裂
- **层级简化**：
  - Shell内层级 ≤ 1（`/home`、`/calendar`、`/settings`）
  - 工具/详情走独立路由（可多段，但不进入底部Tab结构）

### 2.2 量化目标

| 指标 | 现状 | 目标 |
|------|------|------|
| Shell内Tab数 | 5 | **3** |
| 设置独立路由页 | 5+ | **1** (聚合入口页) |
| 功能入口数 | 分散 | **集中** |

### 2.3 可用性底线

- **复杂流程不强行Sheet化**：导出/备份/同步若包含文件选择、进度、历史管理等，优先保留全屏页面
- **入口聚合 ≠ 功能阉割**：聚合入口后，各功能操作步骤不减少

---

## 3. 精简方案

### 3.1 底部导航重构（5 → 3 Tab）

| 新Tab | 路由 | 整合内容 | 底部文案 |
|-------|------|----------|----------|
| **今日** | `/home` | 原首页 + 任务中心（页面内切换：今日/全部） | 今日 |
| **日历** | `/calendar` | 原日历 + 统计（顶部展示关键指标） | 日历 |
| **设置** | `/settings` | 所有设置功能聚合入口 | 设置 |

**决策**：底部Tab文案保持现有"今日"，与 AppStrings.today（`lib/core/constants/app_strings.dart:9`）和 HomePage 标题"今日复习"（`lib/presentation/pages/home/home_page.dart:141`）保持一致。

**新增独立入口**：
- **录入**：Shell层FAB（`FloatingActionButton`），点击打开 `/input`（移动端全屏弹出/页面，桌面端对话框；沿用现有路由表现）
- **设置页不显示FAB**

### 3.2 页面功能整合详情

#### 3.2.1 首页重构

**现状**：
- 只展示今日待复习任务
- 任务中心展示全量任务（支持筛选、分组、分页）

**改进后**：
```
首页结构
┌─ 顶部：搜索 + 更多按钮（现有 AppBar 行为保留）
├─ 二级切换 SegmentedButton：今日 | 全部
├─ FilterBar（现有）：pending | done | skipped | all
└─ 任务列表
```

**数据范围 vs 状态筛选**：
| 维度 | 控制 | 选项 |
|------|------|------|
| **范围** | SegmentedButton | today / all |
| **状态** | TaskFilterBar | pending / done / skipped / all |

**默认组合**：`tab=today` + `filter=pending`
- 其他组合允许：tab=all 时 FilterBar 正常显示
- 批量模式范围：仅在 tab=today 且 filter=pending 时启用（与现有 HomePage 行为一致）

**FilterBar 状态管理决策**：
- `tab=today` 时：FilterBar 状态由 `homeTaskFilterProvider` 管理（现有）
- `tab=all` 时：FilterBar 状态由 `taskHubProvider` 的内部筛选逻辑管理
- **以 TaskHubProvider 为准**：当 tab=all 时，FilterBar 的状态值应同步到 taskHubProvider 的筛选条件，homeTaskFilterProvider 的状态仅作用于 today

**复用策略**：
- tab=today：使用现有的 `homeTasksProvider`
- tab=all：使用 `taskHubProvider`，复用游标分页、筛选、分组逻辑

#### 3.2.2 日历页整合统计

**现状**：
- 统计页面独立：连续打卡、周/月完成率、标签分布
- 日历点击日期弹 DayTaskListSheet（`lib/presentation/pages/calendar/calendar_page.dart:77`）

**改进后**：
```
日历页结构
┌─ 月份切换栏
├─ CompactStatsBar：连续打卡 + 本周完成率（可点击展开）
├─ 月历网格
└─ 选中日期的任务列表（现有）
```

**数据源**：
- CompactStatsBar 直接 watch `statisticsProvider`（`lib/presentation/providers/statistics_provider.dart:1`）
- 不在 calendarProvider 里重复计算，避免口径分裂

**Sheet 冲突处理**：
- 点击 CompactStatsBar 展开统计详情 → Modal Bottom Sheet
- 点击日历日期展开当日任务 → DayTaskListSheet
- 两者互斥：打开另一个前先关闭当前 Sheet

**路由触发自动展开（兼容 `/statistics`）**：
- 当 `/calendar?openStats=1` 时，CalendarPage 首帧后自动弹出 StatisticsSheet
- 统计 Sheet 关闭后，应将路由替换为 `/calendar`（移除 `openStats` 参数），避免返回/重建时重复弹出

**触发优先级决策**：
- 自动触发（openStats=1）和手动触发（点击 CompactStatsBar）是同一行为：弹出 StatisticsSheet
- **弹出期间禁用再次触发**：当 StatisticsSheet 处于打开状态时，CompactStatsBar 的点击事件应被忽略（或 Sheet 已在前台，不影响）
- 实现建议：使用一个 `bool _isStatsSheetOpen` 状态标记，弹出时设为 true，关闭时设为 false，点击 CompactStatsBar 前检查该标记

**统计详情 Sheet**：
- 复用 `StatisticsPage` 的 body 结构（抽成 StatisticsContent）
- 不复制粘贴，作为共享组件

#### 3.2.3 设置页聚合

**现状独立路由页**：
- /settings/export（ExportPage）
- /settings/backup（BackupPage）
- /settings/sync（SyncSettingsPage）
- /settings/help
- /topics

**改进后**：
```
设置页（单一入口页面）
├── 提醒设置（现有）
├── 主题模式（现有）
├── 数据管理入口区块
│   ├── 📤 导出（入口）→ 跳转 ExportPage 或 Sheet
│   ├── 📥 备份/恢复（入口）→ 跳转 BackupPage 或 Sheet
│   └── 🔄 同步（入口）→ 跳转 SyncSettingsPage 或 Sheet
├── 帮助入口（跳转 /help）
├── 关于（现有）
└── Debug（仅Debug模式）
```

**入口聚合原则（两阶段）**：

| 阶段 | 目标 | 交互形式 |
|------|------|----------|
| **阶段A（本次必须）** | 入口聚合到一个页面 | 点击仍可进入现有全屏页 |
| **阶段B（可选优化）** | 简单操作改为 Sheet | 仅开关/轻配置用 Sheet |

**阶段A说明**：
- 设置页创建"数据管理"区块，聚合导出/备份/同步入口
- 点击后仍跳转到现有全屏页面（或桌面端对话框）
- 不强制改为 Sheet，保留现有操作流程完整性

---

## 4. 导航结构

### 4.1 Shell内路由

```
Shell (底部导航 - 3个Tab)
├── /home (今日 - 默认)
│   └── ?tab=all (全部任务)
├── /calendar (日历+统计)
└── /settings (设置聚合页)
```

### 4.2 独立路由（完整列表）

| 路由 | 说明 | 是否在Shell内 |
|------|------|---------------|
| `/input` | 录入页 | 否 |
| `/input/import` | 导入预览 | 否 |
| `/input/templates` | 模板管理 | 否 |
| `/topics` | 主题管理 | 否 |
| `/topics/:id` | 主题详情 | 否 |
| `/items/:id` | 学习内容详情 | 否 |
| `/tasks/detail/:learningItemId` | 任务详情 Sheet | 否 |
| `/help` | 帮助页（全屏） | 否 |

### 4.3 旧路由兼容（重定向）

| 现状路由 | 重定向到 | 说明 |
|----------|----------|------|
| `/tasks` | `/home?tab=all` | 任务中心合并到首页 |
| `/statistics` | `/calendar?openStats=1` | 统计整合到日历页（进入后自动展开统计详情） |
| `/settings/help` | `/help` | 帮助独立为真实页面 |

**说明**：
- `/settings/export`、`/settings/backup`、`/settings/sync` 阶段A不做 redirect，仍保留为可直接访问的独立路由页面（避免破坏深链/桌面快捷入口）。
- 入口聚合的含义是：用户从“设置聚合页”的数据管理区块进入这些页面；而不是禁止直接访问这些路由。

### 4.4 帮助路由修正

**现状**：/help 只是 redirect 到 /settings/help（带底部导航）

**改进后**：
- `/help` = 真实全屏页面（不在 Shell 内）
- `/settings/help` = redirect 到 `/help`（兼容旧入口）

### 4.5 任务详情路由

**现状**：/tasks/detail/:learningItemId 被 TaskHub 直接 push（`lib/presentation/pages/tasks/task_hub_page.dart:194`）

**决策**：保留该路由，作为内部详情 Sheet，不改变现有行为

---

## 5. 组件设计

### 5.1 组件放置规则

| 类型 | 放置位置 |
|------|----------|
| 页面专用组件 | `lib/presentation/pages/<page>/widgets/` |
| 跨页面复用组件 | `lib/presentation/widgets/` |

### 5.2 新增组件清单

| 组件 | 放置位置 | 用途 |
|------|----------|------|
| `HomeTabSwitcher` | `lib/presentation/pages/home/widgets/` | 首页"今日/全部" SegmentedButton |
| `HomeTaskList` | `lib/presentation/pages/home/widgets/` | 首页任务列表（含今日/全部逻辑） |
| `CompactStatsBar` | `lib/presentation/pages/calendar/widgets/` | 日历页顶部紧凑统计栏 |
| `StatisticsContent` | `lib/presentation/widgets/` | 统计详情（抽离自 StatisticsPage，复用） |
| `StatisticsSheet` | `lib/presentation/widgets/` | 统计详情 Bottom Sheet 包装 |
| `DataManagementSection` | `lib/presentation/pages/settings/widgets/` | 设置页数据管理区块 |
| `ShellFAB` | `lib/presentation/pages/shell/` | Shell层统一FAB |

### 5.3 组件复用策略

- **统计详情**：从 `StatisticsPage` 抽离 body 为 `StatisticsContent`，供 StatisticsSheet 复用
- **任务列表**：首页在 tab=all 时复用 TaskHub 的列表逻辑和 Provider
- **不复制粘贴**：所有可复用组件先抽离，再被多页面引用

---

## 6. 页面详细设计

### 6.1 首页（整合版）

```
┌─────────────────────────────┐
│  🔍 搜索        [筛选] [更多] │  <- AppBar（现有行为保留）
├─────────────────────────────┤
│  [ 今日  ] [ 全部  ]        │  <- HomeTabSwitcher (SegmentedButton)
├─────────────────────────────┤
│  📊 今日进度：5/12          │  <- 进度条（现有）
│  ████████░░░░░░░░░ 42%     │
├─────────────────────────────┤
│  [全部] [待复习] [已完成]   │  <- TaskFilterBar（现有）
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │ [标签] 任务标题      │    │
│  │ 第3次复习 | 逾期    │    │
│  │ [✓完成] [→跳过]     │    │
│  └─────────────────────┘    │
│         ...任务列表...        │
├─────────────────────────────┤
│                       [＋]  │  <- ShellFAB（迁移后，HomePage内FAB移除）
├─────────────────────────────┤
│ [今日] [日历] [设置]        │  <- 底部导航（3个）
└─────────────────────────────┘
```

**关键约束**：
- HomePage 内原有 FAB（`lib/presentation/pages/home/home_page.dart:176`）必须移除
- ShellFAB 在设置页隐藏（通过 ShellScaffold 判断当前路由）

### 6.2 日历页（整合版）

```
┌─────────────────────────────┐
│  < 二月 2026 >              │  <- 月份切换
├─────────────────────────────┤
│  ⭐ 连续3天  |  📈 本周80%  │  <- CompactStatsBar（点击展开）
├─────────────────────────────┤
│  一  二  三  四  五  六  日  │  <- 周头
│     1   2   3   4   5   6  │
│  7   8   9  10  11  12  13  │  <- 日历网格
│ 14  15  16  17  18  19  20  │
│ 21  22 [24] 25  26  27  28  │
├─────────────────────────────┤
│  2月24日 星期二              │  <- 选中日期
│  ┌─────────────────────┐    │
│  │ 任务1               │    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│ [今日] [日历] [设置]        │
└─────────────────────────────┘
```

**点击 CompactStatsBar**：弹出 StatisticsSheet（复用 StatisticsContent）

**Sheet 冲突**：打开统计 Sheet 前检查并关闭已打开的 DayTaskListSheet

### 6.3 设置页（聚合版）

```
┌─────────────────────────────┐
│         设置                │
├─────────────────────────────┤
│  🔔 提醒                     │
│  ┌─────────────────────┐    │
│  │ 提醒时间    09:00   >│    │
│  │ 免打扰      22:00   >│    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  🎨 外观                     │
│  ┌─────────────────────┐    │
│  │ 主题模式    跟随系统 >│    │
│  └─────────────────────┘    │
├─────────────────────────────┤
│  💾 数据管理                 │
│  ┌─────────────────────┐    │
│  │ 📤 导出     2分钟前 >│    │  <- 点击 → ExportPage
│  ├─────────────────────┤    │
│  │ 📥 备份/恢复   已同步 >│    │  <- 点击 → BackupPage
│  ├─────────────────────┤    │
│  │ 🔄 同步      已连接 3 >│    │  <- 点击 → SyncSettingsPage
│  └─────────────────────┘    │
├─────────────────────────────┤
│  ❓ 帮助                     │  <- 点击 → /help
├─────────────────────────────┤
│  ℹ️ 关于                     │
└─────────────────────────────┘
```

---

## 7. 桌面快捷键联动

**现状**：`desktop_shortcuts.dart:93` 有基于 `/statistics` 的刷新分支

**改动**：
- 刷新快捷键改为触发 `/calendar` 页面刷新
- 或改为触发统计缓存刷新（不改变路由）

---

## 8. 组件变更清单

### 8.1 新增组件

| 组件 | 放置位置 | 用途 |
|------|----------|------|
| `HomeTabSwitcher` | `lib/presentation/pages/home/widgets/` | 首页"今日/全部"切换器 |
| `HomeTaskList` | `lib/presentation/pages/home/widgets/` | 首页任务列表 |
| `CompactStatsBar` | `lib/presentation/pages/calendar/widgets/` | 日历页顶部统计栏 |
| `StatisticsContent` | `lib/presentation/widgets/` | 统计详情内容（抽离） |
| `StatisticsSheet` | `lib/presentation/widgets/` | 统计详情 Sheet 包装 |
| `DataManagementSection` | `lib/presentation/pages/settings/widgets/` | 设置页数据管理区块 |
| `ShellFAB` | `lib/presentation/pages/shell/` | Shell层统一FAB |

### 8.2 移除/修改组件

| 组件 | 处理 |
|------|------|
| `HomePage内FAB` | 移除，由 ShellFAB 替代 |
| `TaskHubPage` | 不再作为独立页面，逻辑复用 |
| `StatisticsPage` | 保留页面，抽离 StatisticsContent 供复用 |

### 8.3 路由变更

| 现状路由 | 改进后路由 | 处理方式 |
|----------|------------|----------|
| `/tasks` | `/home?tab=all` | redirect |
| `/statistics` | `/calendar?openStats=1` | redirect，进入后自动展开统计详情 |
| `/settings/help` | `/help` | redirect，/help为真实全屏页 |
| `/settings/export` | `/settings/export` | 保留页面路由；入口从设置页聚合进入 |
| `/settings/backup` | `/settings/backup` | 保留页面路由；入口从设置页聚合进入 |
| `/settings/sync` | `/settings/sync` | 保留页面路由；入口从设置页聚合进入 |

---

## 9. 验收标准

### 9.1 功能验收

- [ ] Shell内底部导航只有3个Tab
- [ ] 首页支持"今日/全部"页面内 SegmentedButton 切换
- [ ] 首页在 tab=all 时复用 TaskHub 逻辑（分页、筛选）
- [ ] 日历页顶部显示 CompactStatsBar（连续打卡+本周完成率）
- [ ] 点击 CompactStatsBar 展开 StatisticsSheet
- [ ] 设置页有数据管理入口区块（导出/备份/同步）
- [ ] 录入功能通过 Shell 层 FAB 触发
- [ ] HomePage 内原有 FAB 已移除

### 9.2 交互验收

- [ ] 页面内 SegmentedButton 切换动画流畅
- [ ] 统计 Sheet 展开/收起动画流畅
- [ ] FAB 位置符合拇指操作区
- [ ] 桌面端快捷键刷新对应正确的页面/数据
- [ ] 设置页不显示 FAB

### 9.3 路由兼容验收

- [ ] 访问 `/tasks` 正确跳转到 `/home?tab=all`
- [ ] 访问 `/statistics` 正确跳转到 `/calendar?openStats=1`，并自动弹出 StatisticsSheet
- [ ] 访问 `/settings/help` 正确跳转到 `/help`
- [ ] `/help` 为真实全屏页面（不显示底部导航栏）

### 9.4 关键能力防回归验收

- [ ] Home 的批量模式仍可用（仅 tab=today + filter=pending）
- [ ] Home 的主题筛选仍可用
- [ ] 同步入口仍可用（点击跳转 SyncSettingsPage）
- [ ] 导出流程完整（点击跳转 ExportPage）
- [ ] 备份/恢复流程完整（点击跳转 BackupPage）

### 9.5 Sheet 冲突验收

- [ ] 日历的"当日任务列表 Sheet"和"统计详情 Sheet"不会叠加
- [ ] 打开一个 Sheet 前会先关闭另一个

### 9.6 视觉验收

- [ ] 深浅主题下布局正常
- [ ] 文字对比度符合无障碍标准（≥4.5:1）
- [ ] 触摸目标≥44px

---

## 10. 实施计划

### 阶段一：路由兼容与 Shell 调整（风险最低）

**目标**：Shell 变 3 Tab + 路由 redirect（保留旧路由不崩）

1. 调整 `ShellScaffold` 的 destinations 为 3 项（移除统计、任务中心）
2. 添加 GoRouter redirect 规则：
    - `/tasks` → `/home?tab=all`
    - `/statistics` → `/calendar?openStats=1`
    - `/settings/help` → `/help`
3. 创建 `/help` 为真实全屏页面（从 Shell 内移出）
4. 验证：手动访问旧路由是否正确跳转

### 阶段二：Shell 层 FAB 统一

**目标**：移除 HomePage 内 FAB，在 Shell 层统一提供

1. 在 `ShellScaffold` 添加全局 FAB（ShellFAB）
2. 移除 `HomePage` 内现有 FAB（`lib/presentation/pages/home/home_page.dart:176`）
3. 设置页隐藏 FAB（ShellScaffold 判断路由）
4. 验证：不会出现双 FAB

### 阶段三：首页 Tab 切换

**目标**：首页支持"今日/全部"二级切换

1. 创建 `HomeTabSwitcher` 组件（SegmentedButton）
2. 修改 `HomePage` 读取 `?tab=` 参数
3. "全部"模式复用 `taskHubProvider`（游标分页、筛选）
4. 定义默认组合：`tab=today` + `filter=pending`
5. 桌面快捷键联动更新（`desktop_shortcuts.dart:93`）
6. 验证：tab=all 模式下筛选、分页正常；批量模式仅在 tab=today + filter=pending 可用

### 阶段四：日历页统计整合

**目标**：日历页顶部显示统计，点击展开详情

1. 创建 `CompactStatsBar` 组件
2. 修改 `CalendarPage` 集成统计栏（watch statisticsProvider）
3. 创建 `StatisticsSheet`，复用 StatisticsPage 的 StatisticsContent
4. 处理 Sheet 冲突：打开前先关闭已打开的 Sheet
5. 验证：CompactStatsBar 数据正确，展开/收起正常

### 阶段五：设置页入口聚合

**目标**：设置页聚合数据管理入口

1. 创建 `DataManagementSection` 组件
2. 修改 `SettingsPage`，聚合导出/备份/同步入口
3. 点击入口仍跳转到现有全屏页面（阶段A不强制Sheet化）
4. 验证：各入口点击后正常跳转到对应页面

---

## 11. 更新日志

| 日期 | 更新内容 |
|------|----------|
| 2026-03-01 | 创建UI布局精简重构规范 v1.0 |
| 2026-03-01 | v1.1：修正与现有代码不一致之处，补充路由兼容、组件形态、验收标准 |
| 2026-03-01 | v1.2：补强为可直接开工的实施规格，增加范围定义、代码绑定、复用策略、两阶段目标、防回归验收 |
| 2026-03-01 | v1.3：修正设置子路由不应 redirect、明确录入路由形态与批量模式范围，并定义 `/statistics` 兼容的自动展开参数 |
| 2026-03-01 | v1.4：明确 FilterBar 状态管理决策（以 TaskHubProvider 为准）、统计 Sheet 触发优先级（弹出期间禁用再次触发） |
