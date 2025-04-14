import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

import '../../theme/app_theme.dart';
import '../../services/verification_service.dart';
import '../dashboard/dashboard_screen.dart';

class EmailVerificationSuccessScreen extends StatefulWidget {
  final String verificationCode;

  const EmailVerificationSuccessScreen({
    super.key,
    required this.verificationCode,
  });

  @override
  State<EmailVerificationSuccessScreen> createState() =>
      _EmailVerificationSuccessScreenState();
}

class _EmailVerificationSuccessScreenState
    extends State<EmailVerificationSuccessScreen> {
  late ConfettiController _confettiController;
  bool _isVerifying = true;
  bool _verificationSuccess = false;
  String _userId = '';
  Map<String, dynamic> _userInfo = {};
  String _errorMessage = '';
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Print to confirm this screen is receiving the verification code
    print(
      "EmailVerificationSuccessScreen initialized with code: ${widget.verificationCode}",
    );

    // Ensure the verification process starts immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyEmail();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    try {
      print('Attempting to verify email with code: ${widget.verificationCode}');

      // Verify the email with the backend
      final result = await VerificationService.verifyEmail(
        widget.verificationCode,
      );

      if (result['success']) {
        // Get user details from the result
        final userData = result['user'];

        if (userData == null) {
          setState(() {
            _isVerifying = false;
            _verificationSuccess = false;
            _errorMessage = 'Invalid user data received from server';
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

        // Update state
        setState(() {
          _isVerifying = false;
          _verificationSuccess = true;
          _userId = userId;
          _userInfo = userData;
        });

        // Play confetti animation
        _confettiController.play();
      } else {
        // Retry a few times in case of temporary issues
        if (_retryCount < _maxRetries) {
          print(
            'Verification failed, retrying (${_retryCount + 1}/${_maxRetries})',
          );
          _retryCount++;
          await Future.delayed(const Duration(seconds: 2));
          await _verifyEmail();
          return;
        }

        // Show specific error based on response
        String errorMessage = result['error'] ?? 'Failed to verify email';

        // Handle common error cases
        if (errorMessage.contains('Invalid verification code')) {
          errorMessage =
              'This verification code appears to be invalid or expired. Please request a new verification email.';
        } else if (errorMessage.contains('404')) {
          errorMessage =
              'Verification link not found. The code may be expired or incorrect.';
        }

        setState(() {
          _isVerifying = false;
          _verificationSuccess = false;
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      print('Error in _verifyEmail: $e');

      // Retry a few times in case of temporary issues
      if (_retryCount < _maxRetries) {
        print(
          'Verification error, retrying (${_retryCount + 1}/${_maxRetries})',
        );
        _retryCount++;
        await Future.delayed(const Duration(seconds: 2));
        await _verifyEmail();
        return;
      }

      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _errorMessage =
            'Network or server error. Please check your connection and try again later.';
      });
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (context) => DashboardScreen(userId: _userId, userInfo: _userInfo),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back navigation from this screen
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Confetti widget
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.purple,
                  Colors.pink,
                  Colors.blue,
                  Colors.amber,
                ],
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isVerifying)
                      _buildVerifyingUI()
                    else if (_verificationSuccess)
                      _buildSuccessUI()
                    else
                      _buildErrorUI(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyingUI() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppTheme.primaryColor),
        const SizedBox(height: 30),
        const Text(
          'Verifying your email...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          'Please wait while we confirm your email address.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessUI() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 80,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Email Verified!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Congratulations! Your email ${_userInfo['email'] ?? ''} has been successfully verified.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _navigateToDashboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'START USING HERO BUDGET',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 80,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Verification Failed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          _errorMessage,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Verification code: ${widget.verificationCode}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () async {
            try {
              // Attempt to resend the verification email
              setState(() {
                _isVerifying = true;
                _retryCount = 0;
              });

              // Get a reference to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('user_id');
              final userDataStr = prefs.getString('user_data');

              if (userId != null && userDataStr != null) {
                try {
                  final userData = jsonDecode(userDataStr);
                  final email = userData['email'] as String?;

                  if (email != null) {
                    print('Resending verification email to $email');
                    final result =
                        await VerificationService.resendVerificationEmail(
                          userId,
                          email,
                        );

                    if (result['success'] == true) {
                      // Show success message
                      setState(() {
                        _errorMessage =
                            'Verification email resent. Please check your inbox and try again.';
                        _isVerifying = false;
                      });
                    } else {
                      // Show error message
                      setState(() {
                        _errorMessage =
                            result['error'] ??
                            'Failed to resend verification email';
                        _isVerifying = false;
                      });
                    }
                  } else {
                    throw Exception('Email not found in user data');
                  }
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Error reading user data: $e';
                    _isVerifying = false;
                  });
                }
              } else {
                setState(() {
                  _errorMessage =
                      'User information not found. Please go back and try again.';
                  _isVerifying = false;
                });
              }
            } catch (e) {
              setState(() {
                _errorMessage = 'Error: $e';
                _isVerifying = false;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('RESEND VERIFICATION EMAIL'),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            minimumSize: const Size.fromHeight(56),
            side: const BorderSide(color: AppTheme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Go Back'),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _isVerifying = true;
              _retryCount = 0;
            });
            _verifyEmail();
          },
          child: const Text(
            'Try Again',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
