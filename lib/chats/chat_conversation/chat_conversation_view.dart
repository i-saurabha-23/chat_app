import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/firebase_constants.dart';
import '../../friends/user_public_profile/user_public_profile_view.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/message_input.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/message_encryption.dart';
import 'chat_conversation_view_model.dart';

class ChatConversationView extends StatelessWidget {
  const ChatConversationView({super.key, required this.friendData});

  final Map<String, dynamic> friendData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatConversationViewModel>(
      create: (_) =>
          ChatConversationViewModel(friendData: friendData)..initialize(),
      child: const _ChatConversationBody(),
    );
  }
}

class _ChatConversationBody extends StatefulWidget {
  const _ChatConversationBody();

  @override
  State<_ChatConversationBody> createState() => _ChatConversationBodyState();
}

class _ChatConversationBodyState extends State<_ChatConversationBody> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _openPublicProfile(Map<String, dynamic> userData) {
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

  void _handleSend(ChatConversationViewModel viewModel, String value) {
    viewModel.sendMessage(value).then((String? error) {
      if (!mounted || error == null || error.trim().isEmpty) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatConversationViewModel>(
      builder:
          (
            BuildContext context,
            ChatConversationViewModel viewModel,
            Widget? _,
          ) {
            if (viewModel.isInitializing) {
              return const Scaffold(
                body: LoadingWidget(message: 'Opening chat...'),
              );
            }

            if (viewModel.errorMessage != null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Chat')),
                body: ErrorView(
                  message: viewModel.errorMessage!,
                  onRetry: viewModel.initialize,
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                titleSpacing: AppSizes.xs,
                title: StreamBuilder<Map<String, dynamic>>(
                  stream: viewModel.friendProfileStream(),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Map<String, dynamic>> snapshot,
                      ) {
                        final Map<String, dynamic> profile =
                            snapshot.data ?? viewModel.friendData;
                        final String name =
                            ((profile[FirebaseFields.name] as String?) ?? '')
                                .trim()
                                .isEmpty
                            ? viewModel.friendName
                            : (profile[FirebaseFields.name] as String);
                        final bool isOnline =
                            (profile[FirebaseFields.isOnline] as bool?) ??
                            false;

                        return InkWell(
                          onTap: () => _openPublicProfile(profile),
                          borderRadius: AppRadius.sm,
                          child: Row(
                            children: <Widget>[
                              UserAvatar(
                                imageUrl:
                                    (profile[FirebaseFields.profilePic]
                                        as String?) ??
                                    '',
                                radius: AppSizes.lg,
                                isOnline: isOnline,
                              ),
                              AppGaps.wSM,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      viewModel.isFriendTyping
                                          ? 'typing...'
                                          : (isOnline ? 'online' : 'offline'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textOnPrimary
                                            .withValues(alpha: 0.85),
                                        fontSize: AppSizes.sm,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                ),
              ),
              body: Column(
                children: <Widget>[
                  Expanded(
                    child:
                        StreamBuilder<
                          List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        >(
                          stream: viewModel.messagesStream(),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<
                                  List<
                                    QueryDocumentSnapshot<Map<String, dynamic>>
                                  >
                                >
                                snapshot,
                              ) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData) {
                                  return const LoadingWidget(
                                    message: 'Loading messages...',
                                  );
                                }
                                if (snapshot.hasError) {
                                  return const ErrorView(
                                    message: 'Unable to load messages.',
                                  );
                                }

                                final List<
                                  QueryDocumentSnapshot<Map<String, dynamic>>
                                >
                                docs =
                                    snapshot.data ??
                                    <
                                      QueryDocumentSnapshot<
                                        Map<String, dynamic>
                                      >
                                    >[];

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  viewModel.handleVisibleMessages(docs);
                                });

                                if (docs.isEmpty) {
                                  return EmptyState(
                                    title: 'No messages yet',
                                    subtitle:
                                        'Start chatting with ${viewModel.friendName}.',
                                    icon: Icons.chat_bubble_outline_rounded,
                                  );
                                }

                                return ListView.builder(
                                  padding: AppPaddings.allMd,
                                  itemCount: docs.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final Map<String, dynamic> data =
                                            docs[index].data();
                                        final String senderId =
                                            (data[FirebaseFields.senderId]
                                                as String?) ??
                                            '';
                                        final bool isSender =
                                            senderId == viewModel.currentUserId;
                                        final String decryptedMessage =
                                            MessageEncryption.decryptText(
                                              cipherText:
                                                  (data[FirebaseFields.text]
                                                      as String?) ??
                                                  '',
                                              ivBase64:
                                                  (data[FirebaseFields.iv]
                                                      as String?) ??
                                                  '',
                                              fallbackToRawWhenInvalid: true,
                                            );
                                        return ChatBubble(
                                          message: decryptedMessage,
                                          isSender: isSender,
                                          status:
                                              (data[FirebaseFields.status]
                                                  as String?) ??
                                              '',
                                          timestamp: _toDateTime(
                                            data[FirebaseFields.timestamp],
                                          ),
                                        );
                                      },
                                );
                              },
                        ),
                  ),
                  if (viewModel.isFriendTyping)
                    Padding(
                      padding: AppPaddings.horizontalMd,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TypingIndicator(userName: viewModel.friendName),
                      ),
                    ),
                  MessageInput(
                    controller: _messageController,
                    onSend: (String value) => _handleSend(viewModel, value),
                    onTyping: viewModel.setTyping,
                  ),
                ],
              ),
            );
          },
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
