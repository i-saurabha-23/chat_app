import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../bottom_nav/bottom_nav_view.dart';
import '../../constants/firebase_constants.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_widget.dart';
import '../auth_routes.dart';
import '../auth_session_manager.dart';
import '../sign_in/sign_in_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const Duration _sessionLookupTimeout = Duration(seconds: 4);
  static const Duration _userLookupTimeout = Duration(seconds: 8);

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? userId = await AuthSessionManager.getUserId().timeout(
        _sessionLookupTimeout,
        onTimeout: () => null,
      );

      if (userId == null || userId.isEmpty) {
        _navigateTo(const SignInView());
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>>? userSnapshot = await _fetchUser(
        userId,
      );

      if (userSnapshot != null && userSnapshot.exists) {
        _navigateTo(const BottomNavView());
        return;
      }

      await AuthSessionManager.clearSession();
      _navigateTo(const SignInView());
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message ?? 'Unable to verify session.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to verify session.';
        _isLoading = false;
      });
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _fetchUser(
    String userId,
  ) async {
    try {
      return await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get()
          .timeout(_userLookupTimeout);
    } on TimeoutException {
      return null;
    }
  }

  void _navigateTo(Widget page) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(noTransitionRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget(message: 'Checking account...')
          : ErrorView(
              message: _errorMessage ?? 'Something went wrong.',
              onRetry: _checkAuthStatus,
            ),
    );
  }
}
