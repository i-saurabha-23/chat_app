import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../auth_routes.dart';
import '../sign_in/sign_in_view.dart';
import 'sign_up_view_model.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignUpViewModel>(
      create: (_) => SignUpViewModel(),
      child: const _SignUpForm(),
    );
  }
}

class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onCreateAccount() async {
    final SignUpViewModel viewModel = context.read<SignUpViewModel>();
    final bool isCreated = await viewModel.createAccount(
      name: _nameController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted || !isCreated) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(noTransitionRoute(const SignInView()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignUpViewModel>(
      builder: (BuildContext context, SignUpViewModel viewModel, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Account')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppPaddings.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  AppGaps.hXS,
                  Text(
                    'Create your account with username and password.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppGaps.hXL,
                  AppTextField(
                    controller: _nameController,
                    hintText: 'Name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    textInputAction: TextInputAction.next,
                  ),
                  AppGaps.hMD,
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
                    textInputAction: TextInputAction.next,
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
                  AppGaps.hMD,
                  AppTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    obscureText: _hideConfirmPassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _hideConfirmPassword = !_hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                    text: 'Create Account',
                    onPressed: _onCreateAccount,
                    isLoading: viewModel.isLoading,
                  ),
                  AppGaps.hXL,
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: viewModel.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    noTransitionRoute(const SignInView()),
                                  );
                                },
                          child: Text(
                            'Sign In',
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
