/// 文件用途：录入页（学习内容录入），支持一次录入多条内容并自动生成复习计划。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/glass_card.dart';

class InputPage extends StatelessWidget {
  /// 录入页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const InputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('录入')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          children: const [
            GlassCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('MVP v1 正在开发中：此处将提供标题/备注/标签录入与批量添加。'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

