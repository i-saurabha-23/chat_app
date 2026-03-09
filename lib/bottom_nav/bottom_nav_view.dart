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
      create: (_) => BottomNavViewModel(),
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
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Friends',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
