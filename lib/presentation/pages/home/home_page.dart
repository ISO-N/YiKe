/// 文件用途：首页（今日复习任务），展示今日/逾期任务并支持完成、跳过等操作。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/glass_card.dart';

class HomePage extends StatelessWidget {
  /// 首页（今日复习）。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.todayReview,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'MVP v1 正在开发中：此处将展示今日/逾期复习任务列表与进度。',
                ),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/input'),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.input),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

