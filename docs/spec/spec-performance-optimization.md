# 忆刻（YiKe）性能优化迭代 - 规格文档（探索融入版）

## 文档信息

- 用途：记录性能瓶颈探索结论、优先级与可落地优化方案
- 作者：Codex
- 创建日期：2026-03-03
- 更新日期：2026-03-04
- 版本：v1.3.0
- 状态：规划中（已完成第一轮代码走查）
- 优先平台：Android（120Hz 设备优先）
- 目标数据规模：`review_tasks > 5000`（大数据量场景）

---

## 1. 背景与目标

### 1.1 背景（用户反馈）

- 多场景存在卡顿，且在 **120Hz 屏幕**上更明显（单帧预算约 **8.3ms**）。
- 典型卡顿点：任务中心/首页 tab=all 滚动、展开/收起、加载更多、搜索输入。

### 1.2 优化目标（可验收）

> 目标以“用户体感 + 可量化 profile 指标”双口径验收。

1. **滚动流畅度**：任务中心与首页（tab=all）连续滚动 10 秒，明显 jank（长条红帧）显著减少。
2. **交互响应**：展开/收起任务卡片、触发分页加载更多时，不出现“输入/滚动冻结”。
3. **搜索体验**：连续快速输入时不掉帧；结果刷新稳定（不出现旧结果覆盖新关键词）。
4. **线程模型**：大部分数据库查询不阻塞 UI isolate（避免明显卡顿尖峰）。

---

## 2. 探索结论（基于代码走查）

> 本节为“单一事实源”：仅记录已在仓库中确认的实现形态与可复现风险点。

### 2.1 UI / 渲染瓶颈（高优先级）

#### 2.1.1 大量毛玻璃模糊（BackdropFilter）用于高频列表卡片

- `GlassCard` 默认 `blurSigma=14`，内部使用 `BackdropFilter(ImageFilter.blur)`：
  - 文件：`lib/presentation/widgets/glass_card.dart`
- `GlassCard(` 在 `lib/presentation` 目录出现次数为 **81**（走查统计），且任务卡片/列表大量使用默认模糊。
- 这类模糊在滚动时会产生较重的离屏渲染/合成成本，120Hz 下更容易超时掉帧。
- 已有先例：帮助页明确在 Windows 端禁用大面积模糊以减少卡顿：
  - 文件：`lib/presentation/pages/help/help_page.dart`

**影响场景（已确认）**
- 任务中心时间线卡片：`lib/presentation/pages/tasks/widgets/task_hub_timeline_list.dart`
- 首页任务卡片：`lib/presentation/pages/home/home_page.dart`

#### 2.1.2 任务中心时间线当前为“非虚拟化列表”

- `TaskHubTimelineList` 在 `build()` 内：
  1) 先遍历 `state.items` 进行按天分组（Map putIfAbsent）
  2) 再对分组 key 做排序
  3) 再用 `Column + for (...)` 一次性构建所有日期组与卡片
- 文件：`lib/presentation/pages/tasks/widgets/task_hub_timeline_list.dart`

**结论**
- 分页加载越多，UI 构建与布局成本线性增长。
- 即使只是展开态变化（`expandedTaskIds`），也会触发整段列表的重新分组/构建，容易产生 jank。

#### 2.1.3 首页 tab=all 复用任务中心列表形态，风险同源

- 首页 `HomePage` 的 tab=all 复用了 `TaskHubTimelineList`，并用独立 `ScrollController` 触发分页：
  - 文件：`lib/presentation/pages/home/home_page.dart`

**结论**
- tab=all 的滚动/展开卡顿问题与任务中心同源（列表不虚拟化 + 毛玻璃模糊）。

### 2.2 数据库 / IO 瓶颈（高优先级）

#### 2.2.1 数据库打开方式为 NativeDatabase(file)，大查询很可能运行在 UI isolate

- `AppDatabase.open()` 使用 `LazyDatabase` 包裹，但最终 executor 为 `NativeDatabase(file)`：
  - 文件：`lib/data/database/database.dart`

**结论**
- 在大数据量下，搜索/聚合/时间线分页 SQL 易形成 UI isolate 阻塞（体感为“突然卡住”）。
- 建议改为 Drift 官方推荐的后台方案（如 `NativeDatabase.createInBackground`）。

#### 2.2.2 搜索属于全表扫描范式，且当前“防抖不可取消”会放大压力

- 搜索 SQL 使用 `LIKE '%keyword%'`，并包含对子任务 `EXISTS (...) content LIKE '%keyword%'`：
  - 文件：`lib/data/database/daos/learning_item_dao.dart` → `searchLearningItems()`
- UI 侧搜索 provider 仅使用 `Future.delayed(300ms)`，旧请求无法取消：
  - 文件：`lib/presentation/providers/search_provider.dart`

**结论**
- `%keyword%` 难以利用常规索引，数据量增大时不可避免地变慢。
- “不可取消防抖”会导致用户快速输入时产生多次无意义查询，进一步加重卡顿。

#### 2.2.3 任务中心时间线 SQL 在查询中计算 occurredAt，排序/分页索引利用空间有限

- 时间线分页 query 使用 CASE/COALESCE 计算 `occurred_at` 并排序：
  - 文件：`lib/data/database/daos/review_task_dao.dart` → `getTaskTimelinePageWithItem()`
- 当前 `review_tasks` 已存在一些索引（见 2.4），但对“计算字段排序”帮助有限。

**结论**
- 在 `review_tasks` 数据量很大时，分页查询可能仍出现明显开销（尤其在 status/all 条件下）。
- 若确认该查询是热点，应考虑把 `occurred_at` 落地为列并建立复合索引（需要 schemaVersion 升级）。

### 2.3 其他潜在热点（已确认存在，但需 profile 验证优先级）

1. **日历月统计**：先拉取整月 `scheduled_date + status` 明细，再在 Dart 侧按天聚合：
   - 文件：`lib/data/database/daos/review_task_dao.dart` → `getMonthlyTaskStats()`
2. **连续打卡天数**：会一次性拉取范围内的 `done/pending` 任务到内存再按天聚合：
   - 文件：`lib/data/database/daos/review_task_dao.dart` → `getConsecutiveCompletedDays()`
3. **同步批量应用**：`applyIncomingEvents` 在事务内逐条 `_applySingleEvent`，存在映射查询开销：
   - 文件：`lib/infrastructure/sync/sync_service.dart`

---

## 2.4 已存在的“反向证据”（避免误判）

> 本节用于纠正文档早期猜测：有些索引/优化其实已经存在。

### 2.4.1 review_tasks 已存在的索引

- 表定义中已声明（Drift 生成索引）：
  - `idx_scheduled_date (scheduled_date)`
  - `idx_status (status)`
  - `idx_learning_item_id (learning_item_id)`
  - `idx_completed_at_status (completed_at, status)`
  - `idx_skipped_at_status (skipped_at, status)`
  - 文件：`lib/data/database/tables/review_tasks_table.dart`

### 2.4.2 任务中心已采用游标分页（方向正确）

- 任务中心页面触发 `loadMore()` 使用游标（occurredAt + taskId）而非 offset：
  - 文件：`lib/presentation/pages/tasks/task_hub_page.dart`
  - Provider：`lib/presentation/providers/task_hub_provider.dart`
  - DAO：`lib/data/database/daos/review_task_dao.dart`

**结论**
- “分页策略”本身方向是正确的；当前主要短板在 UI 渲染形态与数据库线程模型。

---

## 3. 优化范围与非目标

### 3.1 范围（允许的变更）

1. **UI 层**：列表虚拟化（`ListView.builder`/Sliver）、降低滚动时合成压力、动效降级。
2. **状态管理**：拆分 watch 范围、`select` 精准订阅、避免大面积 rebuild。
3. **数据库层**：
   - 允许升级数据库打开方式（后台 isolate）。
   - 允许新增索引与 SQL 优化。
   - 允许 **小幅 schema 变更**（新增列/FTS 虚表），前提是迁移逻辑完整且可回滚。

### 3.2 非目标（本次不做）

- 引入全新状态管理框架（保持 Riverpod）。
- 大规模重构业务 Domain 规则。
- 为了性能牺牲核心正确性（例如丢数据、状态不一致）。

---

## 4. 分阶段方案（建议按 ROI 排序落地）

### Phase 1（立竿见影）：降低滚动 GPU/合成压力 + 列表虚拟化

1. **毛玻璃开关（设置项）**
   - 需求：做成一个设置可选项，**默认开启，可关闭**。
   - 目标：当关闭时，任务列表卡片将 `GlassCard.blurSigma` 设为 0，仅保留半透明与边框。
   - 备注：建议作为“按设备本地设置”，不强制参与同步（不同设备性能差异较大）。
2. **任务中心/首页 tab=all 列表改为虚拟化**
   - 用 `ListView.builder` 或 `CustomScrollView + SliverList` 替代 `Column + for`。
   - 将“分组/排序”从 build 热路径移出，改为：
     - Provider 侧基于 `items` 预处理为行模型（header/task row）
     - UI builder 按 index 惰性构建
3. **卡片级 RepaintBoundary**
   - 对大列表中的单个任务卡片加 `RepaintBoundary`，减少滚动时重绘传播。

### Phase 2（上限提升）：数据库后台 isolate + 搜索可取消防抖

1. **数据库后台化**
   - 将 `NativeDatabase(file)` 改为后台 executor（如 `NativeDatabase.createInBackground`）。
2. **搜索 provider 可取消**
   - 避免旧关键词查询继续跑完并回写。
   - 实现策略：基于 `autoDispose` 的 `ref.onDispose` + token/flag 短路，确保仅最新关键词触发查询。

### Phase 3（大数据量硬优化）：任务时间线 occurred_at 落地 + 复合索引（需要迁移）

1. 在 `review_tasks` 增加 `occurred_at` 列（DateTime）
2. 建立索引：
   - `(occurred_at, id)`
   - `(status, occurred_at, id)`
3. 所有写任务状态的入口维护 `occurred_at`（pending/done/skipped/undo/adjust）

### Phase 4（增强）：搜索引入 FTS5（大规模检索场景）

- 建立 `learning_items` 的 FTS5 索引表（title/description/note/subtask 内容）
- 用触发器或应用层写入维护一致性
- 同步/备份需要明确 FTS 数据的再生成策略（一般可重建）

---

## 5. 验证方式（建议固定流程）

### 5.1 Profile 基线录制（每个 Phase 完成后复测）

1. `flutter run --profile -d <设备ID>`（Android 真机）
2. Flutter DevTools → Performance：分别录制三段（每段 10~15 秒）
   - 首页 tab=all：快速滚动 + 停止 + 展开/收起
   - 任务中心：滚动触发 loadMore（多次）+ 展开/收起
   - 搜索：连续快速输入（8~12 次变更）

### 5.2 数据库查询验证

- 对关键 SQL 使用 `EXPLAIN QUERY PLAN`（必要时在 Debug 工具页或临时命令入口输出）。
- 重点关注：任务中心分页 SQL 是否走索引、是否出现临时排序（temp b-tree）。

---

## 6. 风险与回滚

1. **数据库迁移风险**
   - 新增列/索引/FTS 可能导致升级耗时与短暂锁表；需保证升级过程在启动时可控。
   - 回滚策略：保留旧查询兜底逻辑（`COALESCE(occurred_at, <旧口径>)`）。
2. **UI 虚拟化风险**
   - 需确保：分页触发、展开态、滚动位置与刷新逻辑正确。
3. **毛玻璃开关的设计取舍**
   - 关闭模糊会改变视觉风格，但这是“以流畅度优先”的可选项；默认仍保持现有质感。
