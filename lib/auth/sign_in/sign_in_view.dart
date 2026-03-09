import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../chat/chat_list/chat_list_view.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../auth_routes.dart';
import '../sign_up/sign_up_view.dart';
import 'sign_in_view_model.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignInViewModel>(
      create: (_) => SignInViewModel(),
      child: const _SignInForm(),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    final SignInViewModel viewModel = context.read<SignInViewModel>();
    final user = await viewModel.signIn(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted || user == null) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(noTransitionRoute(const ChatListView()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignInViewModel>(
      builder: (BuildContext context, SignInViewModel viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Sign In')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppPaddings.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  AppGaps.hXS,
                  Text(
                    'Sign in with your username and password.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppGaps.hXL,
                  AppTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    textInputAction: TextInputAction.next,
                  ),
                  AppGaps.hMD,
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                      icon: Icon(
                        _hidePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  if (viewModel.errorMessage != null) ...[
                    AppGaps.hMD,
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: AppSizes.sm,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  AppGaps.hXL,
                  PrimaryButton(
                    text: 'Sign In',
                    onPressed: _onSignIn,
                    isLoading: viewModel.isLoading,
                  ),
                  AppGaps.hXL,
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: viewModel.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    noTransitionRoute(const SignUpView()),
                                  );
                                },
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
