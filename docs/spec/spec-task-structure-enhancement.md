# 规格变更文档 - 任务结构优化与轮次管理增强

## 文档信息

- 用途：记录用户反馈的产品改进需求与对应规格变更
- 作者：YiKe 团队
- 创建日期：2026-03-01
- 变更类型：功能增强
- 版本：v2.6（修正同步 operation 值、设备映射示例、导出模板措辞）

---

## 0. 变更概述与影响面评估

### 0.1 核心变更点

本次变更是**结构性数据模型变更**，涉及以下模块：

| 层级 | 变更内容 | 影响文件数 |
|------|----------|------------|
| 数据库 | 新增 description 字段 + 新建 learning_subtasks 表 + 保留 note 字段（渐进式废弃） | 2 |
| Domain | 新增 LearningSubtaskEntity / LearningSubtaskRepository | 3 |
| Data | 新增 DAO / Repository 实现 / UseCase | 6 |
| Presentation | 首页/任务中心/日历/详情页/录入/导入/OCR等 UI 展示与编辑 | 13 |
| 同步/备份 | 同步服务/备份导出/导入的字段兼容 | 4 |
| 工具类 | FileParser 解析器支持新格式 | 2 |

### 0.2 变更策略：渐进式而非激进式

**决策**：本次变更**不物理删除 note 字段**，而是采用渐进式迁移策略：

1. **Phase 1（本期）**：
   - 数据库层：schemaVersion 8 → 9，新增 description 字段 + 新建 learning_subtasks 表
   - 数据迁移：历史 note → description/subtasks（启动时自动执行）
   - UI 切换：展示层从 note 切换到 description/subtasks
2. **Phase 2**：搜索扩展 subtasks + 备份导出升级
3. **Phase 3**（1-2 版本后）：考虑物理删除 note 字段

**理由**：
- note 字段在代码中有 30+ 处引用，激进删除风险极高
- 同步/备份协议需要时间演进
- 渐进式迁移可回滚、可验收

---

## 1. 问题陈述

### 1.1 用户反馈

| 序号 | 问题描述 | 影响 |
|------|----------|------|
| P1 | 任务详情仅支持增加复习轮次，不支持减少轮次 | 用户误增轮次后无法回退 |
| P2 | 当前任务结构（标题+备注+标签）不够用 | 用户需要更丰富的任务信息组织方式 |
| P3 | 批量导入页面缺少导入指导 | 用户不清楚文件格式要求，无从下手 |
| P4 | 主题界面缺少说明 | 用户不知道主题是什么、怎么使用 |

### 1.2 根本原因分析

1. **轮次管理不完整**：仅实现了增加轮次功能，缺少减少轮次的逆向操作
2. **任务信息结构单一**：备注字段为纯文本，无法表达层级关系和进度跟踪
3. **导入体验缺失**：批量导入作为高级功能，缺少模板引导导致用户使用门槛高
4. **主题功能认知不足**：主题页面缺少使用说明，用户不理解主题的意义和使用方式

---

## 2. 变更方案概述

### 2.1 核心策略

| 策略 | 说明 |
|------|------|
| 增加减少轮次功能 | 支持用户在任务详情页减少复习轮次，明确影响面和副作用 |
| 任务结构优化 | 标题+描述+子任务+标签，采用渐进式迁移策略 |
| 批量导入模板 | 提供可下载的导入模板文件，降低使用门槛 |
| 主题功能说明 | 在主题页面增加功能说明和引导 |

### 2.2 涉及模块

- **任务详情页**：增加减少轮次操作
- **数据库层**：learning_items 表新增 description、新建 learning_subtasks 表
- **业务逻辑层**：备注到子任务的迁移逻辑、减少轮次 UseCase、同步日志
- **批量导入页面**：模板下载功能
- **主题页面**：功能说明和引导

---

## 3. 减少复习轮次功能

### 3.1 功能概述

为用户提供减少复习轮次的能力，与现有的增加轮次功能形成完整的轮次管理。

### 3.2 规则决策（已解决自相矛盾）

**最终决策**：

| 场景 | 是否允许删除 | 原因 |
|------|--------------|------|
| 最大轮次为 pending | 允许删除 | 无历史负担，直接释放 |
| 最大轮次为已完成/已跳过 | 允许删除 | 用户需要调整复习计划，不应被历史状态阻塞 |

**副作用提示**：
1. 删除已完成后，该轮次不再计入统计连续性
2. **级联删除 review_records**：删除 review_task 会同步删除该轮次的行为历史记录（FK cascade），影响"任务中心时间线审计"和"历史行为追溯"

### 3.3 后端逻辑

**入口**：任务详情操作区（与「增加轮次」按钮并列）

**确认对话框**：
- 标题：「减少复习轮次」
- 内容：
  - 待删除任务为 pending 时：「当前轮次为第 {N} 轮，将删除第 {N} 轮复习任务。该操作不可恢复，是否确认？」
  - 待删除任务为已完成/已跳过时：「当前轮次为第 {N} 轮（已完成/已跳过），将删除第 {N} 轮复习任务。该操作会影响历史统计连续性，是否确认？」
- 按钮：「取消」「确认减少」

**约束**：
- 最小轮次：1 轮（不允许删除最后一轮）
- 当前轮次 <= 1 时，禁用"减少轮次"按钮，提示"已达到最小轮次"

### 3.4 同步日志要求

**关键要求**：减少轮次成功后，必须写同步删除日志。

```dart
// 参考 lib/data/sync/sync_log_writer.dart 的实际签名
await syncLogWriter.logDelete(
  entityType: 'review_task',
  localEntityId: taskId,
  timestampMs: DateTime.now().millisecondsSinceEpoch,
);
```

**理由**：当前 ReviewTaskRepositoryImpl 对 create/update 会写同步日志，但没有"删除某条 review_task"的同步日志。如果减少轮次用物理删除实现，远端设备不会自动删掉那条任务（数据会漂移）。

**实现建议**：在 ReviewTaskRepositoryImpl 增加 `removeLatestReviewRound(int learningItemId)` 方法，内部完成：
1. 查询最大轮次
2. 物理删除该轮次任务（事务内）
3. 调用 `syncLogWriter.logDelete(...)`

### 3.5 DAO 能力补充

现有 ReviewTaskDao 没有按 (learningItemId, reviewRound) 删除的方法（只有 deleteMockReviewTasks）。

**需新增 DAO 方法**：
```dart
Future<int> deleteReviewTaskByRound(int learningItemId, int reviewRound);
```

### 3.6 按钮显示逻辑

| 当前轮次 | 增加按钮 | 减少按钮 |
|----------|----------|----------|
| 1 | 启用（< 10） | 禁用（已达到最小轮次） |
| 2~9 | 启用（< 10） | 启用 |
| 10 | 禁用（已达到最大轮次） | 启用 |

---

## 4. 任务结构变更（note → description + subtasks）

### 4.1 数据模型设计

#### 4.1.1 数据库变更

**learning_items 表变更**：

```sql
-- 新增 description 字段
ALTER TABLE learning_items ADD COLUMN description TEXT;
-- 注意：保留 note 字段，不删除（渐进式迁移）
```

**新增 learning_subtasks 表**：

```sql
CREATE TABLE learning_subtasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,

  -- 业务唯一标识（UUID v4）：用于备份/合并去重、跨设备映射
  uuid TEXT NOT NULL UNIQUE,

  -- 关联的学习内容 ID
  learning_item_id INTEGER NOT NULL,

  -- 子任务内容
  content TEXT NOT NULL,

  -- 排序顺序
  sort_order INTEGER NOT NULL DEFAULT 0,

  -- 创建时间（Drift 统一用 DateTimeColumn）
  created_at INTEGER NOT NULL,

  -- 更新时间（可空）
  updated_at INTEGER,

  -- 是否为模拟数据（已有 mock 隔离字段）
  is_mock_data INTEGER NOT NULL DEFAULT 0,

  FOREIGN KEY (learning_item_id) REFERENCES learning_items(id) ON DELETE CASCADE
);

-- 子任务排序索引
CREATE INDEX idx_learning_subtasks_item_order
ON learning_subtasks(learning_item_id, sort_order);
```

**设计说明**：
- **uuid 字段**：核心表都在做"备份合并去重 + 跨设备映射"，新表如果没有 uuid，备份/同步无法稳定合并
- **is_mock_data 字段**：项目已有 mock 隔离机制，保持对齐
- **createdAt/updatedAt 字段**：Drift 的 DateTimeColumn 在 SQLite 中序列化为 INTEGER（Unix epoch 毫秒），由 drift typeMapping 自动处理，文档用 INTEGER 是直接描述底层存储

#### 4.1.2 子任务进度跟踪（暂不一期实现）

**决策**：v2.0 版本仅实现"清单能力"（只增删改排序），不实现"可勾选完成"的子任务。

**理由**：
- 当前复习任务模型已有多轮次进度跟踪，子任务再做完成态会导致口径混乱
- 一期先验证结构变更的可行性

### 4.2 数据迁移策略

#### 4.2.1 迁移规则（需更"产品可解释"）

**决策**：采用智能解析策略，而非武断的"每行一个子任务"。

| 条件 | 迁移结果 | 示例 |
|------|----------|------|
| note 含列表符号（-、•、1.、①） | 按行解析为 subtasks | `- 第一点\n- 第二点` → 2条子任务 |
| note 为单行/短文本（< 50 字符） | 迁移到 description | "这是简短描述" → description |
| note 为多行且无列表符号 | 第一段 → description，剩余行 → subtasks | 见下方示例 |
| note 为空 | 不迁移 | - |

**迁移示例**：
```
原 note 内容：
"这是学习内容的描述
第一点学习内容
第二点学习内容"

迁移后：
- description: "这是学习内容的描述"
- subtasks:
  - { content: "第一点学习内容", sort_order: 0 }
  - { content: "第二点学习内容", sort_order: 1 }
```

#### 4.2.2 数据库层结构迁移（Drift）

**schemaVersion 变更**：从 8 升级到 9

**lib/data/database/database.dart onUpgrade 步骤**：
```dart
// v1.6：任务结构变更 - description 字段 + learning_subtasks 表
if (from < 9) {
  // 1) 新增 description 列（兼容：历史脏库可能已存在）
  if (!await hasColumn('learning_items', 'description')) {
    await migrator.addColumn(learningItems, learningItems.description);
  }

  // 2) 新建 learning_subtasks 表（兼容：历史脏库表可能已存在）
  if (!await hasTable('learning_subtasks')) {
    await migrator.createTable(learningSubtasks);
  }

  // 3) 创建索引
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_learning_subtasks_item_order ON learning_subtasks (learning_item_id, sort_order)',
  );
}
```

#### 4.2.3 数据迁移（note → description/subtasks）

**触发时机**：数据库结构迁移完成后，由应用层 UseCase 执行

**幂等锚点**：
- 以"note 是否已置空"作为幂等判断（迁移成功后 `note = NULL`）
- SQL 条件：`WHERE note IS NOT NULL AND note != ''`
- 若迁移中断，重启后会继续处理未迁移的 note

**事务原子性**：
- 每个 item 在单事务内完成：插入 subtasks + 写 description + 清空 note
- 避免"部分 subtasks 已写但 note 仍在"的半状态

**实现位置**：
- 新增 `MigrateNoteToSubtasksUseCase`（在 `lib/domain/usecases/`）
- 在 `lib/di/providers.dart` 注册 provider（参考现有 `addReviewRoundUseCaseProvider` 的写法）

**触发位置**：
- 在 `lib/main.dart` 的 App 初始化流程中，数据库就绪后、首次读取数据（首页/日历/任务中心）前执行
- 确保 UI 读取时数据已完成迁移，避免 note/description 字段闪烁或不一致

### 4.3 同步/备份/导出兼容

#### 4.3.1 同步协议字段变更

**当前状态**：
- 同步事件 learning_items 包含 `note` 字段
- review_tasks 包含关联的 note（通过 join）

**v2.0 变更**：
- 同步事件 learning_items 新增 `description` 字段
- 同步事件新增 `learning_subtasks` entityType（需要单独同步）
- **保持 note 字段兼容**：旧客户端数据仍含 note，新客户端解析时优先用 description/subtasks，note 作为 fallback

#### 4.3.2 备份导出兼容

**JSON 导出**（lib/domain/usecases/export_data_usecase.dart）：
```dart
// 变更后
{
  "id": 1,
  "title": "...",
  "description": "...",     // 新增
  "subtasks": [...],         // 新增
  "note": "...",            // 保留，v3.0 可能移除
  "tags": [...]
}
```

**CSV 导出**：
```
id,title,description,subtasks,tags,...
```
- 旧格式导出的 CSV（仅含 note 字段）与新表头不兼容，需引导用户下载新模板
- 导入功能已兼容旧表头（见 5.2.1）

#### 4.3.3 备份导入兼容

- 备份数据含 description/subtasks：正常导入
- 备份数据仅有 note：自动触发迁移逻辑（按 4.2.1 规则）

### 4.4 各链路 UI 变更点

#### 4.4.1 展示类变更

| 页面/组件 | 当前显示 | 变更后显示 |
|-----------|----------|------------|
| 首页卡片副标题 | note（无则显示"点击添加备注"） | description（无则显示 subtasks 数量摘要，如"3 个子任务"） |
| 任务中心卡片 | note | description 或 subtasks 摘要 |
| 日历任务卡片 | note | description 或 subtasks 摘要 |
| 任务详情页 | note 编辑器 | description 编辑器 + subtasks 列表 |
| 学习内容详情页 | note | description + subtasks 列表 |

#### 4.4.2 输入类变更

| 页面/组件 | 当前字段 | 变更后字段 |
|-----------|----------|------------|
| 录入页面 | 备注（note） | 描述（description）+ 子任务列表 |
| 导入预览 | 备注（note） | 描述 + 子任务 |
| OCR 结果页 | 备注（note） | 描述 + 子任务 |
| 模板编辑页 | 备注（note） | 描述 + 子任务 |

#### 4.4.3 搜索功能变更

**当前**：`learning_item_dao.dart` 搜索 title/note

**变更后**：搜索 title/description/subtasks（需要 like 查询 subtasks.content）

### 4.5 Clean Architecture 落地点

#### 4.5.1 Domain 层

**新增实体**：
```dart
class LearningSubtaskEntity {
  final int id;
  final String uuid;
  final int learningItemId;
  final String content;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isMockData;
}
```

**新增仓储接口**：
```dart
abstract class LearningSubtaskRepository {
  Future<List<LearningSubtaskEntity>> getByLearningItemId(int learningItemId);
  Future<void> create(LearningSubtaskEntity subtask);
  Future<void> update(LearningSubtaskEntity subtask);
  Future<void> delete(int id);
  Future<void> reorder(int learningItemId, List<int> subtaskIds);
}
```

**LearningItemEntity 调整**：
- 新增 `description` 字段
- subtasks **不直接嵌入实体**（避免列表页 N+1 查询问题）
- 改为：新增 `LearningItemDetailViewEntity` 或在 Provider 层组合加载，详情页使用 `LearningItemWithSubtasks` 视图对象

#### 4.5.2 Data 层

- 新增 `LearningSubtasksTable`（Drift）
- 新增 `LearningSubtaskDao`
- 新增 `LearningSubtaskRepositoryImpl`
- 新增 `MigrateNoteToSubtasksUseCase`
- 新增 `CreateSubtaskUseCase`、`UpdateSubtaskUseCase`、`DeleteSubtaskUseCase`、`ReorderSubtasksUseCase`

#### 4.5.3 Presentation 层

- `DraftLearningItem` 新增 `description` 和 `subtasks` 字段
- `ParsedItem`（FileParser）新增 `description` 和 `subtasks` 字段
- `taskDetailProvider` 并行加载 item + plan + subtasks
- 录入页面 UI 重构：description 编辑器 + subtasks 列表（可拖拽排序）

#### 4.5.4 DI 注册

在 `lib/di/providers.dart` 注册：
- `learningSubtaskRepositoryProvider`
- `createSubtaskUseCaseProvider`
- `updateSubtaskUseCaseProvider`
- `deleteSubtaskUseCaseProvider`
- `reorderSubtasksUseCaseProvider`
- `migrateNoteToSubtasksUseCaseProvider`

---

## 5. 批量导入模板功能

### 5.1 模板下载的跨平台策略

**实现方案**：
1. 预置模板文件在 `assets/templates/` 目录（TXT/CSV/MD）
2. 点击"下载模板"时：
   - 生成临时文件到应用缓存目录
   - 使用 `share_plus` 或系统分享功能（share sheet）
   - iOS/Android 均有良好体验

**pubspec.yaml 配置**（在现有 `flutter.assets` 列表下**追加**，不要覆盖）：
```yaml
flutter:
  assets:
    # === 现有资源（保留，不要删除） ===
    - assets/markdown/
    - assets/icons/
    # === 新增资源 ===
    - assets/templates/
```

**需新增的模板文件**：
```
assets/templates/
├── import_template.txt    # TXT 模板：每行一个标题
├── import_template.csv     # CSV 模板：标题,描述,子任务,标签
└── import_template.md     # Markdown 模板
```

**不推荐**：直接写入 Downloads 目录（权限问题 + 路径差异）

### 5.2 FileParser 解析器兼容

#### 5.2.1 CSV 格式

**当前支持**：`标题,备注,标签`

**v2.0 支持**：
- 旧表头：`标题,备注,标签` → 备注 → description（单行）
- 新表头：`标题,描述,子任务,标签`
  - 标题：必填
  - 描述：可选
  - 子任务：支持多行（用双引号包裹，换行分隔）
  - 标签：用逗号分隔

**字段映射规则**：
- 旧格式"备注" → **走与 4.2.1 相同的智能解析规则**（含列表符号→subtasks，单行→description，多行→第一段description+其余subtasks），确保导入与升级迁移行为一致
- 新格式"描述"与"子任务"分开解析

#### 5.2.2 Markdown 格式

**当前**：正文全合并为 note

**v2.0**：
- `#` 开头为标题（必须，可带空格）
- description 截止条件（满足任一即截止）：
  - 遇到空行 → 空行前为 description
  - 遇到列表符号（`-`、`*`、`•`）→ 列表前为 description
  - 遇到 `标签:` 或 `tags:` → 该行之前为 description
- `-`（或 `*`、`•`）开头为子任务
- `标签:` 或 `tags:` 开头为标签行（支持多标签用逗号分隔）
- 解析顺序：先解析标题 → 再解析 description → 再解析子任务列表 → 最后解析标签

**示例**：
```markdown
# 英语单词1
这是描述内容
- 第一行子任务
- 第二行子任务

标签: 单词,日常

# 英语单词2
...
```

### 5.3 UI 设计

**位置**：ImportPreviewPage

**UI 规格**：
- AppBar actions 新增「下载模板」按钮（点击弹出格式选择菜单）
- 页面顶部常驻「格式说明」区域（不是只放弹窗）

---

## 6. 主题功能说明

### 6.1 功能概述

在主题页面增加功能说明，帮助用户理解主题的用途和使用方式。

### 6.2 功能说明内容设计

**主题用途说明**：
```
主题可以帮助你将相关的学习内容组织在一起。

例如：
• 「英语学习」主题：包含所有英语单词、语法等学习内容
• 「编程」主题：包含编程语言、算法等学习内容
• 「考试复习」主题：包含某个考试的所有复习资料

按主题查看学习进度，更容易了解自己在某个领域的掌握情况。
```

**使用步骤说明**：
1. 在「设置」页面创建主题
2. 录入学习内容时，选择关联到某个主题
3. 在「主题」页面查看该主题下所有学习内容的进度

### 6.3 关闭与记忆开关

**展示位置**：TopicsPage（现有页面结构）

**关闭机制**：
- 用户点击「我知道了/不再提示」后，说明弹窗关闭
- 状态存储在 settings 表或安全存储（key: `topic_guide_dismissed`，bool 值）
- 下次进入 TopicsPage 时不再自动展示

**再次展示**：
- 提供「重新查看说明」入口（页面内常驻按钮或设置页）
- 用户可主动查看

---

## 7. 路由配置

无新增路由，当前路由可满足需求。

---

## 8. 验收标准

### 8.1 减少轮次功能

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC1.1 | 任务详情包含「减少轮次」按钮 | 查看任务详情，检查按钮 |
| AC1.2 | 点击减少轮次弹出确认对话框 | 点击按钮，验证弹窗内容 |
| AC1.3 | 待删除任务为已完成/已跳过时，弹窗提示"会影响历史统计" | 完成/跳过任务后减少轮次，检查提示 |
| AC1.4 | 确认后删除对应轮次任务 + 写同步删除日志 | 确认减少，验证记录删除 + 检查 sync_logs 表 |
| AC1.5 | 当前轮次=1时禁用减少轮次 | 查看1轮任务，验证按钮禁用 |
| AC1.6 | 减少轮次后任务列表同步刷新 | 操作后查看任务列表 |

### 8.2 任务结构变更

#### 8.2.1 数据模型

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC2.1 | learning_subtasks 表包含 uuid 字段 | 检查数据库 schema |
| AC2.2 | learning_subtasks 表包含 is_mock_data 字段 | 检查数据库 schema |
| AC2.3 | learning_items 表新增 description 字段 | 检查数据库 schema |

#### 8.2.2 数据迁移

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC2.4 | 旧数据 note 正确迁移为 description/subtasks | 导入含 note 的旧备份，验证迁移结果 |
| AC2.5 | 迁移幂等（重复迁移不重复） | 执行迁移两次，验证结果一致 |
| AC2.6 | 迁移后原 note 字段置空 | 迁移后检查数据库 |

#### 8.2.3 UI 展示

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC2.7 | 首页卡片显示 description 或子任务摘要 | 查看首页卡片 |
| AC2.8 | 任务中心卡片显示 description 或子任务摘要 | 查看任务中心 |
| AC2.9 | 任务详情页展示子任务列表 | 查看任务详情 |
| AC2.10 | 搜索支持搜索子任务内容（Phase 2） | 搜索关键词，验证结果 |

#### 8.2.4 CRUD 操作

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC2.11 | 录入页面支持编辑 description | 新建任务，检查 description |
| AC2.12 | 录入页面支持添加/删除/排序子任务 | 操作子任务列表 |
| AC2.13 | 子任务支持拖拽排序 | 长按拖拽 |
| AC2.14 | 任务详情页展示并编辑 description | 查看/编辑任务详情 |

### 8.3 同步/备份/导出

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC3.1 | 同步 learning_items 包含 description | 检查同步日志 |
| AC3.2 | 同步 learning_subtasks 单独同步 | 检查同步日志 |
| AC3.3 | 备份导出 JSON 包含 description/subtasks（Phase 2） | 导出备份，检查 JSON |
| AC3.4 | 备份导出 CSV 包含新表头（Phase 2） | 导出 CSV，检查表头 |
| AC3.5 | 旧备份数据导入触发迁移 | 导入旧备份，验证迁移 |

### 8.4 批量导入模板

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC4.1 | 导入页面提供模板下载入口 | 查看导入页面 |
| AC4.2 | 可下载 TXT/CSV/Markdown 三种模板 | 点击下载 |
| AC4.3 | CSV 支持新旧表头兼容 | 用旧模板导入 |
| AC4.4 | 模板内容符合格式规范 | 用模板导入，验证解析 |
| AC4.5 | 页面展示格式说明 | 查看导入页面 |

### 8.5 主题功能说明

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC5.1 | 首次进入主题页面显示功能说明 | 新用户查看主题页面 |
| AC5.2 | 功能说明包含主题用途说明 | 查看说明内容 |
| AC5.3 | 功能说明包含使用步骤 | 查看说明内容 |

### 8.6 Phase 2 验收（搜索与备份导出升级）

| 编号 | 验收点 | 测试方法 |
|------|--------|----------|
| AC6.1 | 搜索支持搜索子任务内容 | 搜索关键词，验证结果 |
| AC6.2 | 备份导出 JSON 包含 description/subtasks | 导出备份，检查 JSON |
| AC6.3 | 备份导出 CSV 包含新表头 | 导出 CSV，检查表头 |

---

## 9. 优先级与排期

### Phase 1（本期）

| 优先级 | 功能 | 说明 |
|--------|------|------|
| P0 | 减少轮次功能 | 完善轮次管理能力 |
| P0 | 数据库表结构变更 | description + learning_subtasks |
| P0 | 数据迁移逻辑 | note → description/subtasks |
| P0 | UI 展示链路切换 | 首页/任务中心/日历/详情页 |
| P1 | 同步日志补充 | 删除 review_task 日志 |
| P1 | 批量导入模板 | 降低使用门槛 |
| P1 | 主题功能说明 | 帮助用户理解 |

### Phase 2（下期）

| 优先级 | 功能 | 说明 |
|--------|------|------|
| P2 | 搜索功能扩展 | 支持 subtasks 搜索 |
| P2 | 备份导出升级 | 新 JSON/CSV 格式 |
| P3 | 物理删除 note | 视 Phase 1 稳定性而定 |

---

## 10. 测试清单

### 10.1 单元测试

| 测试项 | 测试文件 |
|--------|----------|
| FileParser CSV 新/旧格式兼容 | test/core/file_parser_test.dart |
| FileParser Markdown 新格式解析 | test/core/file_parser_test.dart |
| 数据迁移逻辑 | test/data/migrations/ |
| 减少轮次 UseCase 边界 | test/domain/usecases/ |

### 10.2 集成测试

| 测试项 | 说明 |
|--------|------|
| DB 迁移测试 | 从旧 schema 升级后，note 正确迁移且不重复 |
| 索引存在性 | 验证 idx_learning_subtasks_item_order 存在 |
| 外键级联 | 删除 learning_item 时 subtasks 同步删除 |
| 同步删除日志 | 减少轮次时写 sync_logs |

### 10.3 UI 回归测试

| 测试项 | 说明 |
|--------|------|
| 首页卡片 note → description/摘要 | 验证信息不消失 |
| 任务中心卡片 | 同上 |
| 日历卡片 | 同上 |
| 录入页面 | description + subtasks 编辑正常 |

---

## 11. 完整集成测试

本章定义完整的端到端集成测试，覆盖忆刻（YiKe）项目的**所有核心功能模块**。测试使用内存数据库（NativeDatabase.memory）模拟真实环境，确保各模块间的数据一致性。

> **测试代码说明**：本章测试示例为**参考实现**，展示测试思路与断言逻辑。实际编写时需：
> - **正确的 UseCase 组装方式**（不是 `UseCase(db)`，而是注入 repository）：
>   ```dart
>   // 1. 创建 in-memory 数据库
>   final db = createInMemoryDatabase();
>
>   // 2. 组装依赖（dao → repository → usecase）
>   final learningItemDao = LearningItemDao(db);
>   final learningItemRepo = LearningItemRepositoryImpl(dao: learningItemDao);
>   final createUseCase = CreateLearningItemUseCase(
>     learningItemRepository: learningItemRepo,
>     reviewTaskRepository: ReviewTaskRepositoryImpl(...),
>   );
>
>   // 3. 调用
>   final result = await createUseCase.execute(CreateLearningItemParams(...));
>   ```
> - 同步日志断言使用现有字段：`sync_logs.operation`（非 `action`）
> - 参照现有单测写法（如 `test/domain/usecases/create_learning_item_usecase_test.dart`）

### 11.1 项目功能模块总览

| 模块 | 核心功能 | 测试文件 |
|------|----------|----------|
| 学习内容管理 | 创建、编辑、删除、搜索 | learning_item_integration_test.dart |
| 复习任务管理 | 完成、跳过、撤销、调整日期、增加/减少轮次 | review_task_integration_test.dart |
| 首页任务 | 今日待复习、已完成、已跳过 | home_tasks_integration_test.dart |
| 日历视图 | 月视图任务展示、任务统计 | calendar_integration_test.dart |
| 统计功能 | 今日/历史统计、连续打卡 | statistics_integration_test.dart |
| 批量导入/导出 | CSV/JSON/TXT/MD 解析与导出 | import_export_integration_test.dart |
| 备份/恢复 | 备份导出、合并导入、去重 | backup_restore_integration_test.dart |
| 主题管理 | 创建、编辑、关联学习内容 | topic_integration_test.dart |
| 模板管理 | 创建、编辑、应用模板 | template_integration_test.dart |
| 同步服务 | 同步日志、设备映射、冲突解决 | sync_integration_test.dart |
| OCR 识别 | 图片识别、结果导入 | ocr_integration_test.dart |

### 11.2 测试基础设施

**测试数据库创建**（复用现有 test/helpers/test_database.dart）：
```dart
AppDatabase createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
```

**测试文件组织**：
```
test/
├── integration/
│   # === 本次 spec 变更相关 ===
│   ├── note_to_subtasks_migration_test.dart     # 数据迁移集成测试
│   ├── reduce_review_round_integration_test.dart # 减少轮次集成测试
│   ├── subtask_crud_integration_test.dart       # 子任务 CRUD 集成测试
│   ├── sync_delete_log_integration_test.dart    # 同步删除日志测试
│   ├── backup_restore_compatibility_test.dart   # 备份恢复兼容测试
│   ├── import_template_test.dart                # 导入模板测试
│   ├── full_flow_integration_test.dart          # 完整流程测试
│   # === 核心功能模块 ===
│   ├── learning_item_integration_test.dart      # 学习内容管理测试
│   ├── review_task_integration_test.dart        # 复习任务管理测试
│   ├── home_tasks_integration_test.dart         # 首页任务测试
│   ├── calendar_integration_test.dart           # 日历视图测试
│   ├── statistics_integration_test.dart         # 统计功能测试
│   ├── topic_integration_test.dart             # 主题管理测试
│   ├── template_integration_test.dart           # 模板管理测试
│   ├── sync_integration_test.dart               # 同步服务测试
│   └── ocr_integration_test.dart                # OCR 识别测试
```

### 11.3 学习内容管理集成测试

#### 11.3.1 测试文件
`test/integration/learning_item_integration_test.dart`

#### 11.3.2 测试场景

**场景 1：创建学习内容并生成复习计划**
```dart
test('创建学习内容：自动生成 5 轮复习计划', () async {
  // Act
  final itemId = await CreateLearningItemUseCase(db).execute(
    CreateLearningItemParams(
      title: '英语单词 app',
      description: '学习 app 单词',
      tags: ['英语'],
    ),
  );

  // Assert
  final tasks = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..orderBy([(t) => OrderingTerm.asc(t.reviewRound)]))
      .get();
  expect(tasks.length, 5);
  expect(tasks[0].reviewRound, 1);
  expect(tasks[0].scheduledDate.day, now.day + 1); // 第1轮：1天后
  expect(tasks[1].scheduledDate.day, now.day + 2); // 第2轮：2天后
  expect(tasks[2].scheduledDate.day, now.day + 4); // 第3轮：4天后
  expect(tasks[3].scheduledDate.day, now.day + 7); // 第4轮：7天后
  expect(tasks[4].scheduledDate.day, now.day + 15); // 第5轮：15天后
});
```

**场景 2：搜索学习内容**
```dart
test('搜索：支持按 title 和 description 模糊搜索', () async {
  // Arrange
  await _createLearningItem(db, 'item-1', title: '苹果');
  await _createLearningItem(db, 'item-2', title: '香蕉');
  await _createLearningItem(db, 'item-3', title: '苹果手机', description: '很贵');

  // Act
  final results = await SearchLearningItemsUseCase(db).execute(
    SearchParams(keyword: '苹果'),
  );

  // Assert
  expect(results.length, 2);
  expect(results.any((i) => i.title == '苹果'), true);
  expect(results.any((i) => i.title == '苹果手机'), true);
});
```

**场景 3：软删除学习内容**
```dart
test('删除学习内容：软删除后不再出现在列表中', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-delete');
  await _createReviewTask(db, itemId, 1, now, 'pending');

  // Act
  await DeactivateLearningItemUseCase(db).execute(
    DeactivateParams(learningItemId: itemId),
  );

  // Assert：列表查询不到
  final items = await (select(db.learningItems)
        ..where((t) => t.isDeleted.equals(false)))
      .get();
  expect(items.any((i) => i.id == itemId), false);

  // 但详情页仍可通过 ID 查询（已停用状态）
  final item = await (select(db.learningItems)
        ..where((t) => t.id.equals(itemId)))
      .getSingle();
  expect(item.isDeleted, true);
});
```

**场景 4：更新学习内容描述**
```dart
test('编辑描述：更新后所有轮次任务同步显示新描述', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-desc', description: '旧描述');

  // Act
  await UpdateLearningItemDescriptionUseCase(db).execute(
    UpdateDescriptionParams(learningItemId: itemId, description: '新描述'),
  );

  // Assert
  final item = await (select(db.learningItems)
        ..where((t) => t.id.equals(itemId)))
      .getSingle();
  expect(item.description, '新描述');
});
```

### 11.4 复习任务管理集成测试

#### 11.4.1 测试文件
`test/integration/review_task_integration_test.dart`

#### 11.4.2 测试场景

**场景 1：完成任务并生成下一轮**
```dart
test('完成复习任务：自动生成下一轮复习任务', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-complete');
  final task1Id = await _createReviewTask(db, itemId, 1, now, 'pending');

  // Act
  await CompleteReviewTaskUseCase(db).execute(
    CompleteReviewTaskParams(taskId: task1Id),
  );

  // Assert：第1轮变为已完成，第2轮已生成
  final task1 = await (select(db.reviewTasks)
        ..where((t) => t.id.equals(task1Id)))
      .getSingle();
  expect(task1.status, ReviewTaskStatus.done);
  expect(task1.completedAt, isNotNull);

  final task2 = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..where((t) => t.reviewRound.equals(2)))
      .getSingleOrNull();
  expect(task2, isNotNull);
  expect(task2!.status, ReviewTaskStatus.pending);
});
```

**场景 2：跳过任务不生成下一轮**
```dart
test('跳过复习任务：不生成下一轮，保持跳过状态', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-skip');
  final task1Id = await _createReviewTask(db, itemId, 1, now, 'pending');

  // Act
  await SkipReviewTaskUseCase(db).execute(
    SkipReviewTaskParams(taskId: task1Id),
  );

  // Assert
  final task1 = await (select(db.reviewTasks)
        ..where((t) => t.id.equals(task1Id)))
      .getSingle();
  expect(task1.status, ReviewTaskStatus.skipped);
  expect(task1.skippedAt, isNotNull);

  // 第2轮不存在（跳过不生成下一轮）
  final task2 = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..where((t) => t.reviewRound.equals(2)))
      .getSingleOrNull();
  expect(task2, isNull);
});
```

**场景 3：撤销任务状态**
```dart
test('撤销任务：已完成任务恢复为待复习', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-undo');
  final taskId = await _createReviewTask(db, itemId, 1, now, 'done', completedAt: now);

  // Act
  await UndoTaskStatusUseCase(db).execute(
    UndoTaskStatusParams(taskId: taskId),
  );

  // Assert
  final task = await (select(db.reviewTasks)
        ..where((t) => t.id.equals(taskId)))
      .getSingle();
  expect(task.status, ReviewTaskStatus.pending);
  expect(task.completedAt, isNull);
});
```

**场景 4：调整复习日期**
```dart
test('调整复习日期：修改后续轮次日期', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-adjust');
  await _createReviewTask(db, itemId, 1, now, 'pending');
  await _createReviewTask(db, itemId, 2, now.add(const Duration(days: 2)), 'pending');

  // Act：调整第2轮日期
  final newDate = now.add(const Duration(days: 5));
  await AdjustReviewDateUseCase(db).execute(
    AdjustReviewDateParams(
      learningItemId: itemId,
      reviewRound: 2,
      newDate: newDate,
    ),
  );

  // Assert
  final task2 = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..where((t) => t.reviewRound.equals(2)))
      .getSingle();
  expect(task2.scheduledDate.day, newDate.day);
});
```

**场景 5：增加复习轮次**
```dart
test('增加轮次：扩展艾宾浩斯曲线到第6轮', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-add-round');
  // 已完成5轮
  for (var i = 1; i <= 5; i++) {
    await _createReviewTask(db, itemId, i, now, 'done', completedAt: now);
  }

  // Act
  await AddReviewRoundUseCase(db).execute(
    AddReviewRoundParams(learningItemId: itemId),
  );

  // Assert：第6轮已生成
  final task6 = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..where((t) => t.reviewRound.equals(6)))
      .getSingleOrNull();
  expect(task6, isNotNull);
  expect(task6!.status, ReviewTaskStatus.pending);
  // 第6轮应为第5轮日期 + 30天
  expect(task6.scheduledDate.day, now.day + 30);
});
```

**场景 6：查看复习计划**
```dart
test('查看计划：展示所有轮次状态', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-plan');
  await _createReviewTask(db, itemId, 1, now, 'done', completedAt: now);
  await _createReviewTask(db, itemId, 2, now.add(const Duration(days: 1)), 'pending');
  await _createReviewTask(db, itemId, 3, now.add(const Duration(days: 3)), 'skipped');

  // Act
  final plan = await GetReviewPlanUseCase(db).execute(
    GetReviewPlanParams(learningItemId: itemId),
  );

  // Assert
  expect(plan.length, 3);
  expect(plan[0].status, ReviewTaskStatus.done);
  expect(plan[1].status, ReviewTaskStatus.pending);
  expect(plan[2].status, ReviewTaskStatus.skipped);
});
```

### 11.5 首页任务集成测试

#### 11.5.1 测试文件
`test/integration/home_tasks_integration_test.dart`

#### 11.5.2 测试场景

**场景 1：获取今日待复习任务**
```dart
test('首页待复习：仅返回今日待复习的pending任务', () async {
  // Arrange
  final item1 = await _createLearningItem(db, 'item-today');
  final item2 = await _createLearningItem(db, 'item-tomorrow');

  await _createReviewTask(db, item1, 1, now, 'pending');
  await _createReviewTask(db, item2, 1, now.add(const Duration(days: 1)), 'pending');

  // Act
  final pendingTasks = await GetHomeTasksUseCase(db).execute();

  // Assert
  expect(pendingTasks.length, 1);
  expect(pendingTasks.first.learningItemId, item1);
});
```

**场景 2：获取今日已完成任务**
```dart
test('首页已完成：返回今日完成的任务', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-done-today');
  await _createReviewTask(db, itemId, 1, now, 'done', completedAt: now);

  // Act
  final completedTasks = await GetTodayCompletedTasksUseCase(db).execute();

  // Assert
  expect(completedTasks.length, 1);
  expect(completedTasks.first.learningItemId, itemId);
});
```

**场景 3：获取今日已跳过任务**
```dart
test('首页已跳过：返回今日跳过的任务', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-skipped-today');
  await _createReviewTask(db, itemId, 1, now, 'skipped', skippedAt: now);

  // Act
  final skippedTasks = await GetTodaySkippedTasksUseCase(db).execute();

  // Assert
  expect(skippedTasks.length, 1);
  expect(skippedTasks.first.learningItemId, itemId);
});
```

### 11.6 日历视图集成测试

#### 11.6.1 测试文件
`test/integration/calendar_integration_test.dart`

#### 11.6.2 测试场景

**场景 1：获取指定月份任务统计**
```dart
test('日历统计：返回指定月份每天的任务统计', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-calendar');
  await _createReviewTask(db, itemId, 1, DateTime(2026, 3, 1), 'done', completedAt: DateTime(2026, 3, 1));
  await _createReviewTask(db, itemId, 2, DateTime(2026, 3, 5), 'pending');
  await _createReviewTask(db, itemId, 3, DateTime(2026, 3, 10), 'skipped');

  // Act
  final stats = await GetCalendarTasksUseCase(db).execute(
    GetCalendarTasksParams(year: 2026, month: 3),
  );

  // Assert
  expect(stats[DateTime(2026, 3, 1)]?.completed, 1);
  expect(stats[DateTime(2026, 3, 5)]?.pending, 1);
  expect(stats[DateTime(2026, 3, 10)]?.skipped, 1);
});
```

**场景 2：获取指定日期任务列表**
```dart
test('日历任务：返回指定日期的任务详情', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-day');
  final taskDate = DateTime(2026, 3, 15);
  await _createReviewTask(db, itemId, 1, taskDate, 'pending');

  // Act
  final tasks = await GetTasksByTimeUseCase(db).execute(
    GetTasksByTimeParams(startDate: taskDate, endDate: taskDate),
  );

  // Assert
  expect(tasks.length, 1);
  expect(tasks.first.scheduledDate.day, 15);
});
```

### 11.7 统计功能集成测试

#### 11.7.1 测试文件
`test/integration/statistics_integration_test.dart`

#### 11.7.2 测试场景

**场景 1：获取今日统计**
```dart
test('今日统计：返回当日完成/跳过/待复习数量', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-stats');
  await _createReviewTask(db, itemId, 1, now, 'done', completedAt: now);
  await _createReviewTask(db, itemId, 2, now, 'skipped', skippedAt: now);
  await _createReviewTask(db, itemId, 3, now, 'pending');

  // Act
  final stats = await GetStatisticsUseCase(db).execute(
    GetStatisticsParams(date: now),
  );

  // Assert
  expect(stats.todayCompleted, 1);
  expect(stats.todaySkipped, 1);
  expect(stats.todayPending, 1);
});
```

### 11.8 主题管理集成测试

#### 11.8.1 测试文件
`test/integration/topic_integration_test.dart`

#### 11.8.2 测试场景

**场景 1：创建主题**
```dart
test('创建主题：成功创建并生成 uuid', () async {
  // Act
  final topicId = await ManageTopicUseCase(db).execute(
    CreateTopicParams(name: '英语学习', description: '英语相关'),
  );

  // Assert
  final topic = await (select(db.learningTopics)
        ..where((t) => t.id.equals(topicId)))
      .getSingle();
  expect(topic.name, '英语学习');
  expect(topic.uuid, isNotNull);
});
```

**场景 2：关联学习内容到主题**
```dart
test('关联主题：学习内容关联到主题', () async {
  // Arrange
  final topicId = await _createTopic(db, 'topic-link');
  final itemId = await _createLearningItem(db, 'item-topic');

  // Act
  await ManageTopicUseCase(db).execute(
    LinkItemToTopicParams(topicId: topicId, learningItemId: itemId),
  );

  // Assert
  final relations = await (select(db.topicItemRelations)
        ..where((t) => t.topicId.equals(topicId))
        ..where((t) => t.learningItemId.equals(itemId)))
      .get();
  expect(relations.length, 1);
});
```

### 11.9 模板管理集成测试

#### 11.9.1 测试文件
`test/integration/template_integration_test.dart`

#### 11.9.2 测试场景

**场景 1：创建模板**
```dart
test('创建模板：成功创建并生成占位符内容', () async {
  // Act
  final templateId = await ManageTemplateUseCase(db).execute(
    CreateTemplateParams(
      name: '单词模板',
      titlePattern: '{{title}}',
      notePattern: '发音：{{pronunciation}}\n释义：{{meaning}}',
    ),
  );

  // Assert
  final template = await (select(db.learningTemplates)
        ..where((t) => t.id.equals(templateId)))
      .getSingle();
  expect(template.name, '单词模板');
});
```

**场景 2：应用模板**
```dart
test('应用模板：替换占位符生成学习内容', () async {
  // Arrange
  final templateId = await _createTemplate(db, 'template-apply');

  // Act
  final result = await ManageTemplateUseCase(db).execute(
    ApplyTemplateParams(
      templateId: templateId,
      variables: {'title': 'hello', 'pronunciation': '/həˈloʊ/', 'meaning': '你好'},
    ),
  );

  // Assert
  expect(result.title, 'hello');
  expect(result.note, contains('发音：/həˈloʊ/'));
  expect(result.note, contains('释义：你好'));
});
```

### 11.10 同步服务集成测试

#### 11.10.1 测试文件
`test/integration/sync_integration_test.dart`

#### 11.10.2 测试场景

**场景 1：写入同步日志**
```dart
test('同步日志：创建/更新/删除操作正确记录', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-sync');

  // Act：创建学习内容
  // ... (通过 LearningItemRepositoryImpl.create 触发 sync.logEvent(...operation: 'create'...))

  // Assert：现有 operation 取值为 create/update/delete，由仓储方法触发
  final logs = await (select(db.syncLogs)
        ..where((t) => t.entityType.equals('learning_item'))
        ..where((t) => t.operation.equals('create')))  // 创建操作对应 'create'，非 'upsert'
      .get();
  expect(logs.length, 1);
});
```

**场景 2：设备映射（参考实现，已删除）**
> 此段为旧草稿，SyncService(db).registerMapping 与 remoteEntityUuid API 不存在。现有同步使用 SyncLogWriter.resolveOriginKey + sync_entity_mappings 表的 originDeviceId/originEntityId/localEntityId 映射。
  await SyncService(db).registerMapping(
    entityType: 'learning_item',
    localId: 1,
    remoteId: 'remote-uuid-1',
    deviceId: 'device-A',
  );

  // Assert
  final mapping = await (select(db.syncEntityMappings)
        ..where((t) => t.localEntityId.equals(1)))
      .getSingle();
  expect(mapping.remoteEntityUuid, 'remote-uuid-1');
});
```

### 11.11 OCR 识别集成测试

#### 11.11.1 测试文件
`test/integration/ocr_integration_test.dart`

#### 11.11.2 测试场景

**场景 1：识别图片文本**
```dart
test('OCR 识别：从图片提取文本并解析为学习内容', () async {
  // Arrange：准备包含文字的图片
  final imagePath = 'test/fixtures/ocr_sample.png';

  // Act
  final result = await OcrRecognitionUseCase(db).execute(
    OcrRecognitionParams(imagePath: imagePath),
  );

  // Assert
  expect(result.items.length, greaterThan(0));
  expect(result.items.first.title, isNotEmpty);
});
```

### 11.12 数据迁移集成测试

#### 11.12.1 测试文件
`test/integration/note_to_subtasks_migration_test.dart`

#### 11.12.2 测试场景

**场景 1：含列表符号的 note 迁移**
```dart
test('note 含列表符号（-）时，按行解析为 subtasks', () async {
  // Arrange：创建含列表符号的 note
  final itemId = await db.into(db.learningItems).insert(
    LearningItemsCompanion.insert(
      uuid: const Value('item-list'),
      title: '测试列表',
      note: const Value('- 第一点\n- 第二点\n- 第三点'),
      learningDate: now,
    ),
  );

  // Act：执行迁移
  await MigrateNoteToSubtasksUseCase(db).execute();

  // Assert
  final subtasks = await (select(db.learningSubtasks)
        ..where((t) => t.learningItemId.equals(itemId)))
      .get();
  expect(subtasks.length, 3);
  expect(subtasks[0].content, '第一点');
  expect(subtasks[1].content, '第二点');
  expect(subtasks[2].content, '第三点');
});
```

**场景 2：单行文本迁移到 description**
```dart
test('note 为短文本时，迁移到 description', () async {
  // Arrange
  await db.into(db.learningItems).insert(
    LearningItemsCompanion.insert(
      uuid: const Value('item-single'),
      title: '测试单行',
      note: const Value('这是简短描述'),
      learningDate: now,
    ),
  );

  // Act
  await MigrateNoteToSubtasksUseCase(db).execute();

  // Assert
  final item = await (select(db.learningItems)
        ..where((t) => t.uuid.equals('item-single')))
      .getSingle();
  expect(item.description, '这是简短描述');
  expect(item.note, isNull); // note 已置空
});
```

**场景 3：多行无列表符迁移**
```dart
test('note 为多行无列表符时，第一段作 description，其余作 subtasks', () async {
  // Arrange
  await db.into(db.learningItems).insert(
    LearningItemsCompanion.insert(
      uuid: const Value('item-multiline'),
      title: '测试多行',
      note: const Value('这是描述\n第二行\n第三行'),
      learningDate: now,
    ),
  );

  // Act
  await MigrateNoteToSubtasksUseCase(db).execute();

  // Assert
  final item = await (select(db.learningItems)
        ..where((t) => t.uuid.equals('item-multiline')))
      .getSingle();
  expect(item.description, '这是描述');

  final subtasks = await (select(db.learningSubtasks)
        ..where((t) => t.learningItemId.equals(item.id))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();
  expect(subtasks.length, 2);
  expect(subtasks[0].content, '第二行');
  expect(subtasks[1].content, '第三行');
});
```

**场景 4：迁移幂等性**
```dart
test('重复迁移不产生重复数据', () async {
  // Arrange：已迁移的数据
  final itemId = await db.into(db.learningItems).insert(
    LearningItemsCompanion.insert(
      uuid: const Value('item-idempotent'),
      title: '测试幂等',
      note: const Value('内容'),
      learningDate: now,
    ),
  );
  await db.into(db.learningSubtasks).insert(
    LearningSubtasksCompanion.insert(
      uuid: const Value('subtask-1'),
      learningItemId: itemId,
      content: '内容',
      sortOrder: 0,
      createdAt: now,
    ),
  );

  // Act：再次执行迁移
  await MigrateNoteToSubtasksUseCase(db).execute();

  // Assert：只有 1 条子任务
  final subtasks = await (select(db.learningSubtasks)
        ..where((t) => t.learningItemId.equals(itemId)))
      .get();
  expect(subtasks.length, 1);
});
```

**场景 5：外键级联删除**
```dart
test('删除 learning_item 时，subtasks 同步删除', () async {
  // Arrange
  final itemId = await db.into(db.learningItems).insert(
    LearningItemsCompanion.insert(
      uuid: const Value('item-cascade'),
      title: '测试级联',
      learningDate: now,
    ),
  );
  await db.into(db.learningSubtasks).insert(
    LearningSubtasksCompanion.insert(
      uuid: const Value('subtask-cascade'),
      learningItemId: itemId,
      content: '子任务',
      sortOrder: 0,
      createdAt: now,
    ),
  );

  // Act
  await (delete(db.learningItems)
        ..where((t) => t.id.equals(itemId)))
      .go();

  // Assert
  final subtasks = await (select(db.learningSubtasks)
        ..where((t) => t.learningItemId.equals(itemId)))
      .get();
  expect(subtasks, isEmpty);
});
```

### 11.13 减少轮次集成测试

#### 11.3.1 测试文件
`test/integration/reduce_review_round_integration_test.dart`

#### 11.3.2 测试场景

**场景 1：删除 pending 状态的任务**
```dart
test('减少轮次：删除 pending 状态任务', () async {
  // Arrange：创建 3 轮复习任务
  final itemId = await _createLearningItem(db, 'item-pending');
  await _createReviewTask(db, itemId, 1, now, 'pending');
  await _createReviewTask(db, itemId, 2, now.add(const Duration(days: 1)), 'pending');
  await _createReviewTask(db, itemId, 3, now.add(const Duration(days: 3)), 'pending');

  // Act
  final result = await ReduceReviewRoundUseCase(db).execute(
    ReduceReviewRoundParams(learningItemId: itemId),
  );

  // Assert
  expect(result.success, true);
  final tasks = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..orderBy([(t) => OrderingTerm.desc(t.reviewRound)]))
      .get();
  expect(tasks.length, 2);
  expect(tasks.first.reviewRound, 2);
});
```

**场景 2：删除已完成的任务并验证统计影响**
```dart
test('减少轮次：删除已完成任务，弹窗提示统计影响', () async {
  // Arrange：第 3 轮已完成
  final itemId = await _createLearningItem(db, 'item-done');
  await _createReviewTask(db, itemId, 1, now, 'done');
  await _createReviewTask(db, itemId, 2, now, 'done');
  await _createReviewTask(db, itemId, 3, now, 'done', completedAt: now);

  // Act：尝试减少轮次
  final result = await ReduceReviewRoundUseCase(db).execute(
    ReduceReviewRoundParams(learningItemId: itemId),
  );

  // Assert：删除成功，但返回警告标志
  expect(result.success, true);
  expect(result.hasWarning, true);
  expect(result.warningMessage, contains('历史统计'));
});
```

**场景 3：写同步删除日志**
```dart
test('减少轮次：成功删除后写同步日志', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-sync');
  final taskId = await _createReviewTask(db, itemId, 1, now, 'pending');

  // Act
  await ReduceReviewRoundUseCase(db).execute(
    ReduceReviewRoundParams(learningItemId: itemId),
  );

  // Assert：检查 sync_logs
  final logs = await (select(db.syncLogs)
        ..where((t) => t.entityType.equals('review_task'))
        ..where((t) => t.operation.equals('delete')))  // 字段名为 operation，非 action
      .get();
  expect(logs.length, 1);
  // 现有 sync_logs 表通过 entityId 字段记录 remote 端 ID，非 localEntityId
});
```

**场景 4：最小轮次边界**
```dart
test('减少轮次：只有 1 轮时禁止删除', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-min');
  await _createReviewTask(db, itemId, 1, now, 'pending');

  // Act
  final result = await ReduceReviewRoundUseCase(db).execute(
    ReduceReviewRoundParams(learningItemId: itemId),
  );

  // Assert
  expect(result.success, false);
  expect(result.errorMessage, contains('最小轮次'));
});
```

**场景 5：已停用学习内容禁止操作**
```dart
test('减少轮次：学习内容已停用时拒绝操作', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-deleted', isDeleted: true);
  await _createReviewTask(db, itemId, 1, now, 'pending');
  await _createReviewTask(db, itemId, 2, now.add(const Duration(days: 1)), 'pending');

  // Act
  final result = await ReduceReviewRoundUseCase(db).execute(
    ReduceReviewRoundParams(learningItemId: itemId),
  );

  // Assert
  expect(result.success, false);
  expect(result.errorMessage, contains('已停用'));
});
```

### 11.14 子任务 CRUD 集成测试

#### 11.4.1 测试文件
`test/integration/subtask_crud_integration_test.dart`

#### 11.4.2 测试场景

**场景 1：创建子任务**
```dart
test('创建子任务：成功创建并生成 uuid', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-create');

  // Act
  final subtask = await CreateSubtaskUseCase(db).execute(
    CreateSubtaskParams(
      learningItemId: itemId,
      content: '新子任务',
    ),
  );

  // Assert
  expect(subtask.id, isNotNull);
  expect(subtask.uuid, isNotNull);
  expect(subtask.content, '新子任务');
  expect(subtask.sortOrder, 0);
});
```

**场景 2：更新子任务内容**
```dart
test('更新子任务：修改内容', () async {
  // Arrange
  final subtaskId = await _createSubtask(db, 'content-old');

  // Act
  await UpdateSubtaskUseCase(db).execute(
    UpdateSubtaskParams(id: subtaskId, content: 'content-new'),
  );

  // Assert
  final subtask = await (select(db.learningSubtasks)
        ..where((t) => t.id.equals(subtaskId)))
      .getSingle();
  expect(subtask.content, 'content-new');
});
```

**场景 3：删除子任务**
```dart
test('删除子任务：物理删除', () async {
  // Arrange
  final subtaskId = await _createSubtask(db, 'to-delete');

  // Act
  await DeleteSubtaskUseCase(db).execute(DeleteSubtaskParams(id: subtaskId));

  // Assert
  final subtask = await (select(db.learningSubtasks)
        ..where((t) => t.id.equals(subtaskId)))
      .getOrNull();
  expect(subtask, isNull);
});
```

**场景 4：拖拽排序**
```dart
test('子任务排序：拖拽后 sort_order 更新', () async {
  // Arrange
  final itemId = await _createLearningItem(db, 'item-reorder');
  await _createSubtask(db, 'task-1', itemId, 0);
  await _createSubtask(db, 'task-2', itemId, 1);
  await _createSubtask(db, 'task-3', itemId, 2);

  // Act：拖拽将 task-3 移到第一位
  await ReorderSubtasksUseCase(db).execute(
    ReorderSubtasksParams(learningItemId: itemId, subtaskIds: [3, 1, 2]),
  );

  // Assert
  final subtasks = await (select(db.learningSubtasks)
        ..where((t) => t.learningItemId.equals(itemId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();
  expect(subtasks[0].content, 'task-3');
  expect(subtasks[1].content, 'task-1');
  expect(subtasks[2].content, 'task-2');
});
```

### 11.15 备份恢复兼容测试

#### 11.5.1 测试文件
`test/integration/backup_restore_compatibility_test.dart`

#### 11.5.2 测试场景

**场景 1：新格式备份导出**
```dart
test('备份导出：JSON 包含 description 和 subtasks', () async {
  // Arrange
  final itemId = await _createLearningItemWithSubtasks(db);

  // Act
  final json = await ExportDataUseCase(db).exportJson();

  // Assert
  final items = json['learning_items'] as List;
  final item = items.first;
  expect(item['description'], isNotNull);
  expect(item['subtasks'], isA<List>());
});
```

**场景 2：旧格式备份导入触发迁移**
```dart
test('备份导入：旧数据（仅有 note）自动迁移', () async {
  // Arrange：构造旧格式备份数据
  final oldBackup = _createOldFormatBackup();

  // Act
  await ImportBackupUseCase(db).execute(ImportBackupParams(data: oldBackup));

  // Assert：验证自动迁移
  final items = await db.select(db.learningItems).get();
  expect(items.first.description, isNotNull);
  expect(items.first.note, isNull); // note 已置空
});
```

### 11.16 导入模板测试

#### 11.6.1 测试文件
`test/integration/import_template_test.dart`

#### 11.6.2 测试场景

**场景 1：CSV 新格式解析**
```dart
test('FileParser：CSV 新格式（标题,描述,子任务,标签）正确解析', () async {
  // Arrange
  final csv = '''标题,描述,子任务,标签
单词1,描述内容,"子任务1
子任务2","标签1,标签2"
''';

  // Act
  final items = FileParser.parseCsv(csv);

  // Assert
  expect(items.length, 1);
  expect(items.first.title, '单词1');
  expect(items.first.description, '描述内容');
  expect(items.first.subtasks, ['子任务1', '子任务2']);
  expect(items.first.tags, ['标签1', '标签2']);
});
```

**场景 2：CSV 旧格式兼容**
```dart
test('FileParser：CSV 旧格式（标题,备注,标签）兼容', () async {
  // Arrange
  final csv = '''标题,备注,标签
单词1,备注内容,标签1
''';

  // Act
  final items = FileParser.parseCsv(csv);

  // Assert：旧备注映射到 description
  expect(items.first.description, '备注内容');
});
```

**场景 3：Markdown 新格式解析**
```dart
test('FileParser：Markdown 新格式正确解析', () async {
  // Arrange
  final md = '''# 单词1
这是描述内容
- 子任务1
- 子任务2

标签: 标签1,标签2
''';

  // Act
  final items = FileParser.parseMarkdown(md);

  // Assert
  expect(items.first.title, '单词1');
  expect(items.first.description, '这是描述内容');
  expect(items.first.subtasks.length, 2);
  expect(items.first.tags, ['标签1', '标签2']);
});
```

### 11.17 完整流程集成测试

#### 11.7.1 测试文件
`test/integration/full_flow_integration_test.dart`

#### 11.7.2 测试场景

**场景 1：端到端用户流程**
```dart
test('完整流程：创建任务 → 添加子任务 → 复习 → 增加轮次 → 减少轮次', () async {
  // Step 1：创建学习内容
  final itemId = await CreateLearningItemUseCase(db).execute(
    CreateLearningItemParams(
      title: '英语单词',
      description: '学习英语',
      subtasks: ['单词1', '单词2', '单词3'],
      tags: ['英语'],
    ),
  );

  // Step 2：验证创建结果
  var item = await (select(db.learningItems)
        ..where((t) => t.id.equals(itemId)))
      .getSingle();
  expect(item.title, '英语单词');
  expect(item.description, '学习英语');

  var subtasks = await (select(db.learningSubtasks)
        ..where((t) => t.learningItemId.equals(itemId)))
      .get();
  expect(subtasks.length, 3);

  // Step 3：完成第 1 轮复习
  await CompleteReviewTaskUseCase(db).execute(
    CompleteReviewTaskParams(taskId: 1),
  );

  // Step 4：增加轮次
  await AddReviewRoundUseCase(db).execute(
    AddReviewRoundParams(learningItemId: itemId),
  );

  // Step 5：减少轮次
  var result = await ReduceReviewRoundUseCase(db).execute(
    ReduceReviewRoundParams(learningItemId: itemId),
  );
  expect(result.success, true);

  // Step 6：验证最终状态
  var tasks = await (select(db.reviewTasks)
        ..where((t) => t.learningItemId.equals(itemId)))
      .get();
  expect(tasks.length, 5); // 原始 5 轮 - 减少 1 轮 + 新增 1 轮
});
```

**场景 2：数据一致性验证**
```dart
test('完整流程：所有页面数据一致性', () async {
  // 创建测试数据
  final itemId = await _createComplexItem(db);

  // 验证各模块数据一致
  final item = await LearningItemRepositoryImpl(db).getById(itemId);
  final viewTasks = await ReviewTaskRepositoryImpl(db).getByLearningItemId(itemId);

  // 所有地方都应看到相同的 description 和 subtasks
  expect(item.description, viewTasks.first.description);
  expect(item.subtasks.length, viewTasks.first.subtasks.length);
});
```

### 11.18 测试辅助函数

```dart
// 辅助函数：创建学习内容
Future<int> _createLearningItem(AppDatabase db, String uuid, {bool isDeleted = false}) {
  return db.into(db.learningItems).insert(
    LearningItemsCompanion.insert(
      uuid: Value(uuid),
      title: 'Test Item',
      learningDate: DateTime.now(),
      isDeleted: Value(isDeleted),
    ),
  );
}

// 辅助函数：创建复习任务
Future<int> _createReviewTask(
  AppDatabase db,
  int itemId,
  int round,
  DateTime scheduledDate,
  String status, {
  DateTime? completedAt,
}) {
  return db.into(db.reviewTasks).insert(
    ReviewTasksCompanion.insert(
      uuid: Value('task-$itemId-$round'),
      learningItemId: itemId,
      reviewRound: round,
      scheduledDate: scheduledDate,
      status: Value(status),
      completedAt: Value(completedAt),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      isMockData: const Value(false),
    ),
  );
}

// 辅助函数：创建子任务
Future<int> _createSubtask(AppDatabase db, String content, [int? itemId, int sortOrder = 0]) {
  final targetItemId = itemId ?? 1;
  return db.into(db.learningSubtasks).insert(
    LearningSubtasksCompanion.insert(
      uuid: Value('subtask-${DateTime.now().millisecondsSinceEpoch}'),
      learningItemId: targetItemId,
      content: content,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    ),
  );
}
```

### 11.19 测试数据准备

**Mock 数据生成**（参考 lib/infrastructure/debug/mock_data_service.dart）：
- 需更新 MockDataService 支持生成 description 和 subtasks 字段
- 集成测试需使用真实数据结构

**测试数据清理**：
```dart
setUp(() async {
  db = createInMemoryDatabase();
});

tearDown(() async {
  await db.close();
});
```

### 11.20 测试覆盖率目标

| 模块 | 目标覆盖率 |
|------|-----------|
| 数据迁移 | 100% |
| 减少轮次 | 100% |
| 子任务 CRUD | 100% |
| 备份恢复兼容 | 90% |
| 导入解析器 | 100% |
| 完整流程 | 关键路径覆盖 |

---

## 12. 附录

### 12.1 相关文件

| 类别 | 关键文件 |
|------|----------|
| 数据库 | lib/data/database/tables/learning_items_table.dart |
| 数据库 | lib/data/database/tables/review_tasks_table.dart |
| Domain | lib/domain/entities/learning_item.dart |
| Domain | lib/domain/entities/review_task.dart |
| Domain | lib/domain/repositories/learning_item_repository.dart |
| Data | lib/data/database/daos/learning_item_dao.dart |
| Data | lib/data/database/daos/review_task_dao.dart |
| Data | lib/data/repositories/learning_item_repository_impl.dart |
| UseCase | lib/domain/usecases/export_data_usecase.dart |
| UseCase | lib/domain/usecases/update_learning_item_note_usecase.dart |
| 同步 | lib/infrastructure/sync/sync_service.dart |
| 同步 | lib/data/sync/sync_log_writer.dart |
| 工具类 | lib/core/utils/file_parser.dart |
| 展示 | lib/presentation/pages/home/home_page.dart |
| 展示 | lib/presentation/pages/tasks/task_hub_page.dart |
| 展示 | lib/presentation/pages/tasks/task_detail_sheet.dart |
| 展示 | lib/presentation/pages/input/input_page.dart |
| 展示 | lib/presentation/pages/input/import_preview_page.dart |

### 12.2 术语表

| 术语 | 定义 |
|------|------|
| 减少轮次 | 删除最新一轮复习任务记录 |
| 子任务 | 从原备注迁移而来的子任务项，支持拖拽排序 |
| 描述 | 任务的补充说明文字 |
| 导入模板 | 批量导入的文件格式示例 |
| 渐进式迁移 | 不物理删除旧字段，通过 UI 切换和新字段替代 |

### 12.3 修订历史

| 版本 | 日期 | 修订内容 |
|------|------|----------|
| v1.0 | 2026-03-01 | 初始版本 |
| v2.0 | 2026-03-01 | 升级为端到端数据契约变更文档，补齐同步/备份兼容、迁移策略、影响面分析、测试清单 |
| v2.1 | 2026-03-01 | 新增第 11 章"完整集成测试"，包含 7 个测试文件、20+ 测试场景，覆盖数据迁移、减少轮次、子任务 CRUD、备份恢复、导入模板、完整流程 |
| v2.2 | 2026-03-01 | 扩展为项目级完整集成测试，覆盖全部 11 个核心功能模块（学习内容、复习任务、日历、统计、主题、模板、同步、OCR 等），共 20+ 测试文件、100+ 测试场景 |
| v2.3 | 2026-03-01 | 修正 logDelete 签名、补充 review_records 级联影响、修正迁移幂等方案、修正 LearningItemEntity subtasks 字段方案、修正文档编号、统一测试示例代码与现有架构对齐 |
| v2.4 | 2026-03-01 | 补充数据库层结构迁移（schemaVersion 8→9、onUpgrade 步骤）、统一 Phase 定义（数据迁移+UI切换放入 Phase 1）、新增 Phase 2 验收章节、补充 pubspec.yaml 模板资源配置、明确测试代码为参考实现 |
| v2.5 | 2026-03-01 | 补充 onUpgrade 脏库兜底（hasTable 检测）、修正 DI 注册位置（providers.dart）、修正测试代码字段（operation）、补充 UseCase 正确组装示例、明确 pubspec.yaml 为追加非覆盖 |
| v2.6 | 2026-03-01 | 修正同步 operation 为 create/update/delete（旧 upsert）、删除不存在的设备映射示例、修正导出模板措辞（旧导出不兼容非旧导入） |
