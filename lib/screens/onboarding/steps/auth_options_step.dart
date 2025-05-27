import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';
import '../../../widgets/language_selector_button.dart';

class AuthOptionsStep extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;
  final VoidCallback onGoogleSignIn;

  const AuthOptionsStep({
    super.key,
    required this.onSignUp,
    required this.onSignIn,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine if we're on desktop
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // Wrap the content in a Builder to ensure we have the proper context with Localizations
    return Builder(
      builder: (context) {
        // Add a safety check to ensure tr is available
        try {
          // Check if localizations are available
          final _ = context.tr;

          return Stack(
            children: [
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 0.0 : 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skip logo on desktop since it's already on the left panel
                      if (!isDesktop) ...[
                        Image.asset(
                          'assets/images/herobudgeticon.png',
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 25),
                      ],

                      // Welcome Text
                      Text(
                        context.tr.translate('welcome'),
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 0 : 16.0,
                        ),
                        child: Text(
                          context.tr.translate('welcome_desc'),
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: isDesktop ? 50 : 40),

                      // Sign Up Button
                      SizedBox(
                        width: isDesktop ? 320 : double.infinity,
                        child: ElevatedButton(
                          onPressed: onSignUp,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.fromHeight(isDesktop ? 60 : 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.tr.translate('sign_up'),
                            style: TextStyle(
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sign In Button
                      SizedBox(
                        width: isDesktop ? 320 : double.infinity,
                        child: OutlinedButton(
                          onPressed: onSignIn,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(isDesktop ? 60 : 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            context.tr.translate('sign_in'),
                            style: TextStyle(
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider with "or" text
                      SizedBox(
                        width: isDesktop ? 320 : double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.5,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                context.tr.translate('or_sign_in_with'),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Google Sign In Button
                      SizedBox(
                        width: isDesktop ? 320 : double.infinity,
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
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.fromHeight(isDesktop ? 60 : 56),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Hide language selector on desktop since it's already in the left panel
              if (!isDesktop)
                Positioned(
                  right: 24,
                  top: 15,
                  child: const LanguageSelectorButton(),
                ),
            ],
          );
        } catch (e) {
          // Fallback if localizations are not yet available
          print('Localizations not yet available in AuthOptionsStep: $e');
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
