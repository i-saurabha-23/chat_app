import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.timestamp,
    this.status,
  });

  final String message;
  final bool isSender;
  final DateTime? timestamp;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final Color bubbleColor = isSender
        ? AppColors.primaryBlue
        : AppColors.surface;
    final Color textColor = isSender
        ? AppColors.textOnPrimary
        : AppColors.textPrimary;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSizes.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSizes.radiusLg),
              topRight: const Radius.circular(AppSizes.radiusLg),
              bottomLeft: Radius.circular(
                isSender ? AppSizes.radiusLg : AppSizes.xs,
              ),
              bottomRight: Radius.circular(
                isSender ? AppSizes.xs : AppSizes.radiusLg,
              ),
            ),
            border: isSender ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: textColor, fontSize: 14)),
              AppGaps.hXS,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: isSender
                          ? AppColors.softBlue
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (isSender) ...[AppGaps.wXS, _statusIcon()],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon() {
    final String value = (status ?? '').toLowerCase().trim();
    IconData icon = Icons.schedule;
    Color iconColor = AppColors.softBlue;

    if (value == 'sent') {
      icon = Icons.done;
    } else if (value == 'delivered') {
      icon = Icons.done_all;
    } else if (value == 'read') {
      icon = Icons.done_all;
      iconColor = Colors.lightBlueAccent;
    }

    return Icon(icon, size: 14, color: iconColor);
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }
    final int rawHour = value.hour;
    final int hour = rawHour % 12 == 0 ? 12 : rawHour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = rawHour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
