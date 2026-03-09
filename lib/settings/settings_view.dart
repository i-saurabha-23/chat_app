import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_routes.dart';
import '../auth/sign_in/sign_in_view.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/primary_button.dart';
import 'settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsViewModel>(
      create: (_) => SettingsViewModel(),
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  Future<void> _onSignOut(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    final bool isSuccess = await viewModel.signOut();

    if (!context.mounted) {
      return;
    }

    if (isSuccess) {
      Navigator.of(
        context,
      ).pushReplacement(noTransitionRoute(const SignInView()));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.errorMessage ?? 'Unable to sign out right now.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (BuildContext context, SettingsViewModel viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: Text(viewModel.screenTitle)),
          body: ListView(
            padding: AppPaddings.allMd,
            children: <Widget>[
              ...viewModel.settingsItems.map((Map<String, dynamic> item) {
                return Padding(
                  padding: AppMargins.bottomSm,
                  child: Card(
                    elevation: AppSizes.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: AppPaddings.horizontalMd,
                      leading: Icon(_toIconData(item['icon'] as String? ?? '')),
                      title: Text(item['title'] as String? ?? ''),
                      subtitle: Text(item['subtitle'] as String? ?? ''),
                    ),
                  ),
                );
              }),
              AppGaps.hLG,
              PrimaryButton(
                text: 'Sign Out',
                onPressed: () => _onSignOut(context, viewModel),
                isLoading: viewModel.isSigningOut,
                backgroundColor: AppColors.error,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _toIconData(String key) {
    switch (key) {
      case 'notifications':
        return Icons.notifications_outlined;
      case 'privacy':
        return Icons.lock_outline_rounded;
      case 'storage':
        return Icons.storage_rounded;
      default:
        return Icons.settings_outlined;
    }
  }
}
