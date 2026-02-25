/// 文件用途：设置页（通知开关、提醒时间、免打扰时段等）。
/// 作者：Codex
/// 创建日期：2026-02-25
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../widgets/glass_card.dart';

class SettingsPage extends StatelessWidget {
  /// 设置页。
  ///
  /// 返回值：页面 Widget。
  /// 异常：无。
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          children: const [
            Text(
              '设置',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSpacing.lg),
            GlassCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('MVP v1 正在开发中：此处将提供通知、免打扰等设置。'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

