import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/firebase_constants.dart';
import '../constants/app_sizes.dart';
import '../widgets/chat_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_widget.dart';
import 'chat_conversation/chat_conversation_view.dart';
import 'chats_view_model.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatsViewModel>(
      create: (_) => ChatsViewModel()..initialize(),
      child: const _ChatsBody(),
    );
  }
}

class _ChatsBody extends StatelessWidget {
  const _ChatsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatsViewModel>(
      builder: (BuildContext context, ChatsViewModel viewModel, Widget? _) {
        if (viewModel.isInitializing) {
          return Scaffold(
            appBar: AppBar(title: Text(viewModel.screenTitle)),
            body: const LoadingWidget(message: 'Loading chats...'),
          );
        }

        if (viewModel.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: Text(viewModel.screenTitle)),
            body: ErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.initialize,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(viewModel.screenTitle)),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: viewModel.friendsStream(),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const LoadingWidget(
                      message: 'Loading your friends...',
                    );
                  }
                  if (snapshot.hasError) {
                    return const ErrorView(
                      message: 'Unable to load chats right now.',
                    );
                  }

                  final List<Map<String, dynamic>> friends =
                      snapshot.data ?? <Map<String, dynamic>>[];

                  if (friends.isEmpty) {
                    return const EmptyState(
                      title: 'No friends yet',
                      subtitle: 'Accept a friend request to start chatting.',
                      icon: Icons.group_outlined,
                    );
                  }

                  return ListView.builder(
                    padding: AppPaddings.verticalXs,
                    itemCount: friends.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> friend = friends[index];
                      final String friendId =
                          (friend[FirebaseFields.userId] as String?) ?? '';

                      return StreamBuilder<Map<String, dynamic>>(
                        stream: viewModel.friendProfileStream(friendId),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<Map<String, dynamic>>
                              profileSnapshot,
                            ) {
                              final Map<String, dynamic> liveFriendProfile =
                                  profileSnapshot.data ?? friend;

                              return StreamBuilder<Map<String, dynamic>>(
                                stream: viewModel.chatTileStream(
                                  friend: liveFriendProfile,
                                ),
                                builder:
                                    (
                                      BuildContext context,
                                      AsyncSnapshot<Map<String, dynamic>>
                                      tileSnapshot,
                                    ) {
                                      final Map<String, dynamic> tileData =
                                          tileSnapshot.data ??
                                          _fallbackTile(liveFriendProfile);
                                      return ChatTile(
                                        chatModel: tileData,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => ChatConversationView(
                                                friendData: <String, dynamic>{
                                                  ...liveFriendProfile,
                                                  ...tileData,
                                                  FirebaseFields.userId:
                                                      (liveFriendProfile[FirebaseFields
                                                              .userId]
                                                          as String?) ??
                                                      '',
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                              );
                            },
                      );
                    },
                  );
                },
          ),
        );
      },
    );
  }

  Map<String, dynamic> _fallbackTile(Map<String, dynamic> friend) {
    final String friendName =
        ((friend[FirebaseFields.name] as String?) ?? '').trim().isNotEmpty
        ? (friend[FirebaseFields.name] as String)
        : ((friend[FirebaseFields.username] as String?) ?? 'Friend');

    return <String, dynamic>{
      ...friend,
      'friendName': friendName,
      'lastMessage': 'Start chatting with $friendName',
      'lastMessageTime': null,
      'unreadCount': 0,
    };
  }
}
