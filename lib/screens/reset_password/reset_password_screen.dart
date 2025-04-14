import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/reset_password_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/toast_util.dart';
import '../../utils/deep_link_handler.dart';
import '../../utils/extensions.dart';
import '../onboarding/onboarding_screen.dart';
import 'steps/email_step.dart';
import 'steps/email_sent_step.dart';
import 'steps/reset_success_step.dart';
import 'steps/new_password_step.dart';
import '../auth/signin_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String? userIdString;
  final String? initialEmail;

  const ResetPasswordScreen({
    Key? key,
    this.token,
    this.userIdString,
    this.initialEmail,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with WidgetsBindingObserver {
  // Controllers
  TextEditingController? _emailController;
  TextEditingController? _passwordController;
  TextEditingController? _confirmPasswordController;

  // State variables
  bool _isLoading = false;
  int _currentStep = 0;
  String _email = '';
  int _userId = 0;
  String _resetToken = '';

  // Flag to force staying on the new password step
  bool _forcePasswordStep = false;

  // Error states
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    // Register as an observer to get lifecycle callbacks
    WidgetsBinding.instance.addObserver(this);

    // Print debug info about what we received
    debugPrint(
      'ResetPasswordScreen initState - token: ${widget.token}, userIdString: ${widget.userIdString}',
    );

    // Check if we received token from props
    if (widget.token != null &&
        widget.token!.isNotEmpty &&
        widget.userIdString != null &&
        widget.userIdString!.isNotEmpty) {
      // Set flag to force password step permanently
      _forcePasswordStep = true;
      _currentStep = 2; // Set to password step immediately

      // Store token permanently
      _resetToken = widget.token!;
      try {
        _userId = int.parse(widget.userIdString!);
      } catch (e) {
        debugPrint('Error parsing userId: $e');
      }

      // Initialize the password controllers immediately
      _disposeControllers();
      _passwordController = TextEditingController();
      _confirmPasswordController = TextEditingController();

      debugPrint('Token and userId received, forcing password step');
    }
    // Check from the global handler
    else if (resetPasswordHandler.hasResetPasswordData() &&
        resetPasswordHandler.isFromDeepLink) {
      _checkForResetPasswordData();
    }

    // If we didn't get token from props or handler, initialize for email step
    if (!_forcePasswordStep && _resetToken.isEmpty) {
      debugPrint(
        'ResetPasswordScreen - no token or userIdString received, showing email step',
      );
      _initControllers();
    } else {
      // Validate the token in the background
      _validateToken();
    }

    // Schedule additional check to ensure we're in the right state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCorrectStep();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure we're in the correct step when dependencies change
    _ensureCorrectStep();
  }

  @override
  void didUpdateWidget(ResetPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if token or userId changed
    if ((widget.token != oldWidget.token ||
            widget.userIdString != oldWidget.userIdString) &&
        widget.token != null &&
        widget.userIdString != null) {
      debugPrint('Widget updated with new token/userId, updating state');

      // Update our stored values
      _resetToken = widget.token!;
      try {
        _userId = int.parse(widget.userIdString!);
      } catch (e) {
        debugPrint('Error parsing userId: $e');
      }

      // Force password step
      _forcePasswordStep = true;
      if (_currentStep != 2) {
        setState(() {
          _currentStep = 2;
        });
      }

      // Ensure controllers are initialized
      if (_passwordController == null || _confirmPasswordController == null) {
        _disposeControllers();
        _passwordController = TextEditingController();
        _confirmPasswordController = TextEditingController();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, ensure we're in the right state
      _ensureCorrectStep();
    }
  }

  // Method to check if reset password data exists in the global handler
  void _checkForResetPasswordData() {
    if (resetPasswordHandler.hasResetPasswordData() &&
        resetPasswordHandler.isFromDeepLink) {
      final token = resetPasswordHandler.currentResetToken;
      final userId = resetPasswordHandler.currentUserId;

      // Ensure both token and userId are non-null
      if (token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty) {
        debugPrint(
          'Found reset password data in global handler - token: $token, userId: $userId',
        );

        // Set flag to force password step permanently
        _forcePasswordStep = true;
        _currentStep = 2;
        _resetToken = token;

        try {
          _userId = int.parse(userId);
        } catch (e) {
          debugPrint('Error parsing userId from handler: $e');
        }

        // Initialize the password controllers immediately
        _disposeControllers();
        _passwordController = TextEditingController();
        _confirmPasswordController = TextEditingController();
      } else {
        debugPrint('Reset password data in handler is incomplete or invalid');
      }
    }
  }

  // Method to ensure we're always in the correct step
  void _ensureCorrectStep() {
    // If we have a token, always ensure we're on password step
    if ((_resetToken.isNotEmpty ||
            (widget.token != null && widget.token!.isNotEmpty) ||
            (resetPasswordHandler.currentResetToken != null &&
                resetPasswordHandler.currentResetToken!.isNotEmpty)) &&
        _currentStep != 3) {
      // Allow success step to stay

      if (!_forcePasswordStep || _currentStep != 2) {
        debugPrint('Ensuring correct step: forcing to password step');

        // Get latest token if available
        if (_resetToken.isEmpty) {
          if (widget.token != null && widget.token!.isNotEmpty) {
            _resetToken = widget.token!;
          } else if (resetPasswordHandler.currentResetToken != null) {
            _resetToken = resetPasswordHandler.currentResetToken!;
          }
        }

        // Get latest userId if available
        if (_userId == 0) {
          if (widget.userIdString != null && widget.userIdString!.isNotEmpty) {
            try {
              _userId = int.parse(widget.userIdString!);
            } catch (e) {
              debugPrint('Error parsing userId: $e');
            }
          } else if (resetPasswordHandler.currentUserId != null) {
            try {
              _userId = int.parse(resetPasswordHandler.currentUserId!);
            } catch (e) {
              debugPrint('Error parsing userId from handler: $e');
            }
          }
        }

        setState(() {
          _forcePasswordStep = true;
          _currentStep = 2;

          // Ensure controllers are initialized
          if (_passwordController == null ||
              _confirmPasswordController == null) {
            _disposeControllers();
            _passwordController = TextEditingController();
            _confirmPasswordController = TextEditingController();
          }
        });
      }
    }
  }

  void _initControllers() {
    // Dispose any existing controllers first
    _disposeControllers();

    // Initialize only the controllers needed for the current step
    if (_currentStep == 0) {
      _emailController = TextEditingController();
      // Pre-fill email if provided
      if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
        _emailController!.text = widget.initialEmail!;
      }
    } else if (_currentStep == 2) {
      _passwordController = TextEditingController();
      _confirmPasswordController = TextEditingController();
    }
  }

  void _disposeControllers() {
    if (_emailController != null) {
      _emailController!.dispose();
      _emailController = null;
    }

    if (_passwordController != null) {
      _passwordController!.dispose();
      _passwordController = null;
    }

    if (_confirmPasswordController != null) {
      _confirmPasswordController!.dispose();
      _confirmPasswordController = null;
    }
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);

    _disposeControllers();

    // Clear the token from the global state and handler when this screen is disposed
    try {
      // Clear the app state
      final appState = myAppKey.currentState;
      if (appState != null) {
        appState.clearResetPasswordData();
      } else {
        // Directly clear the handler if app state is not available
        resetPasswordHandler.clear();
      }
    } catch (e) {
      debugPrint('Error clearing reset password data: $e');
      // Ensure handler is cleared even if there's an error
      resetPasswordHandler.clear();
    }

    super.dispose();
  }

  // Validate token from deep link
  Future<void> _validateToken() async {
    debugPrint('Validating reset token: $_resetToken');
    setState(() {
      _isLoading = true;
    });

    final response = await ResetPasswordService.validateToken(_resetToken);
    debugPrint('Token validation response: $response');

    setState(() {
      _isLoading = false;
    });

    if (response['success']) {
      // Token is valid, stay on new password step (we're already there)
      _email = response['email'] ?? '';
      debugPrint('Token is valid, email: $_email');
    } else {
      // Token is invalid, but we'll still stay on the password step
      // Just show a warning toast but allow the user to try
      debugPrint('Token validation failed: ${response['message']}');

      ToastUtil.showWarningToast(
        context,
        'Note: ${response['message'] ?? 'There may be an issue with your reset link'}, but you can still try to reset your password.',
      );
    }
  }

  // Step 1: Request password reset
  Future<void> _requestPasswordReset() async {
    if (_emailController == null || _emailController!.text.isEmpty) {
      setState(() {
        _emailError = context.tr.translate('email_required');
      });
      return;
    }

    if (!_emailController!.text.contains('@')) {
      setState(() {
        _emailError = context.tr.translate('valid_email_required');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    // First check if the email exists
    final checkResponse = await ResetPasswordService.checkEmail(
      _emailController!.text,
    );

    if (!checkResponse['success']) {
      setState(() {
        _isLoading = false;
        _emailError = checkResponse['message'];
      });
      return;
    }

    if (!checkResponse['exists']) {
      setState(() {
        _isLoading = false;
        _emailError = context.tr.translate('no_account_found');
      });
      return;
    }

    // Email exists, send reset email
    final resetResponse = await ResetPasswordService.requestReset(
      _emailController!.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (resetResponse['success']) {
      _email = _emailController!.text;
      _userId = resetResponse['user_id'] ?? 0;

      // Go to email sent step
      setState(() {
        _currentStep = 1;
        // Re-initialize controllers for this step
        _initControllers();
      });
    } else {
      ToastUtil.showErrorToast(
        context,
        resetResponse['message'] ??
            context.tr.translate('failed_to_send_reset_email'),
      );
    }
  }

  // Step 3: Update password
  Future<void> _updatePassword() async {
    // Validate password fields
    if (_passwordController == null || _passwordController!.text.isEmpty) {
      setState(() {
        _passwordError = context.tr.translate('enter_new_password');
      });
      return;
    }

    if (_passwordController!.text.length < 6) {
      setState(() {
        _passwordError = context.tr.translate('password_must_be_6_chars');
      });
      return;
    }

    if (_confirmPasswordController == null ||
        _confirmPasswordController!.text != _passwordController!.text) {
      setState(() {
        _confirmPasswordError = context.tr.translate('passwords_dont_match');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final response = await ResetPasswordService.updatePassword(
      _resetToken,
      _userId,
      _passwordController!.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (response['success']) {
      // Password updated successfully, go to success step
      setState(() {
        _currentStep = 3;
        // Re-initialize controllers for this step
        _initControllers();
      });
    } else {
      ToastUtil.showErrorToast(
        context,
        response['message'] ??
            context.tr.translate('failed_to_update_password'),
      );
    }
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // Toggle confirm password visibility
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  // Navigate to sign in
  void _navigateToSignIn() {
    debugPrint('ResetPasswordScreen - navigateToSignIn called');

    // Clear reset password data first
    try {
      final appState = myAppKey.currentState;
      if (appState != null) {
        debugPrint('Clearing reset password data through app state');
        appState.clearResetPasswordData();
      }
    } catch (e) {
      debugPrint('Error clearing reset password data: $e');
    }

    // Use direct navigation instead of app state for more reliable navigation
    if (mounted && context.mounted) {
      debugPrint('Using direct navigation to SignInScreen');

      // Use pushReplacement to replace the current screen entirely
      // This prevents nesting issues by completely removing this screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false, // Remove all previous routes
      );
    } else {
      debugPrint('Context not available for navigation');

      // Fallback to app state method
      try {
        final appState = myAppKey.currentState;
        if (appState != null) {
          debugPrint('Using app state for navigation to sign in');
          appState.navigateToSignIn();
        }
      } catch (e) {
        debugPrint('Error with fallback navigation: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'ResetPasswordScreen build - currentStep: $_currentStep, token: $_resetToken, userId: $_userId, forcePasswordStep: $_forcePasswordStep',
    );

    // Always ensure we're in the correct step before building UI
    if (_forcePasswordStep && _currentStep != 3) {
      // Force to password step if we have a token
      if (_currentStep != 2) {
        debugPrint(
          'Forcing to password step (step 2) because forcePasswordStep is true',
        );

        // Important: Do this synchronously to prevent flashing of wrong UI
        _currentStep = 2;

        // Ensure password controllers are initialized
        if (_passwordController == null || _confirmPasswordController == null) {
          _disposeControllers();
          _passwordController = TextEditingController();
          _confirmPasswordController = TextEditingController();
        }
      }
    }

    return WillPopScope(
      // Prevent going back if we're on password step with token
      onWillPop: () async {
        if (_forcePasswordStep && _currentStep == 2) {
          // Don't allow back navigation from password step when from deep link
          return false;
        }

        // Handle custom back navigation for email sent step
        if (_currentStep == 1) {
          // Go back to email input step
          setState(() {
            _currentStep = 0;
            _initControllers();
            _emailError = null;
          });
          return false; // Prevent default back behavior
        }

        // For email input step, navigate to sign in
        if (_currentStep == 0) {
          _navigateToSignIn();
          return false; // Prevent default back behavior
        }

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getStepTitle()),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          // Hide back button if on password step with token from deep link
          automaticallyImplyLeading: !(_forcePasswordStep && _currentStep == 2),
          // Custom back button handling
          leading: _buildCustomBackButton(),
        ),
        body: SafeArea(child: _buildCurrentStep()),
      ),
    );
  }

  // Build custom back button with proper navigation logic
  Widget? _buildCustomBackButton() {
    // If on password step with token from deep link, don't show back button
    if (_forcePasswordStep && _currentStep == 2) {
      return null;
    }

    // For email sent step, go back to email input step
    if (_currentStep == 1) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navigate back to email input step
          setState(() {
            _currentStep = 0;
            _initControllers();
            _emailError = null;
          });
        },
      );
    }

    // For email input step, go back to sign in screen
    if (_currentStep == 0) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navigate to sign in screen
          _navigateToSignIn();
        },
      );
    }

    // For other steps, use default back button behavior
    return null;
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return context.tr.translate('reset_password');
      case 1:
        return context.tr.translate('check_your_email');
      case 2:
        return context.tr.translate('create_new_password');
      case 3:
        return context.tr.translate('password_reset_complete');
      default:
        return context.tr.translate('reset_password');
    }
  }

  Widget _buildCurrentStep() {
    // Double check that we have the right step based on the token presence
    _ensureCorrectStep();

    // If forcing password step and not on success screen, always show password step
    if (_forcePasswordStep && _currentStep != 3) {
      debugPrint('Building password step UI because forcePasswordStep is true');

      // Ensure controllers are initialized
      if (_passwordController == null || _confirmPasswordController == null) {
        _disposeControllers();
        _passwordController = TextEditingController();
        _confirmPasswordController = TextEditingController();
      }

      return NewPasswordStep(
        passwordController: _passwordController!,
        confirmPasswordController: _confirmPasswordController!,
        passwordError: _passwordError,
        confirmPasswordError: _confirmPasswordError,
        obscurePassword: _obscurePassword,
        obscureConfirmPassword: _obscureConfirmPassword,
        isLoading: _isLoading,
        onTogglePasswordVisibility: _togglePasswordVisibility,
        onToggleConfirmPasswordVisibility: _toggleConfirmPasswordVisibility,
        onSubmit: _updatePassword,
      );
    }

    // Normal flow for other steps
    switch (_currentStep) {
      case 0:
        if (_emailController == null) {
          _initControllers();
        }
        return EmailStep(
          emailController: _emailController!,
          emailError: _emailError,
          isLoading: _isLoading,
          onSubmit: _requestPasswordReset,
          onBack: _navigateToSignIn,
        );
      case 1:
        return EmailSentStep(
          email: _email,
          onBack: () {
            // Go back to email input step
            setState(() {
              _currentStep = 0;
              _initControllers();
              _emailError = null;
            });
          },
        );
      case 2:
        if (_passwordController == null || _confirmPasswordController == null) {
          _initControllers();
        }
        return NewPasswordStep(
          passwordController: _passwordController!,
          confirmPasswordController: _confirmPasswordController!,
          passwordError: _passwordError,
          confirmPasswordError: _confirmPasswordError,
          obscurePassword: _obscurePassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          isLoading: _isLoading,
          onTogglePasswordVisibility: _togglePasswordVisibility,
          onToggleConfirmPasswordVisibility: _toggleConfirmPasswordVisibility,
          onSubmit: _updatePassword,
        );
      case 3:
        return ResetSuccessStep(onSignIn: _navigateToSignIn);
      default:
        if (_emailController == null) {
          _initControllers();
        }
        return EmailStep(
          emailController: _emailController!,
          emailError: _emailError,
          isLoading: _isLoading,
          onSubmit: _requestPasswordReset,
          onBack: _navigateToSignIn,
        );
    }
  }
}
