# 文件用途：统一的本地测试入口（带超时/并发限制，并可选执行覆盖率校验）。
# 作者：Codex
# 创建日期：2026-02-26
#
# 用法：
# - 仅运行测试：powershell -ExecutionPolicy Bypass -File tool/run_tests.ps1
# - 运行覆盖率并校验非 UI ≥ 90%：powershell -ExecutionPolicy Bypass -File tool/run_tests.ps1 -Coverage

param(
  [switch]$Coverage
)

$ErrorActionPreference = 'Stop'

Write-Host "Running tests (timeout=30s, concurrency=1)..."
flutter test --timeout 30s --concurrency=1

if ($Coverage) {
  Write-Host "Generating coverage (lcov) and checking non-UI threshold..."
  flutter test --coverage --timeout 30s --concurrency=1
  dart run tool/coverage/check_non_ui_coverage.dart
}
