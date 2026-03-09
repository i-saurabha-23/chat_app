import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../chats/chats_view.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../friends/friends_view.dart';
import '../profile/profile_view.dart';
import '../settings/settings_view.dart';
import 'bottom_nav_view_model.dart';

class BottomNavView extends StatelessWidget {
  const BottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BottomNavViewModel>(
      create: (_) => BottomNavViewModel()..initialize(),
      child: const _BottomNavBody(),
    );
  }
}

class _BottomNavBody extends StatelessWidget {
  const _BottomNavBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavViewModel>(
      builder: (BuildContext context, BottomNavViewModel viewModel, _) {
        final int pendingRequestCount = viewModel.pendingRequestCount;
        return Scaffold(
          body: IndexedStack(
            index: viewModel.selectedIndex,
            children: const <Widget>[
              ChatsView(),
              FriendsView(),
              ProfileView(),
              SettingsView(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: viewModel.selectedIndex,
            onDestinationSelected: viewModel.selectTab,
            height: AppSizes.giant + AppSizes.md,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.softBlue,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: const Icon(Icons.chat_bubble_rounded),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: _friendsIcon(
                  isSelected: false,
                  pendingRequestCount: pendingRequestCount,
                ),
                selectedIcon: _friendsIcon(
                  isSelected: true,
                  pendingRequestCount: pendingRequestCount,
                ),
                label: 'Friends',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _friendsIcon({
    required bool isSelected,
    required int pendingRequestCount,
  }) {
    final Widget icon = Icon(isSelected ? Icons.group : Icons.group_outlined);
    if (pendingRequestCount <= 0) {
      return icon;
    }

    return Badge(
      backgroundColor: AppColors.error,
      textColor: AppColors.textOnPrimary,
      label: Text(
        pendingRequestCount > 99 ? '99+' : pendingRequestCount.toString(),
      ),
      child: icon,
    );
  }
}
