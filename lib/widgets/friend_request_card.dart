import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'primary_button.dart';
import 'user_avatar.dart';

class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.requestModel,
    required this.onAccept,
    required this.onReject,
  });

  final dynamic requestModel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final String name = _readString(const [
      'name',
      'fullName',
      'displayName',
      'userName',
      'username',
    ], fallback: 'Unknown User');
    final String imageUrl = _readString(const [
      'profilePic',
      'imageUrl',
      'avatarUrl',
      'photoUrl',
    ]);

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: AppPaddings.allMd,
        child: Column(
          children: [
            Row(
              children: [
                UserAvatar(imageUrl: imageUrl, radius: AppSizes.xl),
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
              ],
            ),
            AppGaps.hMD,
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Accept',
                    onPressed: onAccept,
                    height: 42,
                    backgroundColor: AppColors.primaryBlue,
                  ),
                ),
                AppGaps.wSM,
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
                    ),
                    child: const Text('Reject'),
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
    if (requestModel is Map) {
      final map = requestModel as Map;
      for (final key in keys) {
        final dynamic value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return fallback;
  }
}
