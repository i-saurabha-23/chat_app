import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/firebase_constants.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/friend_request_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_card.dart';
import 'user_public_profile/user_public_profile_view.dart';
import 'friends_view_model.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FriendsViewModel>(
      create: (_) => FriendsViewModel()..initialize(),
      child: const _FriendsBody(),
    );
  }
}

class _FriendsBody extends StatefulWidget {
  const _FriendsBody();

  @override
  State<_FriendsBody> createState() => _FriendsBodyState();
}

class _FriendsBodyState extends State<_FriendsBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPublicUserProfile(Map<String, dynamic> userData) {
    final String userId = ((userData[FirebaseFields.userId] as String?) ?? '')
        .trim();
    if (userId.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            UserPublicProfileView(userId: userId, initialData: userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsViewModel>(
      builder: (BuildContext context, FriendsViewModel viewModel, _) {
        if (viewModel.isInitializing) {
          return Scaffold(
            appBar: AppBar(title: Text(viewModel.screenTitle)),
            body: const LoadingWidget(message: 'Loading friends...'),
          );
        }

        if (viewModel.errorMessage != null &&
            viewModel.searchResults.isEmpty &&
            viewModel.searchQuery.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(viewModel.screenTitle)),
            body: ErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.initialize,
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(viewModel.screenTitle),
              bottom: TabBar(
                labelColor: AppColors.textOnPrimary,
                unselectedLabelColor: AppColors.textOnPrimary.withValues(
                  alpha: 0.8,
                ),
                indicatorColor: AppColors.textOnPrimary,
                tabs: <Tab>[
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('Received'),
                        if (viewModel.receivedRequestCount > 0) ...<Widget>[
                          AppGaps.wXXS,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.xs,
                              vertical: AppSizes.xxxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textOnPrimary,
                              borderRadius: AppRadius.xl,
                            ),
                            child: Text(
                              viewModel.receivedRequestCount > 99
                                  ? '99+'
                                  : viewModel.receivedRequestCount.toString(),
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: AppSizes.xs,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(text: 'Sent'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                _ReceivedRequestsTab(
                  viewModel: viewModel,
                  onOpenUserProfile: _openPublicUserProfile,
                ),
                _SentRequestsTab(
                  viewModel: viewModel,
                  searchController: _searchController,
                  onOpenUserProfile: _openPublicUserProfile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReceivedRequestsTab extends StatelessWidget {
  const _ReceivedRequestsTab({
    required this.viewModel,
    required this.onOpenUserProfile,
  });

  final FriendsViewModel viewModel;
  final ValueChanged<Map<String, dynamic>> onOpenUserProfile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: viewModel.receivedRequestsStream(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingWidget(message: 'Loading requests...');
            }
            if (snapshot.hasError) {
              return const ErrorView(
                message: 'Unable to load received requests.',
              );
            }

            final List<Map<String, dynamic>> requests =
                snapshot.data ?? <Map<String, dynamic>>[];
            if (requests.isEmpty) {
              return const EmptyState(
                title: 'No received requests',
                subtitle: 'Incoming friend requests will appear here.',
                icon: Icons.inbox_outlined,
              );
            }

            return ListView.builder(
              padding: AppPaddings.allMd,
              itemCount: requests.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> request = requests[index];
                final String requestId =
                    (request['requestId'] as String?) ?? '';
                final String senderId = (request['senderId'] as String?) ?? '';
                return Padding(
                  padding: AppMargins.bottomSm,
                  child: FriendRequestCard(
                    requestModel: request,
                    onTap: () => onOpenUserProfile(request),
                    onAccept: () async {
                      final String? error = await viewModel.acceptFriendRequest(
                        requestId: requestId,
                        senderId: senderId,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Friend request accepted.'),
                        ),
                      );
                    },
                    onReject: () async {
                      final String? error = await viewModel.rejectFriendRequest(
                        requestId: requestId,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error ?? 'Friend request rejected.'),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
    );
  }
}

class _SentRequestsTab extends StatelessWidget {
  const _SentRequestsTab({
    required this.viewModel,
    required this.searchController,
    required this.onOpenUserProfile,
  });

  final FriendsViewModel viewModel;
  final TextEditingController searchController;
  final ValueChanged<Map<String, dynamic>> onOpenUserProfile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppPaddings.allMd,
      children: <Widget>[
        AppTextField(
          controller: searchController,
          hintText: 'Search users by name or username',
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: viewModel.searchUsers,
        ),
        AppGaps.hMD,
        _buildSearchResultBlock(context),
        AppGaps.hLG,
        Text('Sent Requests', style: Theme.of(context).textTheme.titleMedium),
        AppGaps.hSM,
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: viewModel.sentRequestsStream(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LoadingWidget(
                    message: 'Loading sent requests...',
                  );
                }
                if (snapshot.hasError) {
                  return const ErrorView(
                    message: 'Unable to load sent requests.',
                  );
                }

                final List<Map<String, dynamic>> requests =
                    snapshot.data ?? <Map<String, dynamic>>[];
                if (requests.isEmpty) {
                  return const EmptyState(
                    title: 'No sent requests',
                    subtitle: 'Requests you send will appear here.',
                    icon: Icons.send_outlined,
                  );
                }

                return Column(
                  children: requests.map((Map<String, dynamic> request) {
                    final String name =
                        (request['name'] as String?) ?? 'Unknown User';
                    final String username =
                        (request['username'] as String?) ?? '';
                    final String imageUrl =
                        (request['profilePic'] as String?) ?? '';
                    final bool isOnline =
                        (request['isOnline'] as bool?) ?? false;

                    return Padding(
                      padding: AppMargins.bottomSm,
                      child: Card(
                        elevation: AppSizes.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.md,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          onTap: () => onOpenUserProfile(request),
                          contentPadding: AppPaddings.allMd,
                          leading: UserAvatar(
                            imageUrl: imageUrl,
                            isOnline: isOnline,
                            radius: AppSizes.lg,
                          ),
                          title: Text(name),
                          subtitle: Text('@$username'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: AppSizes.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: AppRadius.sm,
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
        ),
      ],
    );
  }

  Widget _buildSearchResultBlock(BuildContext context) {
    if (viewModel.searchQuery.isEmpty) {
      return const EmptyState(
        title: 'Search users',
        subtitle: 'Find users by username or name.',
        icon: Icons.person_search_rounded,
      );
    }

    if (viewModel.isSearching) {
      return const LoadingWidget(message: 'Searching users...');
    }

    if (viewModel.errorMessage != null) {
      return ErrorView(
        message: viewModel.errorMessage!,
        onRetry: () => viewModel.searchUsers(viewModel.searchQuery),
      );
    }

    if (viewModel.searchResults.isEmpty) {
      return const EmptyState(
        title: 'No users found',
        subtitle: 'Try a different username or name.',
        icon: Icons.search_off_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Search Results', style: Theme.of(context).textTheme.titleMedium),
        AppGaps.hSM,
        ...viewModel.searchResults.map((Map<String, dynamic> user) {
          final String userId = (user['userId'] as String?) ?? '';
          final String status = viewModel.connectionStatusFor(userId);
          final String actionText = _actionTextForStatus(status);
          final bool isFriend = status == 'friend';
          final bool canSendRequest = status == 'none';

          return Padding(
            padding: AppMargins.bottomSm,
            child: UserCard(
              userModel: user,
              isFriend: isFriend,
              actionText: actionText,
              isActionEnabled: canSendRequest,
              isActionLoading: viewModel.isSendingRequest(userId),
              onTap: () => onOpenUserProfile(user),
              onAddFriend: () async {
                final String? error = await viewModel.sendFriendRequest(user);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Friend request sent.')),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  String _actionTextForStatus(String status) {
    if (status == 'friend') {
      return 'Friend';
    }
    if (status == 'sent') {
      return 'Requested';
    }
    if (status == 'received') {
      return 'Check Received';
    }
    return 'Add Friend';
  }
}
