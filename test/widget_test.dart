// 文件用途：基础 Widget 冒烟测试，确保 App 能成功渲染并进入首页路由。
// 作者：Codex
// 创建日期：2026-02-25

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:yike/app.dart';
import 'package:yike/data/database/database.dart';
import 'package:yike/di/providers.dart';

void main() {
  testWidgets('App 可以渲染并显示首页标题', (WidgetTester tester) async {
    // 测试环境下使用内存数据库，避免依赖真实文件系统路径。
    final db = AppDatabase(NativeDatabase.memory());

    // 构建 App 并触发首帧渲染。
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const YiKeApp(),
      ),
    );

    // 由于 GoRouter 的异步导航，补一帧以等待路由进入初始页。
    await tester.pumpAndSettle();

    // “今日复习”在首页标题与底部导航中都会出现，因此断言至少出现一次即可。
    expect(find.text('今日复习'), findsAtLeastNWidgets(1));

    await db.close();
  });
}
