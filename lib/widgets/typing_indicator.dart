import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppMargins.bottomSm,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.lg,
      ),
      child: Text(
        '$userName is typing...',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
