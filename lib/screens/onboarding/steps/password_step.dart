import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class PasswordStep extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool verifiedEmail;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirmPassword;
  final Function(bool) onVerifiedEmailChanged;

  const PasswordStep({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.verifiedEmail,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirmPassword,
    required this.onVerifiedEmailChanged,
  });

  @override
  State<PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<PasswordStep>
    with SingleTickerProviderStateMixin {
  // Status of password guidelines
  bool _hasMinLength = false;
  bool _passwordsMatch = false;
  bool _hasLettersAndNumbers = false;
  bool _hasSpecialChars = false;
  double _passwordStrength = 0.0; // 0.0 to 1.0

  // Animation controller for guidelines updates
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Add listeners to update guidelines in real-time
    widget.passwordController.addListener(_updatePasswordGuidelines);
    widget.confirmPasswordController.addListener(_updatePasswordGuidelines);

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Start the animation as fully visible
    _animationController.value = 1.0;

    // Initial check
    _updatePasswordGuidelines();
  }

  @override
  void dispose() {
    // Remove listeners
    widget.passwordController.removeListener(_updatePasswordGuidelines);
    widget.confirmPasswordController.removeListener(_updatePasswordGuidelines);
    _animationController.dispose();
    super.dispose();
  }

  void _updatePasswordGuidelines() {
    final bool wasMinLength = _hasMinLength;
    final bool wasPasswordsMatch = _passwordsMatch;
    final bool wasLettersAndNumbers = _hasLettersAndNumbers;
    final bool wasSpecialChars = _hasSpecialChars;

    setState(() {
      _hasMinLength = _isPasswordLongEnough();
      _passwordsMatch = _doPasswordsMatch();
      _hasLettersAndNumbers = _containsLettersAndNumbers();
      _hasSpecialChars = _hasSpecialCharacters();
      _calculatePasswordStrength();
    });

    // Animate if any guideline changed
    if (wasMinLength != _hasMinLength ||
        wasPasswordsMatch != _passwordsMatch ||
        wasLettersAndNumbers != _hasLettersAndNumbers ||
        wasSpecialChars != _hasSpecialChars) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _calculatePasswordStrength() {
    final String password = widget.passwordController.text;
    // Base score: empty password is 0, otherwise start at 0.25
    double strength = password.isEmpty ? 0.0 : 0.25;

    // Length factor (up to 0.25)
    if (password.length >= 6) {
      strength += 0.15;
      if (password.length >= 10) {
        strength += 0.10;
      }
    }

    // Complexity factors (up to 0.5)
    if (_hasLettersAndNumbers) {
      strength += 0.25;
    }
    if (_hasSpecialChars) {
      strength += 0.25;
    }

    _passwordStrength = strength.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 46),
            child: Text(
              'Set a secure password for your account',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Password field
          TextFormField(
            controller: widget.passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Create a password',
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: widget.onToggleObscurePassword,
              ),
            ),
            obscureText: widget.obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          // Password strength indicator
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password Strength:',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  Text(
                    _getPasswordStrengthText(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getPasswordStrengthColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getPasswordStrengthColor(),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Confirm password field
          TextFormField(
            controller: widget.confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Confirm your password',
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: widget.onToggleObscureConfirmPassword,
              ),
            ),
            obscureText: widget.obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != widget.passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Email verification checkbox
          Row(
            children: [
              Checkbox(
                value: widget.verifiedEmail,
                onChanged: (value) {
                  widget.onVerifiedEmailChanged(value ?? false);
                },
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(
                child: Text(
                  'I agree to verify my email after registration',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ),
            ],
          ),

          // Password guidelines
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Guidelines',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAnimatedPasswordGuidelineRow(
                  context,
                  'At least 6 characters long',
                  _hasMinLength,
                ),
                const SizedBox(height: 8),
                _buildAnimatedPasswordGuidelineRow(
                  context,
                  'Passwords match',
                  _passwordsMatch,
                ),
                const SizedBox(height: 8),
                _buildAnimatedPasswordGuidelineRow(
                  context,
                  'Contains letters and numbers (recommended)',
                  _hasLettersAndNumbers,
                  isRequired: false,
                ),
                const SizedBox(height: 8),
                _buildAnimatedPasswordGuidelineRow(
                  context,
                  'Contains special characters (recommended)',
                  _hasSpecialChars,
                  isRequired: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength < 0.3) return Colors.red;
    if (_passwordStrength < 0.6) return Colors.orange;
    if (_passwordStrength < 0.8) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getPasswordStrengthText() {
    if (_passwordStrength < 0.3) return 'Weak';
    if (_passwordStrength < 0.6) return 'Fair';
    if (_passwordStrength < 0.8) return 'Good';
    return 'Strong';
  }

  Widget _buildAnimatedPasswordGuidelineRow(
    BuildContext context,
    String text,
    bool isFulfilled, {
    bool isRequired = true,
  }) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isFulfilled
                  ? Colors.green.withOpacity(0.1)
                  : (isRequired
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isFulfilled
                  ? Icons.check_circle
                  : (isRequired ? Icons.cancel : Icons.info_outline),
              color:
                  isFulfilled
                      ? Colors.green
                      : (isRequired ? Colors.red : Colors.orange),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color:
                      isFulfilled
                          ? Colors.green.shade800
                          : (isRequired
                              ? Colors.red.shade800
                              : Colors.orange.shade800),
                  fontSize: 14,
                  fontWeight: isFulfilled ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isPasswordLongEnough() {
    return widget.passwordController.text.length >= 6;
  }

  bool _doPasswordsMatch() {
    return widget.confirmPasswordController.text.isNotEmpty &&
        widget.confirmPasswordController.text == widget.passwordController.text;
  }

  bool _containsLettersAndNumbers() {
    final hasLetters = RegExp(
      r'[a-zA-Z]',
    ).hasMatch(widget.passwordController.text);
    final hasNumbers = RegExp(
      r'[0-9]',
    ).hasMatch(widget.passwordController.text);
    return hasLetters && hasNumbers;
  }

  bool _hasSpecialCharacters() {
    return RegExp(
      r'[!@#$%^&*(),.?":{}|<>]',
    ).hasMatch(widget.passwordController.text);
  }
}
