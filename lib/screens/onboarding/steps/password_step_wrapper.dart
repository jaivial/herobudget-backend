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
    return SafeArea(
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Solo logo centrado, botones manejados por AppBar principal
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getPrimaryColor(context),
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
