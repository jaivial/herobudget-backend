import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';
import '../../../widgets/language_selector_button.dart';
import 'password_step.dart';

class PasswordStepWrapper extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const PasswordStepWrapper({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<PasswordStepWrapper> createState() => _PasswordStepWrapperState();
}

class _PasswordStepWrapperState extends State<PasswordStepWrapper> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _verifiedEmail = true;
  final _passwordWrapperFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Crear un AppBar para la pantalla de contraseña
    final passwordScreenAppBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
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

    return Scaffold(
      appBar: passwordScreenAppBar,
      body: SafeArea(
        child: Form(
          key: _passwordWrapperFormKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PasswordStep(
                  passwordController: widget.passwordController,
                  confirmPasswordController: widget.confirmPasswordController,
                  obscurePassword: _obscurePassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  verifiedEmail: _verifiedEmail,
                  onToggleObscurePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onToggleObscureConfirmPassword: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  onVerifiedEmailChanged: (value) {
                    setState(() {
                      _verifiedEmail = value;
                    });
                  },
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
                        child: Text(context.tr.translate('back').toUpperCase()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate password step
                          if (widget.passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password must be at least 6 characters',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (widget.confirmPasswordController.text !=
                              widget.passwordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          widget.onNext();
                        },
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
                                : Text(
                                  context.tr.translate('next').toUpperCase(),
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
  }

  Widget _buildHeader() {
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
            context.tr.translate('create_password'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr.translate('create_password_desc'),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
