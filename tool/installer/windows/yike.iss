; ============================================================================
; 文件用途：YiKe（忆刻）Windows 端 Inno Setup 打包脚本
; 作者：Codex（OpenAI）
; 创建日期：2026-03-01
; 编码：UTF-8（无 BOM）
;
; 使用方式：
; 1) 先构建 Release：flutter build windows --release
; 2) 用 Inno Setup 编译本脚本（ISCC.exe），生成安装包
; ============================================================================

; ----------------------------
; 可按需修改的参数（集中在这里）
; ----------------------------
#define ProjectRoot "..\\..\\.."
#define BuildDir ProjectRoot + "\\build\\windows\\x64\\runner\\Release"
#define AppExeName "yike.exe"

; 应用显示名可用中文，但建议安装目录用纯英文，避免路径兼容性问题。
#define AppName "忆刻（YiKe）"
#define AppInstallDirName "YiKe"

; TODO: 如需对外发布，请替换为真实的发布者与主页信息。
#define AppPublisher "YiKe"
#define AppURL "https://example.com"

#define AppIconFile ProjectRoot + "\\windows\\runner\\resources\\app_icon.ico"
#define OutputDir ProjectRoot + "\\build\\installer\\windows"

; AppVersion 直接从 Release 产物的文件版本读取，保证与 flutter build 输出一致。
#define AppVersion GetStringFileInfo(BuildDir + "\\" + AppExeName, "ProductVersion")

; ----------------------------
; 编译期校验：避免“没先 build 就打包”的常见问题
; ----------------------------
#if !FileExists(BuildDir + "\\" + AppExeName)
  #error "未找到 Windows Release 产物：" + BuildDir + "\\" + AppExeName + "。请先执行：flutter build windows --release"
#endif

[Setup]
; AppId 必须保持稳定（同一应用版本升级依赖此值），请勿随意更换。
AppId={{B5799FDF-8697-4725-ADE1-96D25124D7AD}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}

DefaultDirName={autopf}\{#AppInstallDirName}
DefaultGroupName={#AppName}
AllowNoIcons=yes

OutputDir={#OutputDir}
OutputBaseFilename=YiKe-Setup-{#AppVersion}-x64
SetupIconFile={#AppIconFile}
UninstallDisplayIcon={app}\{#AppExeName}

Compression=lzma2
SolidCompression=yes
WizardStyle=modern

; 兼容 x64 系统（避免使用已弃用的 x64 标识符）。
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; 以普通用户权限安装（写入 Program Files 仍可能触发 UAC；如需强制管理员请改为 admin）。
PrivilegesRequired=lowest

; TODO: 如需代码签名，可配置 SignTool/SignToolParameters。

[Languages]
; 默认提供英文；若 Inno Setup 安装目录中存在中文语言文件，则自动追加中文选项。
Name: "english"; MessagesFile: "compiler:Default.isl"
#if FileExists(CompilerPath + "Languages\\ChineseSimplified.isl")
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\\ChineseSimplified.isl"
#endif

[Tasks]
; 可选桌面图标任务。
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 复制 Flutter Windows Release 目录内全部文件（包含 data\flutter_assets、依赖 dll 等）。
Source: "{#BuildDir}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\\{#AppName}"; Filename: "{app}\\{#AppExeName}"
Name: "{userdesktop}\\{#AppName}"; Filename: "{app}\\{#AppExeName}"; Tasks: desktopicon

[Run]
; 安装完成后可勾选启动应用。
Filename: "{app}\\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
