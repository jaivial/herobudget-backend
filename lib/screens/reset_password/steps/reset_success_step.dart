import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../../theme/app_theme.dart';

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
            const Text(
              'Password Reset Successful',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your password has been successfully updated. You can now sign in with your new password.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
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

                  // Don't use any local navigation - only use the app state
                  // which provides a global context-free navigation
                  try {
                    final appState = myAppKey.currentState;
                    if (appState != null) {
                      debugPrint('Calling navigateToSignIn on app state');
                      // Clear reset password data and navigate in one step
                      appState.navigateToSignIn();
                      return; // Return early to avoid calling onSignIn
                    }
                  } catch (e) {
                    debugPrint('Error using app state for navigation: $e');
                  }

                  // Only if the app state method failed, try the onSignIn callback
                  debugPrint('Falling back to onSignIn callback');
                  onSignIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
