import 'package:flutter/material.dart';

import '../../auth/auth_routes.dart';
import '../../auth/auth_session_manager.dart';
import '../../auth/sign_in/sign_in_view.dart';
import '../../auth/sign_in/sign_in_view_model.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/empty_state.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  String _name = '';
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final String? name = await AuthSessionManager.getName();
    if (!mounted) {
      return;
    }
    setState(() {
      _name = name ?? '';
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    await SignInViewModel().signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(noTransitionRoute(const SignInView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
        actions: [
          if (_isSigningOut)
            const Padding(
              padding: AppPaddings.horizontalSm,
              child: SizedBox(
                height: AppSizes.iconMd,
                width: AppSizes.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.xxs,
                  color: AppColors.textOnPrimary,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: EmptyState(
        title: _name.isEmpty ? 'No chats yet' : 'Hi $_name',
        subtitle: _name.isEmpty
            ? 'Your chat list will appear here.'
            : 'Your chat list will appear here.',
        icon: Icons.chat_bubble_outline_rounded,
      ),
    );
  }
}
