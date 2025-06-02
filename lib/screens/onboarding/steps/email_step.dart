import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';

class EmailStep extends StatelessWidget {
  final TextEditingController emailController;
  final String? emailError;
  final bool isLoading;
  final VoidCallback onEmailChanged;
  final VoidCallback onGoogleSignIn;

  const EmailStep({
    super.key,
    required this.emailController,
    this.emailError,
    required this.isLoading,
    required this.onEmailChanged,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're on desktop
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 0 : 24.0,
          vertical: isDesktop ? 20.0 : 48.0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 450 : double.infinity,
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.email_rounded,
                      color: AppTheme.getPrimaryColor(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr.translate('email'),
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPrimaryColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 46),
                child: Text(
                  context.tr.translate('enter_email'),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
              ),
              SizedBox(height: isDesktop ? 30 : 24),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: context.tr.translate('email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: context.tr.translate('enter_email'),
                  errorText: emailError,
                  contentPadding:
                      isDesktop
                          ? const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          )
                          : null,
                  suffixIcon:
                      isLoading
                          ? Container(
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          )
                          : null,
                ),
                style: TextStyle(fontSize: isDesktop ? 16 : 14),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  onEmailChanged();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.tr.translate('please_enter_email');
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return context.tr.translate('please_enter_valid_email');
                  }
                  if (emailError != null) {
                    return emailError;
                  }
                  return null;
                },
              ),
              SizedBox(height: isDesktop ? 50 : 40),

              // Information box at the bottom
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isDesktop ? 24 : 20,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      isDesktop
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.secondaryColor,
                      size: isDesktop ? 28 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr.translate('why_sign_up'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 18 : 16,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr.translate('why_sign_up_description'),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: isDesktop ? 16 : 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Option to sign in with Google for desktop
              if (isDesktop) ...[
                SizedBox(height: 40),
                Center(
                  child: Text(
                    context.tr.translate('or_sign_in_with'),
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: onGoogleSignIn,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: Text(
                      context.tr.translate('continue_with_google'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(280, 56),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
