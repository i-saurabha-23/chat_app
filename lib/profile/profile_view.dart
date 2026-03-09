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
                      const UserAvatar(radius: AppSizes.max, isOnline: true),
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
