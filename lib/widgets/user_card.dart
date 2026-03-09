import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'primary_button.dart';
import 'user_avatar.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.userModel,
    this.onAddFriend,
    this.isFriend = false,
    this.onTap,
  });

  final dynamic userModel;
  final VoidCallback? onAddFriend;
  final bool isFriend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String name = _readString(
      const ['name', 'fullName', 'displayName', 'userName', 'username'],
      fallback: 'Unknown User',
    );
    final String imageUrl = _readString(
      const ['profilePic', 'imageUrl', 'avatarUrl', 'photoUrl'],
    );
    final bool isOnline = _readBool(
      const ['isOnline', 'online'],
      fallback: false,
    );

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Padding(
          padding: AppPaddings.allMd,
          child: Row(
            children: [
              UserAvatar(
                imageUrl: imageUrl,
                radius: AppSizes.xl,
                isOnline: isOnline,
              ),
              AppGaps.wMD,
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              AppGaps.wSM,
              if (isFriend)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: AppRadius.sm,
                  ),
                  child: const Text(
                    'Friend',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 132,
                  child: PrimaryButton(
                    text: 'Add Friend',
                    onPressed: onAddFriend,
                    height: 40,
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _readString(List<String> keys, {String fallback = ''}) {
    if (userModel is Map) {
      final map = userModel as Map;
      for (final key in keys) {
        final dynamic value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return fallback;
  }

  bool _readBool(List<String> keys, {required bool fallback}) {
    if (userModel is Map) {
      final map = userModel as Map;
      for (final key in keys) {
        final dynamic value = map[key];
        if (value is bool) {
          return value;
        }
      }
    }
    return fallback;
  }
}
