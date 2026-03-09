import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'user_avatar.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({super.key, required this.chatModel, this.onTap});

  final dynamic chatModel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String friendName = _readString(const [
      'friendName',
      'name',
      'fullName',
      'displayName',
    ], fallback: 'Unknown User');
    final String lastMessage = _readString(const [
      'lastMessage',
      'message',
      'text',
    ], fallback: 'No messages yet');
    final String imageUrl = _readString(const [
      'avatarUrl',
      'profilePic',
      'imageUrl',
      'photoUrl',
    ]);
    final DateTime? time = _readDateTime(const [
      'lastMessageTime',
      'timestamp',
      'time',
    ]);
    final int unreadCount = _readInt(const [
      'unreadCount',
      'unread',
      'count',
    ], fallback: 0);
    final bool isOnline = _readBool(const [
      'isOnline',
      'online',
    ], fallback: false);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            UserAvatar(
              imageUrl: imageUrl,
              radius: AppSizes.xl,
              isOnline: isOnline,
            ),
            AppGaps.wMD,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  AppGaps.hXXS,
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AppGaps.wSM,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                AppGaps.hXS,
                if (unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: AppSizes.lg),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: AppSizes.xxxs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppSizes.max),
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _readString(List<String> keys, {String fallback = ''}) {
    if (chatModel is Map) {
      final map = chatModel as Map;
      for (final key in keys) {
        final dynamic value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return fallback;
  }

  int _readInt(List<String> keys, {required int fallback}) {
    if (chatModel is Map) {
      final map = chatModel as Map;
      for (final key in keys) {
        final dynamic value = map[key];
        if (value is int) {
          return value;
        }
        if (value is String) {
          return int.tryParse(value) ?? fallback;
        }
      }
    }
    return fallback;
  }

  bool _readBool(List<String> keys, {required bool fallback}) {
    if (chatModel is Map) {
      final map = chatModel as Map;
      for (final key in keys) {
        final dynamic value = map[key];
        if (value is bool) {
          return value;
        }
      }
    }
    return fallback;
  }

  DateTime? _readDateTime(List<String> keys) {
    if (chatModel is! Map) {
      return null;
    }

    final map = chatModel as Map;
    for (final key in keys) {
      final dynamic value = map[key];
      if (value is DateTime) {
        return value;
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value);
      }
    }
    return null;
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '';
    }

    final now = DateTime.now();
    final isToday =
        now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;

    if (isToday) {
      final int rawHour = value.hour;
      final int hour = rawHour % 12 == 0 ? 12 : rawHour % 12;
      final String minute = value.minute.toString().padLeft(2, '0');
      final String period = rawHour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    return '${value.day}/${value.month}/${value.year}';
  }
}
