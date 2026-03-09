import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/loading_widget.dart';
import '../widgets/user_avatar.dart';
import 'profile_view_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (_) => ProfileViewModel()..loadProfile(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  Future<void> _selectProfilePictureSource(
    BuildContext context,
    ProfileViewModel viewModel,
  ) async {
    final String? source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.xl)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: AppPaddings.allMd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.of(context).pop('gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Use Camera'),
                  onTap: () => Navigator.of(context).pop('camera'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || source == null) {
      return;
    }

    if (source == 'gallery') {
      final bool canProceed = await _confirmPermissionDialog(
        context,
        title: 'Gallery Permission Required',
        message:
            'To select your profile picture, allow access to your gallery/photos.',
      );
      if (!canProceed || !context.mounted) {
        return;
      }
      final String? error = await viewModel.updateProfilePictureFromGallery();
      if (!context.mounted) {
        return;
      }
      if (error != null && error.trim().isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    if (source == 'camera') {
      final bool canProceed = await _confirmPermissionDialog(
        context,
        title: 'Camera Permission Required',
        message: 'To capture your profile picture, allow camera access.',
      );
      if (!canProceed || !context.mounted) {
        return;
      }
      final String? error = await viewModel.updateProfilePictureFromCamera();
      if (!context.mounted) {
        return;
      }
      if (error != null && error.trim().isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<bool> _confirmPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (BuildContext context, ProfileViewModel viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: Text(viewModel.screenTitle)),
          body: viewModel.isLoading
              ? const LoadingWidget(message: 'Loading profile...')
              : SingleChildScrollView(
                  padding: AppPaddings.screen,
                  child: Column(
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          InkWell(
                            onTap: viewModel.isUploadingProfilePic
                                ? null
                                : () => _selectProfilePictureSource(
                                    context,
                                    viewModel,
                                  ),
                            borderRadius: AppRadius.xl,
                            child: UserAvatar(
                              imageUrl: viewModel.profilePic,
                              radius: AppSizes.max,
                              isOnline: viewModel.isOnline,
                            ),
                          ),
                          Positioned(
                            right: AppSizes.zero,
                            bottom: AppSizes.zero,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.canvasWhite,
                                  width: AppSizes.xxs,
                                ),
                              ),
                              padding: AppPaddings.allXs,
                              child: viewModel.isUploadingProfilePic
                                  ? const SizedBox(
                                      width: AppSizes.iconSm,
                                      height: AppSizes.iconSm,
                                      child: CircularProgressIndicator(
                                        strokeWidth: AppSizes.xxs,
                                        color: AppColors.textOnPrimary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      size: AppSizes.iconSm,
                                      color: AppColors.textOnPrimary,
                                    ),
                            ),
                          ),
                        ],
                      ),
                      AppGaps.hMD,
                      Text(
                        viewModel.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppGaps.hXXS,
                      Text(
                        '@${viewModel.username}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (viewModel.errorMessage != null &&
                          viewModel.errorMessage!
                              .trim()
                              .isNotEmpty) ...<Widget>[
                        AppGaps.hSM,
                        Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: AppSizes.sm,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      AppGaps.hXL,
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        elevation: AppSizes.zero,
                        child: Padding(
                          padding: AppPaddings.allMd,
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                contentPadding: AppPaddings.zero,
                                leading: const Icon(Icons.badge_outlined),
                                title: const Text('User ID'),
                                subtitle: Text(viewModel.userId),
                              ),
                              ListTile(
                                contentPadding: AppPaddings.zero,
                                leading: const Icon(
                                  Icons.alternate_email_rounded,
                                ),
                                title: const Text('Username'),
                                subtitle: Text(viewModel.username),
                              ),
                              ListTile(
                                contentPadding: AppPaddings.zero,
                                leading: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                title: const Text('Name'),
                                subtitle: Text(viewModel.name),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
