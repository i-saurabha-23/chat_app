import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.radius = 22,
    this.isOnline = false,
  });

  final String? imageUrl;
  final double radius;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.softBlue,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Icon(
              Icons.person,
              color: AppColors.primaryBlue,
              size: radius,
            ),
    );

    if (!isOnline) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: AppSizes.sm,
            height: AppSizes.sm,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.canvasWhite, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
