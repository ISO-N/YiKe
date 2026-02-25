# 忆刻 (YiKe)

基于艾宾浩斯遗忘曲线的学习任务规划应用，让科学记忆触手可及。

## 产品简介

忆刻是一款帮助用户科学复习的学习工具。根据艾宾浩斯遗忘曲线——新学知识在 20 分钟后遗忘 42%、1 天后遗忘 66%、6 天后遗忘 75%——通过在遗忘临界点进行复习，可以显著提高长期记忆保持率。

**用户只需记录"今天学了什么"，软件自动生成科学的复习计划并按时提醒。**

## 核心功能

| 功能 | 说明 |
|------|------|
| F1 学习内容录入 | 输入标题 + 备注 + 标签，一次可录入多条 |
| F2 复习计划自动生成 | 根据遗忘曲线自动生成 5 轮复习节点 |
| F3 复习任务完成/跳过 | 勾选完成或跳过，逾期任务标红提示 |
| F4 通知提醒 | 每日定时推送复习提醒（默认 09:00） |
| F5 桌面小组件 | Android 桌面小组件展示今日任务 |

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.11+ |
| 状态管理 | Riverpod 2.5+ |
| 路由 | GoRouter 14+ |
| 数据库 | Drift (SQLite ORM) |
| 通知 | flutter_local_notifications + workmanager |
| 桌面组件 | home_widget |
| 加密存储 | flutter_secure_storage |

## 快速开始

### 环境要求

- Flutter SDK 3.11+
- Dart SDK 3.11+

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 默认运行（自动选择设备）
flutter run

# 指定设备运行
flutter run -d <设备ID>

# 热重载模式运行
flutter run -d <设备ID> --hot
```

### 设备管理

```bash
# 查看已连接设备
flutter devices

# 启动 Android 模拟器
flutter emulator --launch <模拟器名称>

# 查看可用模拟器
flutter emulators

# 列出所有已知的模拟器 ID
flutter emulators --list
```

### 真机调试

```bash
# Android 真机调试（需要开启开发者选项中的 USB 调试）
flutter run -d <手机设备ID>

# iOS 真机调试（需要 macOS + Xcode）
# 首先确保设备已连接并信任证书
flutter run -d <iOS设备ID>

# 运行 release 版本进行性能测试
flutter run --release
```

### 构建发布

```bash
# Android APK
flutter build apk --release

# Android App Bundle（推荐 Google Play 发布）
flutter build appbundle --release

# iOS（需要 macOS）
flutter build ios --release

# Web
flutter build web --release
```

### 代码检查与测试

```bash
# 代码静态分析
flutter analyze

# 运行所有测试
flutter test

# 运行指定测试文件
flutter test test/path/to/file_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 代码生成

修改 Drift 数据库表后，需要重新生成代码：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 项目架构

项目采用 Clean Architecture 分层架构：

```
lib/
├── core/              # 核心工具（常量、扩展、主题、工具函数）
├── data/              # 数据层（数据库、DAO、Repository 实现）
├── domain/           # 领域层（实体、Repository 接口、用例）
├── infrastructure/   # 基础设施（通知、路由、安全存储、小组件）
├── presentation/     # 展示层（页面、组件）
└── di/               # 依赖注入（Riverpod Provider）
```

### 依赖流向

```
UI → UseCase → Repository → DAO → Database
```

## 文档导航

| 文档 | 说明 |
|------|------|
| [UI/UX 设计稿](./docs/ui-ux/忆刻-UI-UX设计稿.md) | 界面设计规范 |
| [技术设计文档](./docs/tdd/忆刻-技术设计文档.md) | 架构与数据库设计 |

## 版本信息

- **当前版本**：v1.0.0
- **目标平台**：Android / iOS
- **许可证**：MIT

---

*忆刻，让记忆有迹可循。*
