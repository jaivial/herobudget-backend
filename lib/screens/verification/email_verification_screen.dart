import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';
import '../../utils/toast_util.dart';
import '../../utils/deep_link_handler.dart';
import 'email_verification_success_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userInfo;

  const EmailVerificationScreen({
    super.key,
    required this.userId,
    required this.userInfo,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isResending = false;

  // Override to keep this screen's state alive when not visible
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Check for verification code in shared preferences or app state
    _checkForVerificationCode();
  }

  // Method to check if a verification code exists and redirect if needed
  Future<void> _checkForVerificationCode() async {
    try {
      // Check the global verification code handler
      if (verificationCodeHandler.hasVerificationCode() &&
          verificationCodeHandler.isFromDeepLink) {
        print(
          "EmailVerificationScreen: Found verification code in global handler",
        );
        final code = verificationCodeHandler.currentVerificationCode;

        // Navigate to success screen with the code
        if (code != null && mounted) {
          _navigateToSuccessScreen(code);
        }
      }

      // This will be executed in the next frame to ensure
      // the context is fully ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check again in case the code was set after initialization
        if (verificationCodeHandler.hasVerificationCode() &&
            verificationCodeHandler.isFromDeepLink &&
            mounted) {
          final code = verificationCodeHandler.currentVerificationCode;
          if (code != null) {
            _navigateToSuccessScreen(code);
          }
        }

        // Listen for verification code changes from deep links
        _setupDeepLinkListener();
      });
    } catch (e) {
      print("Error in _checkForVerificationCode: $e");
    }
  }

  // Listen for deep links containing verification codes
  void _setupDeepLinkListener() {
    // No need to unsubscribe as the screen will be disposed
    // but just checking for active context
    if (mounted) {
      print("Setting up deep link listener in EmailVerificationScreen");
    }
  }

  // Navigate to success screen if verification code is received
  void _navigateToSuccessScreen(String verificationCode) {
    if (mounted) {
      print(
        "Navigating to verification success screen from verification screen",
      );

      // Mark this code as from deep link before navigating
      verificationCodeHandler.setCodeFromDeepLink(verificationCode);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: "verification_success"),
          builder:
              (context) => EmailVerificationSuccessScreen(
                verificationCode: verificationCode,
              ),
        ),
      );
    }
  }

  // Method to check if the email has been verified
  Future<void> _checkEmailVerificationStatus() async {
    try {
      // Show a loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking verification status...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Call API to check user data
      final result = await VerificationService.checkVerificationStatus(
        widget.userId,
      );

      if (mounted) {
        if (result == true) {
          // Email has been verified, proceed to dashboard
          ToastUtil.showSuccessToast(context, 'Your email has been verified!');

          // Navigate to dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => DashboardScreen(
                    userId: widget.userId,
                    userInfo: widget.userInfo,
                  ),
            ),
            (route) => false,
          );
        } else {
          // Email not verified yet
          ToastUtil.showInfoToast(
            context,
            'Your email is not verified yet. Please check your inbox.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showErrorToast(
          context,
          'Error checking verification status: $e',
        );
      }
    }
  }

  // Function to open email app
  Future<void> _openEmailApp() async {
    final String email = widget.userInfo['email'] ?? '';
    final Uri emailUri = Uri.parse('mailto:$email');

    try {
      // Using launchUrl directly with fallback
      if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch email app with URI: $emailUri');
        // Fallback to simple mailto
        final Uri fallbackUri = Uri.parse('mailto:');
        if (!await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        )) {
          debugPrint('Could not launch email app with fallback URI');
        }
      }
    } catch (e) {
      debugPrint('Error launching email app: $e');
    }
  }

  // Function to handle sign out
  Future<void> _handleSignOut() async {
    await AuthService.signOut(context);

    if (context.mounted) {
      // Navigate back to onboarding and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  // Function to resend verification email
  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await VerificationService.resendVerificationEmail(
        widget.userId,
        widget.userInfo['email'],
      );

      if (context.mounted) {
        if (result['success']) {
          ToastUtil.showSuccessToast(
            context,
            'Verification email resent. Please check your inbox.',
          );
        } else {
          ToastUtil.showErrorToast(
            context,
            result['error'] ?? 'Failed to resend email.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtil.showErrorToast(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required when using AutomaticKeepAliveClientMixin

    // CRITICAL: Check if verification code exists and came from a deep link
    final codeFromHandler = verificationCodeHandler.currentVerificationCode;
    if (codeFromHandler != null &&
        codeFromHandler.isNotEmpty &&
        verificationCodeHandler.isFromDeepLink) {
      // Found verification code from deep link - return success screen directly
      print(
        "EmailVerificationScreen: Found deep link code on build: $codeFromHandler",
      );
      return EmailVerificationSuccessScreen(verificationCode: codeFromHandler);
    }

    // Check if there's a verification code in app state or arguments
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null &&
        modalRoute.settings.arguments != null &&
        modalRoute.settings.name == "verification_success") {
      final args = modalRoute.settings.arguments;
      if (args is Map && args.containsKey('verification_code')) {
        // Verification code in route arguments must have come from deep link
        final code = args['verification_code'];
        print("EmailVerificationScreen: Found verification route: $code");
        verificationCodeHandler.setCodeFromDeepLink(code);
        return EmailVerificationSuccessScreen(verificationCode: code);
      }
    }

    return WillPopScope(
      // Prevent going back by returning false
      onWillPop: () async => false,
      child: Scaffold(
        // Remove back button from app bar
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Email Verification Required',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Email icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'We\'ve sent an email with a verification link to ${widget.userInfo['email']}.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Please verify your account to start using Hero Budget.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Resend verification email
                  TextButton(
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    child:
                        _isResending
                            ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.secondaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Sending...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                            : const Text(
                              'Resend Verification Email',
                              style: TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),

                  const SizedBox(height: 60),

                  // Sign Out Button
                  OutlinedButton(
                    onPressed: _handleSignOut,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
