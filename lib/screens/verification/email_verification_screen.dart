import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';
import '../../utils/toast_util.dart';
import '../../utils/deep_link_handler.dart';
import '../../utils/extensions.dart';
import 'email_otp_verification_screen.dart';

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
  }

  // Method to check if the email has been verified
  Future<void> _checkEmailVerificationStatus() async {
    try {
      // Show a loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.translate('email_verification_checking_status'),
            ),
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
          ToastUtil.showSuccessToast(
            context,
            context.tr.translate('email_verification_complete'),
          );

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
            context.tr.translate('email_verification_not_verified'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showErrorToast(
          context,
          '${context.tr.translate('email_verification_error_checking')}: $e',
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
    setState(() {
      _isResending = true;
    });

    try {
      final result = await VerificationService.resendVerificationEmail(
        widget.userId,
        widget.userInfo['email'] ?? '',
      );

      if (mounted) {
        if (result['success'] == true) {
          ToastUtil.showSuccessToast(
            context,
            context.tr.translate('email_verification_sent'),
          );

          // Navigate to OTP verification screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => EmailOTPVerificationScreen(
                    userId: widget.userId,
                    userInfo: widget.userInfo,
                  ),
            ),
          );
        } else {
          ToastUtil.showErrorToast(
            context,
            result['error'] ??
                context.tr.translate('email_verification_failed_to_send'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showErrorToast(
          context,
          '${context.tr.translate('email_verification_error_sending')}: $e',
        );
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

    // Navigate directly to OTP verification screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => EmailOTPVerificationScreen(
                  userId: widget.userId,
                  userInfo: widget.userInfo,
                ),
          ),
        );
      }
    });

    return WillPopScope(
      // Prevent going back by returning false
      onWillPop: () async => false,
      child: Scaffold(
        // Remove back button from app bar
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            context.tr.translate('email_verification_required'),
            style: TextStyle(
              color: AppTheme.getPrimaryColor(context),
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
                      color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      color: AppTheme.getPrimaryColor(context),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    context.tr.translate('verify_your_email'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPrimaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    '${context.tr.translate('email_verification_description')} ${widget.userInfo['email']}.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    context.tr.translate('email_verification_instruction'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Loading indicator
                  CircularProgressIndicator(
                    color: AppTheme.getPrimaryColor(context),
                  ),
                  const SizedBox(height: 40),

                  Text(
                    context.tr.translate('email_verification_redirecting'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
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
