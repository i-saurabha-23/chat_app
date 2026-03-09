import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/user_avatar.dart';
import 'user_public_profile_view_model.dart';

class UserPublicProfileView extends StatelessWidget {
  const UserPublicProfileView({
    super.key,
    required this.userId,
    this.initialData,
  });

  final String userId;
  final Map<String, dynamic>? initialData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserPublicProfileViewModel>(
      create: (_) =>
          UserPublicProfileViewModel(userId: userId, initialData: initialData)
            ..loadUser(),
      child: const _UserPublicProfileBody(),
    );
  }
}

class _UserPublicProfileBody extends StatelessWidget {
  const _UserPublicProfileBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPublicProfileViewModel>(
      builder:
          (
            BuildContext context,
            UserPublicProfileViewModel viewModel,
            Widget? _,
          ) {
            return Scaffold(
              appBar: AppBar(title: const Text('User Profile')),
              body: _buildBody(context, viewModel),
            );
          },
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserPublicProfileViewModel viewModel,
  ) {
    if (viewModel.isLoading && viewModel.errorMessage == null) {
      return const LoadingWidget(message: 'Loading user profile...');
    }

    if (viewModel.errorMessage != null && viewModel.name == 'Unknown User') {
      return ErrorView(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadUser,
      );
    }

    return SingleChildScrollView(
      padding: AppPaddings.screen,
      child: Column(
        children: <Widget>[
          UserAvatar(
            imageUrl: viewModel.profilePic,
            radius: AppSizes.max,
            isOnline: viewModel.isOnline,
          ),
          AppGaps.hMD,
          Text(
            viewModel.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          AppGaps.hXS,
          Text(
            '@${viewModel.username}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          AppGaps.hXL,
          Card(
            elevation: AppSizes.zero,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.md,
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: AppPaddings.allMd,
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: AppPaddings.zero,
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Name'),
                    subtitle: Text(viewModel.name),
                  ),
                  ListTile(
                    contentPadding: AppPaddings.zero,
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('User ID'),
                    subtitle: Text(viewModel.publicUserId),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
