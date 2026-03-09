import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_sizes.dart';
import '../widgets/chat_tile.dart';
import '../widgets/empty_state.dart';
import 'chats_view_model.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatsViewModel>(
      create: (_) => ChatsViewModel(),
      child: const _ChatsBody(),
    );
  }
}

class _ChatsBody extends StatelessWidget {
  const _ChatsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatsViewModel>(
      builder: (BuildContext context, ChatsViewModel viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: Text(viewModel.screenTitle)),
          body: viewModel.chatItems.isEmpty
              ? const EmptyState(
                  title: 'No chats yet',
                  subtitle: 'Your conversations will appear here.',
                  icon: Icons.chat_bubble_outline_rounded,
                )
              : ListView.builder(
                  padding: AppPaddings.verticalXs,
                  itemCount: viewModel.chatItems.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> chat =
                        viewModel.chatItems[index];
                    return ChatTile(
                      chatModel: chat,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Opening chat with ${chat['friendName'] as String}',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
