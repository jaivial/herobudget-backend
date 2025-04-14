import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/extensions.dart';
import '../../auth/signin_screen.dart';

class ResetSuccessStep extends StatelessWidget {
  final VoidCallback onSignIn;

  const ResetSuccessStep({Key? key, required this.onSignIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.primaryColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),

            // Success text
            Text(
              context.tr.translate('password_reset_successful'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.translate('password_reset_message'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Sign in button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('Sign In button pressed');

                  // Clear reset password data first via app state
                  try {
                    final appState = myAppKey.currentState;
                    if (appState != null) {
                      debugPrint(
                        'Clearing reset password data through app state',
                      );
                      appState.clearResetPasswordData();
                    }
                  } catch (e) {
                    debugPrint('Error clearing reset password data: $e');
                  }

                  // Use direct navigation to SignInScreen
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  } else {
                    // Fallback to using the callback
                    onSignIn();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr.translate('sign_in'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
