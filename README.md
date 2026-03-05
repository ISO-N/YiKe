# 🧠 忆刻 (YiKe) - 你的第二大脑

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.5+-00D9FF?style=for-the-badge&logo=reactivex)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows-4CAF50?style=for-the-badge)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-FF9800?style=for-the-badge)](LICENSE)

<br>

> **"遗忘是记忆的终极BOSS，而忆刻是你的作弊器。"** 🎮
>
> 基于**艾宾浩斯遗忘曲线**的科学记忆方案，让你的知识过目不忘。

</div>

---

## 📱 等等，这是啥？

想象一下：**你刚学完的东西，20分钟后忘了一半，1天后忘了66%** 😱

这就是著名的**艾宾浩斯遗忘曲线**——大脑的"选择性失忆"技能。

但！是！我们可以用**科学的复习节奏**来干翻它：

```
默认复习间隔（学习日 D0）：
D1 / D2 / D4 / D7 / D15 / D30 / D60 / D90 / D120 / D180（最多 10 轮）
```

**忆刻** 就是帮你自动安排这个"复习节奏"的贴心小助手。

> 你只需要：**"今天学了什么？"**
>
> 剩下的复习计划，交给忆刻来搞定！ 📅✨

---

## ✨ 功能地图 - 版本的进化史

### 🎯 v1.0 MVP - 初出茅庐

| 功能 | 说明 | 状态 |
|:----:|------|:----:|
| F1 | 学习内容录入（标题 + 备注 + 标签） | ✅ |
| F2 | 复习计划自动生成（默认最多 10 轮，可配置） | ✅ |
| F3 | 复习任务完成/跳过 | ✅ |
| F4 | 通知提醒（每日定时推送） | ✅ |
| F5 | 桌面小组件（Android） | ✅ |

> 核心目标：**让你能记，且记得住。**

### 📅 v2.0 增强版 - 武装到牙齿

| 功能 | 说明 | 状态 |
|:----:|------|:----:|
| F6 | 日历视图 | ✅ |
| F7 | 学习统计 | ✅ |
| F8 | 数据导出 | ✅ |

> 进阶目标：**让你看得清数据，打得了包。**

### ⚡ v2.1 录入升级 - 输入黑科技

| 功能 | 说明 | 状态 |
|:----:|------|:----:|
| F1.1 | 批量导入 | ✅ |
| F1.2 | 快速模板 | ✅ |
| F1.3 | 语音输入 | ✅ |
| F1.4 | OCR 识别 | ✅ |
| F1.5 | 复习预览 | ✅ |
| F1.6 | 内容关联 | ✅ |

> 终极目标：**让你怎么方便怎么来。**

### 🌙 v2.2 主题升级 - 颜值即正义

| 功能 | 说明 | 状态 |
|:----:|------|:----:|
| F9.1 | 深色主题 | ✅ |
| F9.2 | 跟随系统主题 | ✅ |
| F9.3 | 主题设置入口 | ✅ |

> 用户：**我要深色模式！** → 产品：**给给给！** 🌚

### 🌐 v3.0 跨平台与同步 - 的全家桶

| 功能 | 说明 | 状态 |
|:----:|------|:----:|
| **F10** | 学习指南内嵌 | ✅ |
| F10.1 | 设置页添加帮助入口 | ✅ |
| F10.2 | 学习指南独立页面 | ✅ |
| F10.3 | Markdown 渲染支持 | ✅ |
| **F11** | Windows 桌面端 | ✅ |
| F11.1 | Windows 桌面端适配 | ✅ |
| F11.2 | 桌面端窗口管理 | ✅ |
| F11.3 | 桌面端导航适配 | ✅ |
| **F12** | 局域网数据同步 | ✅ |
| F12.1 | 局域网服务发现 | ✅ |
| F12.2 | 设备配对与认证 | ✅ |
| F12.3 | 数据双向同步 | ✅ |
| F12.4 | 同步状态管理 | ✅ |

> 野心目标：**手机、平板、Windows，一个都不能少！**
>
> 📡 同步协议：UDP 广播发现 + HTTP 传输（端口 19876/19877）

### 🚧 v3.1 规划中 - 未来可期

| 功能 | 说明 | 状态 |
|:----:|------|:----:|
| F13 | Debug 模拟数据生成 | 📋 |
| F14 | 体验优化（搜索、筛选、进度展示） | 📋 |

---

## 🛠 技术栈 - 肌肉展示

<div align="center">

| 部位 | 技术 |
|:----:|------|
| 🦴 骨架 | Flutter 3.11+ |
| 💪 肌肉 | Riverpod 2.5+ |
| 🧭 导航 | GoRouter 14+ |
| 🗄 仓库 | Drift (SQLite ORM) |
| 🔔 闹钟 | flutter_local_notifications + workmanager |
| 🖥 桌面 | home_widget + window_manager + tray_manager |
| 🔐 保险箱 | flutter_secure_storage + cryptography |
| 📖 文档 | flutter_markdown |
| 📡 同步 | UDP 广播 + HTTP (端口 19876/19877) |

</div>

---

## 🚀 搞起来！5分钟入门

### 环境要求

- Flutter SDK 3.11+
- Dart SDK 3.11+

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 默认运行（会挑一个可用的设备）
flutter run

# 指定设备（先看看有哪些设备）
flutter devices
flutter run -d <设备ID>
```

### 构建发布

```bash
# Android APK（最常用的分发格式）
flutter build apk --release

# Android App Bundle（Google Play 推荐）
flutter build appbundle --release

# iOS（macOS 限定，土豪专属）
flutter build ios --release

# Windows（桌面端玩家的选择）
flutter build windows --release
```

### 代码生成

> ⚠️ 警告：如果你改了数据库表结构，必须跑这个！

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🏗 项目架构 - 代码的骨骼

项目采用 **Clean Architecture** 分层架构，讲究一个**依赖单向流动**：

```
lib/
├── core/              # 核心工具（常量、扩展、主题、工具函数）
├── data/              # 数据层（数据库、DAO、Repository 实现）
├── domain/            # 领域层（实体、Repository 接口、用例）
├── infrastructure/   # 基础设施（通知、路由、安全存储、小组件）
├── presentation/      # 展示层（页面、组件）
└── di/               # 依赖注入（Riverpod Provider）
```

### 依赖流向（单向通行，禁止逆行）

```
UI (Presentation) → UseCase (Domain) → Repository (Domain) → DAO (Data) → Database
                          ↑
                    ProviderContainer (DI)
```

> 💡 通俗理解：
> - **Presentation** = 门面（接待客人）
> - **Domain** = 业务逻辑（大脑）
> - **Data** = 仓库（保管货物）
> - 各层各司其职，不要跨界搞事情！

---

## 📚 文档导航 - 找不到路看这里

| 文档 | 说明 |
|------|------|
| [文档索引](./docs/README.md) | 文档入口与阅读顺序（建议从这里开始） |
| [PRD（汇总版）](./docs/prd.md) | 产品需求与验收口径汇总 |
| [UI/UX（汇总版）](./docs/UI-UX.md) | 设计体系、交互规则与验收检查点 |
| [技术设计（汇总版）](./docs/技术设计.md) | 架构、数据模型与关键方案 |

---

## 📄 版本信息

- **功能版本**：v3.0（见 `docs/README.md`）
- **应用版本**：以 `pubspec.yaml` 的 `version:` 为准
- **目标平台**：Android / iOS / Windows
- **许可证**：MIT
- **状态**：🟢 活跃开发中

---

## 🤝 一起搞事情？

如果你想：
- 🐛 报 Bug → GitHub Issues
- 💡 提建议 → GitHub Issues
- 💻 贡献代码 → Pull Request 大欢迎！
- 📢 聊聊人生 → 随便都可

---

<div align="center">

**忆刻，让记忆有迹可循。** 🧠✨

_记住，遗忘不是你的错，但忘记对抗遗忘就是你的问题了。_

</div>
