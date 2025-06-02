import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../../theme/app_theme.dart';
import '../../services/verification_service.dart';
import '../../utils/toast_util.dart';
import '../../utils/extensions.dart';
import '../dashboard/dashboard_screen.dart';
import 'email_verification_success_screen.dart';

class EmailOTPVerificationScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userInfo;

  const EmailOTPVerificationScreen({
    super.key,
    required this.userId,
    required this.userInfo,
  });

  @override
  State<EmailOTPVerificationScreen> createState() =>
      _EmailOTPVerificationScreenState();
}

class _EmailOTPVerificationScreenState
    extends State<EmailOTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String _errorMessage = '';
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Set up focus listeners for OTP fields
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _otpControllers[i].text.isNotEmpty) {
          _otpControllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpControllers[i].text.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  // Get the complete OTP code from all text fields
  String _getCompleteOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  // Verify the email with the entered OTP code
  Future<void> _verifyEmail() async {
    final otp = _getCompleteOtp();

    // Validate OTP
    if (otp.length != 6) {
      setState(() {
        _errorMessage = context.tr.translate('email_otp_enter_all_digits');
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      // Call verification service
      final result = await VerificationService.verifyEmail(otp);

      if (result['success']) {
        // Get user details from the result
        final userData = result['user'];

        if (userData == null) {
          setState(() {
            _isVerifying = false;
            _errorMessage = context.tr.translate('email_otp_invalid_user_data');
          });
          return;
        }

        // Save verified user data to local storage
        final prefs = await SharedPreferences.getInstance();

        // Safely extract user ID, defaulting to '0' if not available
        final userId =
            userData['user_id']?.toString() ??
            userData['id']?.toString() ??
            '0';

        await prefs.setString('user_id', userId);
        await prefs.setString('user_data', jsonEncode(userData));

        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) =>
                      EmailVerificationSuccessScreen(verificationCode: otp),
            ),
          );
        }
      } else {
        // Show error message
        setState(() {
          _isVerifying = false;
          _errorMessage =
              result['error'] ??
              context.tr.translate('email_otp_failed_to_verify');
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = context.tr.translate('email_otp_network_error');
      });
    }
  }

  // Resend verification code
  Future<void> _resendVerificationCode() async {
    if (_isResending || _resendCountdown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      final result = await VerificationService.resendVerificationEmail(
        widget.userId,
        widget.userInfo['email'],
      );

      if (result['success']) {
        ToastUtil.showSuccessToast(
          context,
          context.tr.translate('email_otp_resend_sent'),
        );

        // Start countdown for resend button
        setState(() {
          _resendCountdown = 60; // 60 seconds cooldown
        });

        _startResendTimer();
      } else {
        setState(() {
          _errorMessage =
              result['error'] ??
              context.tr.translate('email_otp_resend_failed');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.tr.translate('email_otp_network_error');
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  // Start timer for resend cooldown
  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr.translate('verify_your_email'),
          style: TextStyle(
            color: AppTheme.getPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  context.tr.translate('email_verification'),
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
                  '${context.tr.translate('email_otp_description')} ${widget.userInfo['email']}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  context.tr.translate('email_otp_enter_6_digits'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 45,
                      height: 55,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(
                                context,
                              ).withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          // Auto-verify when all fields are filled
                          if (index == 5 && value.isNotEmpty) {
                            if (_getCompleteOtp().length == 6) {
                              _verifyEmail();
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppTheme.getPrimaryColor(
                        context,
                      ).withOpacity(0.5),
                    ),
                    child:
                        _isVerifying
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              context.tr.translate('email_otp_verify_button'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend code button
                TextButton(
                  onPressed:
                      (_resendCountdown > 0 || _isResending)
                          ? null
                          : _resendVerificationCode,
                  child: Text(
                    _resendCountdown > 0
                        ? '${context.tr.translate('email_otp_resend_countdown')} $_resendCountdown ${context.tr.translate('email_otp_seconds')}'
                        : _isResending
                        ? context.tr.translate('email_otp_sending')
                        : context.tr.translate('email_otp_resend_code'),
                    style: TextStyle(
                      color:
                          (_resendCountdown > 0 || _isResending)
                              ? Colors.grey
                              : AppTheme.getPrimaryColor(context),
                      fontWeight: FontWeight.bold,
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
}
