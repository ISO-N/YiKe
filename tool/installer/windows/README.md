# Windows 安装包（Inno Setup）

> 文件用途：说明如何用 Inno Setup 为 YiKe（忆刻）Windows 端生成安装包  
> 作者：Codex（OpenAI）  
> 创建日期：2026-03-01  
> 编码：UTF-8（无 BOM）

## 前置条件

- 已安装 Flutter（能执行 `flutter`）
- 已安装 Inno Setup 6，并能执行 `ISCC`（建议把 Inno 安装目录加入 PATH）

## 生成安装包

1) 构建 Windows Release：

```powershell
flutter build windows --release
```

2) 编译 Inno 脚本生成安装包：

```powershell
ISCC tool\\installer\\windows\\yike.iss
```

生成的安装包默认输出到 `build\\installer\\windows\\`（该目录在 `.gitignore` 的 `build/` 下）。

## 一键脚本（推荐）

仓库已提供 `tool\\build_windows_installer.dart`，会自动执行构建并调用 `ISCC`：

```powershell
dart run tool\\build_windows_installer.dart
```
