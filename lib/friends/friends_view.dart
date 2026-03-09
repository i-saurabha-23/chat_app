import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_sizes.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_card.dart';
import 'friends_view_model.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FriendsViewModel>(
      create: (_) => FriendsViewModel(),
      child: const _FriendsBody(),
    );
  }
}

class _FriendsBody extends StatelessWidget {
  const _FriendsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsViewModel>(
      builder: (BuildContext context, FriendsViewModel viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: Text(viewModel.screenTitle)),
          body: viewModel.users.isEmpty
              ? const EmptyState(
                  title: 'No users available',
                  subtitle: 'Users you can connect with will appear here.',
                  icon: Icons.group_outlined,
                )
              : ListView.builder(
                  padding: AppPaddings.allMd,
                  itemCount: viewModel.users.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> user = viewModel.users[index];
                    final String username = user['username'] as String? ?? '';
                    final String name =
                        user['name'] as String? ?? 'Unknown User';
                    final bool isFriend = viewModel.isFriend(username);

                    return Padding(
                      padding: AppMargins.bottomSm,
                      child: UserCard(
                        userModel: user,
                        isFriend: isFriend,
                        onAddFriend: () {
                          viewModel.addFriend(username);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Friend request sent to $name'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
