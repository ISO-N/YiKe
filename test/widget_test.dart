// 文件用途：基础 Widget 冒烟测试，确保 App 能成功渲染并进入首页路由。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yike/app.dart';

void main() {
  testWidgets('App 可以渲染并显示首页标题', (WidgetTester tester) async {
    // 构建 App 并触发首帧渲染。
    await tester.pumpWidget(
      const ProviderScope(child: YiKeApp()),
    );

    // 由于 GoRouter 的异步导航，补一帧以等待路由进入初始页。
    await tester.pumpAndSettle();

    expect(find.text('今日复习'), findsOneWidget);
  });
}
