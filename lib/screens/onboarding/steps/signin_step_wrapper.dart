import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';
import '../../../widgets/language_selector_button.dart';
import 'signin_step.dart';

class SignInStepWrapper extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? passwordError;
  final bool isLoading;
  final VoidCallback onForgotPassword;
  final VoidCallback onEmailChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignIn;
  final VoidCallback onBack;

  const SignInStepWrapper({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.emailError,
    this.passwordError,
    required this.isLoading,
    required this.onForgotPassword,
    required this.onEmailChanged,
    required this.onGoogleSignIn,
    required this.onSignIn,
    required this.onBack,
  });

  @override
  State<SignInStepWrapper> createState() => _SignInStepWrapperState();
}

class _SignInStepWrapperState extends State<SignInStepWrapper> {
  bool _obscurePassword = true;
  final _signInWrapperFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _signInWrapperFormKey,
          child: Column(
            children: [
              // Header is now built inside this widget
              _buildHeader(),
              Expanded(
                child: SignInStep(
                  emailController: widget.emailController,
                  passwordController: widget.passwordController,
                  obscurePassword: _obscurePassword,
                  emailError: widget.emailError,
                  passwordError: widget.passwordError,
                  isLoading: widget.isLoading,
                  onToggleObscurePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onForgotPassword: widget.onForgotPassword,
                  onEmailChanged: widget.onEmailChanged,
                  onGoogleSignIn: widget.onGoogleSignIn,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.isLoading ? null : widget.onBack,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('BACK'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.isLoading ? null : widget.onSignIn,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            widget.isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('SIGN IN'),
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              // Centered logo
              Center(
                child: Image.asset(
                  'assets/images/herobudgeticon.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              // Absolute positioned language selector at the right
              Positioned(
                right: 0,
                top: 0,
                child: const LanguageSelectorButton(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Sign In to Your Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your credentials to access your account',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
