import 'dart:convert';
import 'dart:typed_data';

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
    final ImageProvider<Object>? imageProvider = _resolveImageProvider(
      imageUrl,
    );
    final bool hasImage = imageProvider != null;

    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.softBlue,
      backgroundImage: imageProvider,
      child: hasImage
          ? null
          : Icon(Icons.person, color: AppColors.primaryBlue, size: radius),
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

  ImageProvider<Object>? _resolveImageProvider(String? value) {
    if (value == null) {
      return null;
    }

    final String imageValue = value.trim();
    if (imageValue.isEmpty) {
      return null;
    }

    if (imageValue.startsWith('http://') || imageValue.startsWith('https://')) {
      return NetworkImage(imageValue);
    }

    try {
      String base64String = imageValue;
      if (imageValue.startsWith('data:image')) {
        final int index = imageValue.indexOf(',');
        if (index != -1) {
          base64String = imageValue.substring(index + 1);
        }
      }
      final Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}
