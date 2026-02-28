// 文件用途：ResponsiveUtils 响应式断点与列数计算的单元测试（Widget 测试）。
// 作者：Codex
// 创建日期：2026-02-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yike/core/utils/responsive_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 构建一个最小 Widget，并在 build 阶段读取响应式工具类的结果。
  Future<({bool isMobile, bool isTablet, bool isDesktop, int columns})>
  measure(WidgetTester tester, double width) async {
    var isMobile = false;
    var isTablet = false;
    var isDesktop = false;
    var columns = 0;

    await tester.pumpWidget(
      MediaQuery(
        // 说明：直接注入 MediaQueryData，避免受测试绑定层 surfaceSize/devicePixelRatio 影响而出现断点不稳定。
        data: MediaQueryData(size: Size(width, 800)),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = ResponsiveUtils.isMobile(context);
              isTablet = ResponsiveUtils.isTablet(context);
              isDesktop = ResponsiveUtils.isDesktop(context);
              columns = ResponsiveUtils.getColumnCount(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    return (
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      columns: columns,
    );
  }

  testWidgets('断点判断：mobile/tablet/desktop', (tester) async {
    final mobile = await measure(tester, 500);
    expect(mobile.isMobile, isTrue);
    expect(mobile.isTablet, isFalse);
    expect(mobile.isDesktop, isFalse);
    expect(mobile.columns, 1);

    final tablet = await measure(tester, 700);
    expect(tablet.isMobile, isFalse);
    expect(tablet.isTablet, isTrue);
    expect(tablet.isDesktop, isFalse);
    expect(tablet.columns, 1);

    final desktop = await measure(tester, 1300);
    expect(desktop.isMobile, isFalse);
    expect(desktop.isTablet, isFalse);
    expect(desktop.isDesktop, isTrue);
    expect(desktop.columns, 2);
  });
}
