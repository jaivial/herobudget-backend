import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/signin_service.dart';
import '../../services/app_service.dart';
import '../../utils/toast_util.dart';
import '../../utils/extensions.dart';
import '../../widgets/language_selector_button.dart';
import '../dashboard/dashboard_screen.dart';
import '../reset_password/reset_password_screen.dart';
import '../verification/email_verification_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleObscurePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _handleEmailChanged() {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _handleForgotPassword() {
    // Save the email if available for potential use on the reset password screen
    String email = '';
    if (_emailController.text.isNotEmpty &&
        _emailController.text.contains('@')) {
      email = _emailController.text;
    }

    // Navigate to reset password screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(initialEmail: email),
      ),
    );
  }

  // Method to safely navigate back
  void _handleBackNavigation() {
    // Navigate to the OnboardingScreen instead of just popping
    // This ensures we always have a valid screen to go back to
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (route) => false, // Remove all existing routes
    );
  }

  Future<void> _handleSignIn() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    try {
      // Attempt to sign in
      final result = await SignInService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        if (result['success']) {
          // Successful login
          final userData = result['user_data'];

          // Check if email is verified
          final bool isEmailVerified = userData['verified_email'] ?? false;

          // Navigate based on verification status
          if (!isEmailVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EmailVerificationScreen(
                      userId: userData['id'].toString(),
                      userInfo: userData,
                    ),
              ),
            );
          } else {
            // Navigate to Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DashboardScreen(
                      userId: userData['id'].toString(),
                      userInfo: userData,
                    ),
              ),
            );
          }
        } else {
          // Handle errors
          setState(() {
            _isLoading = false;
            if (result['error_type'] == 'invalid_credentials') {
              _passwordError = context.tr.translate('invalid_credentials');
            } else if (result['error_type'] == 'email_not_found') {
              _emailError = context.tr.translate('email_not_found');
            } else {
              // Generic error
              ToastUtil.showErrorToast(
                context,
                result['message'] ?? context.tr.translate('signin_failed'),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastUtil.showErrorToast(
          context,
          'An error occurred. Please try again.',
        );
      }
    }
  }

  void _handleGoogleSignIn() {
    // Implement Google sign-in
    ToastUtil.showErrorToast(
      context,
      context.tr.translate('google_signin_not_implemented'),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Crear un AppBar personalizado con el botón selector de idioma
    final appBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60, // Altura mayor para el AppBar
      actions: [
        Container(
          margin: const EdgeInsets.only(top: 8.0, right: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: LanguageSelectorButton(),
        ),
      ],
    );

    return WillPopScope(
      // Handle back button press
      onWillPop: () async {
        _handleBackNavigation();
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: appBar,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email input section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.getPrimaryColor(
                                    context,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.getPrimaryColor(context),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                context.tr.translate('email'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => _handleEmailChanged(),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return context.tr.translate('enter_email');
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: context.tr.translate('enter_email'),
                              prefixIcon: const Icon(Icons.email_outlined),
                              errorText: _emailError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Password input section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.getPrimaryColor(
                                    context,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.getPrimaryColor(context),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                context.tr.translate('password'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr.translate('enter_password');
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: context.tr.translate('enter_password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: _toggleObscurePassword,
                              ),
                              errorText: _passwordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: Text(
                                context.tr.translate('forgot_password'),
                                style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(context.tr.translate('sign_in')),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Back button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _handleBackNavigation,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(context.tr.translate('back')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/herobudgeticon.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr.translate('login'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr.translate('enter_credentials'),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
