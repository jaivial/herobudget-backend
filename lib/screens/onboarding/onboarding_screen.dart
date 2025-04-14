import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../utils/locale_util.dart';
import '../../utils/toast_util.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/signin_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'steps/language_step.dart';
import 'steps/auth_options_step.dart';
import 'steps/email_step.dart';
import 'steps/password_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/profile_image_step.dart';
import 'steps/signin_step.dart';
import 'steps/signin_step_wrapper.dart';
import 'steps/password_step_wrapper.dart';
import '../verification/email_verification_screen.dart';
import '../reset_password/reset_password_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool initialShowSignIn;

  const OnboardingScreen({super.key, this.initialShowSignIn = false});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controller to manage the page view
  final PageController _pageController = PageController(initialPage: 1);

  // Current page index
  int _currentStep = 1;

  // Form keys for different screens to avoid duplicate key issues
  final _formKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _signInFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _profileImageFormKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Tracks if we're in signup or signin flow
  bool _isSignupFlow = true;

  // Step 1 - Language & Region
  String _selectedLocale = '';
  bool _languageSelected = false;

  // Sign In Fields
  final _signinEmailController = TextEditingController();
  final _signinPasswordController = TextEditingController();
  bool _signinObscurePassword = true;
  String? _signinEmailError;
  String? _signinPasswordError;

  // Sign Up Fields
  // Step 2 - Email
  final _emailController = TextEditingController();
  String? _emailError;
  // Add a variable to store the email separately
  String _signupEmail = '';

  // Step 3 - Password
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _verifiedEmail = true; // Default to true

  // Step 4 - Personal Info
  final _givenNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();

  // Step 5 - Profile Image
  File? _profileImageFile;
  String? _base64Image;

  @override
  void initState() {
    super.initState();

    print(
      "OnboardingScreen initState - initialShowSignIn: ${widget.initialShowSignIn}",
    );

    // Check if we need to show sign-in immediately
    if (widget.initialShowSignIn) {
      print(
        "Setting up delayed call to _handleSignInSelected due to initialShowSignIn=true",
      );

      // We need to wait until the widget is fully built before navigating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("Executing delayed _handleSignInSelected call");
        setState(() {
          _isSignupFlow = false; // Make sure we're in sign-in mode
        });
        _handleSignInSelected();
      });
    }

    // Override the initial page controller to ensure it starts at page 1 (welcome screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(1); // Always start at welcome screen
      }
    });

    _checkLanguageAndUser();

    // Add listener to email controller to automatically update _signupEmail
    _emailController.addListener(() {
      if (_emailController.text.isNotEmpty &&
          _emailController.text.contains('@')) {
        // Only update if it's a potentially valid email
        _signupEmail = _emailController.text;
        print("Email controller updated, new _signupEmail: '$_signupEmail'");
      }
    });
  }

  Future<void> _checkLanguageAndUser() async {
    // Always set language as selected, using device language as default
    _detectDeviceLocale();
    setState(() {
      _languageSelected = true;
    });

    // First check if user is already signed in
    bool isSignedIn = await SignInService.isSignedIn();

    if (isSignedIn) {
      // User is already signed in, navigate to dashboard
      final userData = await SignInService.getCurrentUser();
      if (userData != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => DashboardScreen(
                  userId: userData['id'].toString(),
                  userInfo: userData,
                ),
          ),
        );
        return;
      }
    }

    // If not signed in, check for language preference
    String? language = await LanguageService.getLanguagePreference();

    if (language != null && language.isNotEmpty) {
      // Language is already set, skip to auth options
      setState(() {
        _selectedLocale = language;
        _currentStep = 1; // Move to auth options step

        // Need to wait for build to complete before animating
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(1); // Jump to auth options
        });
      });
    } else {
      // Save the detected device language
      await LanguageService.saveLanguagePreference(_selectedLocale);

      setState(() {
        _currentStep = 1; // Start at auth options
      });

      // Need to wait for build to complete before animating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageController.jumpToPage(1); // Jump to auth options
      });
    }
  }

  void _detectDeviceLocale() {
    _selectedLocale = LocaleUtil.detectDeviceLocale(null);
    // Set language as selected even when using device locale
    _languageSelected = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _givenNameController.dispose();
    _familyNameController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _signinEmailController.dispose();
    _signinPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building OnboardingScreen with _currentStep: $_currentStep");

    // Ensure we properly cleanup any leftover state when on the welcome screen
    if (_currentStep == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // This will run after the build completes
        // Clear any potential leftover state from previous navigation
        if (_profileImageFile != null ||
            _emailController.text.isNotEmpty ||
            _passwordController.text.isNotEmpty ||
            _confirmPasswordController.text.isNotEmpty ||
            _givenNameController.text.isNotEmpty ||
            _familyNameController.text.isNotEmpty) {
          setState(() {
            _profileImageFile = null;
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            _givenNameController.clear();
            _familyNameController.clear();
            _emailError = null;
            _signinEmailError = null;
            _signinPasswordError = null;
          });
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Always show header for step 2 and higher, except auth options
              if (_currentStep >= 2 || (_currentStep == 1 && !_isSignupFlow))
                _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (int page) {
                    print("PageView onPageChanged: $page");
                    // Only update state if the page has actually changed and we're not in the middle of a navigation
                    if (_currentStep != page) {
                      setState(() {
                        _currentStep = page;
                      });
                    }
                  },
                  children: [
                    // Step 1: Language selection
                    LanguageStep(
                      selectedLocale: _selectedLocale,
                      onLocaleChanged: (locale) {
                        setState(() {
                          _selectedLocale = locale;
                        });
                      },
                    ),

                    // Step 2: Auth Options (Sign Up, Sign In, Google)
                    AuthOptionsStep(
                      onSignUp: _handleSignUpSelected,
                      onSignIn: _handleSignInSelected,
                      onGoogleSignIn: _handleGoogleSignIn,
                    ),

                    // Step 3 (sign in): Sign In Form
                    SignInStep(
                      emailController: _signinEmailController,
                      passwordController: _signinPasswordController,
                      obscurePassword: _signinObscurePassword,
                      emailError: _signinEmailError,
                      passwordError: _signinPasswordError,
                      isLoading: _isLoading,
                      onToggleObscurePassword: () {
                        setState(() {
                          _signinObscurePassword = !_signinObscurePassword;
                        });
                      },
                      onForgotPassword: _handleForgotPassword,
                      onEmailChanged: () {
                        if (_signinEmailError != null) {
                          setState(() {
                            _signinEmailError = null;
                          });
                        }
                      },
                      onGoogleSignIn: _handleGoogleSignIn,
                    ),

                    // Step 3 (sign up): Email input & Google sign-in
                    EmailStep(
                      emailController: _emailController,
                      emailError: _emailError,
                      isLoading: _isLoading,
                      onEmailChanged: () {
                        if (_emailError != null) {
                          setState(() {
                            _emailError = null;
                          });
                        }
                      },
                      onGoogleSignIn: _handleGoogleSignIn,
                    ),

                    // Step 4 (sign up): Password creation
                    PasswordStep(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      obscurePassword: _obscurePassword,
                      obscureConfirmPassword: _obscureConfirmPassword,
                      verifiedEmail: _verifiedEmail,
                      onToggleObscurePassword: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onToggleObscureConfirmPassword: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      onVerifiedEmailChanged: (value) {
                        setState(() {
                          _verifiedEmail = value;
                        });
                      },
                    ),

                    // Step 5 (sign up): Personal info
                    PersonalInfoStep(
                      givenNameController: _givenNameController,
                      familyNameController: _familyNameController,
                      firstNameFocusNode: _firstNameFocusNode,
                      lastNameFocusNode: _lastNameFocusNode,
                    ),

                    // Step 6 (sign up): Profile image
                    _buildProfileImageScreen(),
                  ],
                ),
              ),
              _buildNavButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/herobudgeticon.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _getStepTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStepDescription(),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    // Debug print to check which step is currently active
    print("Current step in _buildNavButtons: $_currentStep");

    // For auth options screen (step 1), don't show any navigation buttons since it has its own buttons
    if (_currentStep == 1) {
      return const SizedBox.shrink();
    }

    // For language selection, only show "Next" button
    if (_currentStep == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            // Save language preference and move to auth options
            await LanguageService.saveLanguagePreference(_selectedLocale);
            setState(() {
              _languageSelected = true;
              _currentStep = 1; // Move to next step
            });
            _pageController.jumpToPage(1); // Use jumpToPage for reliability
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // For signin screen, show sign in button
    if (_currentStep == 2 && !_isSignupFlow) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : () async {
                    await _handleSignIn();
                  },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text(
                    'SIGN IN',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
        ),
      );
    }

    // For signup flow
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          // Special case for email step (3) to go back to auth options (1)
                          if (_currentStep == 3) {
                            setState(() {
                              _currentStep = 1;
                              // Clear any form data if needed
                              _emailError = null;
                              _emailController.clear();
                            });
                            _pageController.jumpToPage(
                              1,
                            ); // Use jumpToPage for reliability
                          } else {
                            setState(() {
                              _currentStep -= 1;
                            });
                            _pageController.jumpToPage(
                              _currentStep,
                            ); // Use jumpToPage for reliability
                          }
                        },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('BACK'),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () async {
                        if (_currentStep < 6) {
                          // Validate current step before proceeding
                          bool isValid = await _validateCurrentStep();
                          if (isValid) {
                            final nextStep = _currentStep + 1;
                            setState(() {
                              _currentStep = nextStep;
                            });
                            _pageController.jumpToPage(
                              nextStep,
                            ); // Use jumpToPage for reliability
                          }
                        } else {
                          // Submit the form (final step)
                          if (_formKey.currentState!.validate()) {
                            _handleManualSignup();
                          }
                        }
                      },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(_currentStep < 6 ? 'NEXT' : 'GET STARTED'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSignUpSelected() {
    print("_handleSignUpSelected called, navigating to email step");

    // Navigate to email step directly using a new route instead of PageView
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              body: SafeArea(
                child: Form(
                  key: _signUpFormKey,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: EmailStep(
                          emailController: _emailController,
                          emailError: _emailError,
                          isLoading: _isLoading,
                          onEmailChanged: () {
                            if (_emailError != null) {
                              setState(() {
                                _emailError = null;
                              });
                            }
                          },
                          onGoogleSignIn: _handleGoogleSignIn,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Reset state to prevent view stacking when going back to welcome screen
                                  setState(() {
                                    _currentStep =
                                        1; // Reset to welcome/auth options step
                                    // Clear any form data if needed
                                    _emailError = null;
                                    _emailController.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('BACK'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () async {
                                          print(
                                            "NEXT button pressed on email step",
                                          );
                                          // Validate email step
                                          if (_emailController.text.isEmpty ||
                                              !_emailController.text.contains(
                                                '@',
                                              )) {
                                            print(
                                              "Email validation failed: ${_emailController.text}",
                                            );
                                            ToastUtil.showErrorToast(
                                              context,
                                              'Please enter a valid email address',
                                            );
                                            return;
                                          }

                                          // Capture the email immediately when it's valid
                                          final validEmail =
                                              _emailController.text;
                                          print(
                                            "Captured valid email: '$validEmail'",
                                          );

                                          print(
                                            "Checking if email exists: $validEmail",
                                          );
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          try {
                                            print(
                                              "Checking if email exists: $validEmail",
                                            );

                                            final emailExists =
                                                await AuthService.checkEmailExists(
                                                  validEmail,
                                                );

                                            print(
                                              "Email exists check result: $emailExists",
                                            );
                                            print(
                                              "Email value after check: '$validEmail'",
                                            );

                                            setState(() {
                                              _isLoading = false;
                                            });

                                            // If email already exists, show error
                                            if (emailExists) {
                                              setState(() {
                                                _emailError =
                                                    'This email is already registered';
                                              });
                                              ToastUtil.showCustomToast(
                                                context,
                                                'Account with this email already exists. Try signing in instead.',
                                                backgroundColor:
                                                    AppTheme.secondaryColor,
                                                action: SnackBarAction(
                                                  label: 'Sign In',
                                                  textColor: Colors.white,
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _handleSignInSelected();
                                                  },
                                                ),
                                              );
                                              return;
                                            }

                                            // If email is valid, proceed to password step
                                            print(
                                              "Email valid, proceeding to password step",
                                            );
                                            // Store the email value in the class variable
                                            _signupEmail = validEmail;
                                            print(
                                              "Email controller text: '$validEmail'",
                                            );
                                            print(
                                              "Stored email in _signupEmail: '$_signupEmail'",
                                            );

                                            setState(() {
                                              _currentStep = 4;
                                            });

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        _buildPasswordScreen(),
                                              ),
                                            );
                                          } catch (e) {
                                            print(
                                              'Error in email validation: $e',
                                            );

                                            // Set loading state to false
                                            setState(() {
                                              _isLoading = false;
                                            });

                                            // Show specific error for timeout issues
                                            if (e.toString().contains(
                                              'TimeoutException',
                                            )) {
                                              ToastUtil.showCustomToast(
                                                context,
                                                'Connection to server timed out. Please check your network and that the backend services are running.',
                                                backgroundColor: Colors.orange,
                                                action: SnackBarAction(
                                                  label: 'Continue Anyway',
                                                  textColor: Colors.white,
                                                  onPressed: () {
                                                    // If user wants to continue despite error
                                                    print(
                                                      "Continuing despite connection error",
                                                    );
                                                    setState(() {
                                                      _currentStep = 4;
                                                    });

                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                                _buildPasswordScreen(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            } else {
                                              ToastUtil.showErrorToast(
                                                context,
                                                'Error validating email: $e. Please try again.',
                                              );
                                            }
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text('NEXT'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  // Helper method to build the password screen
  Widget _buildPasswordScreen() {
    return PasswordStepWrapper(
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      isLoading: _isLoading,
      onBack: () {
        // Reset state when going back to email step
        setState(() {
          _currentStep = 3; // Reset to email step
        });
        Navigator.pop(context);
      },
      onNext: () {
        setState(() {
          _currentStep = 5;
        });

        // Navigate to the personal info step
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  body: SafeArea(
                    child: Form(
                      key: _personalInfoFormKey,
                      child: Column(
                        children: [
                          _buildHeader(),
                          Expanded(
                            child: PersonalInfoStep(
                              givenNameController: _givenNameController,
                              familyNameController: _familyNameController,
                              firstNameFocusNode: _firstNameFocusNode,
                              lastNameFocusNode: _lastNameFocusNode,
                            ),
                          ),
                          // Navigation buttons
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Reset state when going back to prevent view stacking issues
                                      setState(() {
                                        _currentStep =
                                            4; // Reset to password step
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('BACK'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Validate personal info
                                      if (_givenNameController.text.isEmpty) {
                                        ToastUtil.showErrorToast(
                                          context,
                                          'First name is required',
                                        );
                                        return;
                                      }
                                      if (_familyNameController.text.isEmpty) {
                                        ToastUtil.showErrorToast(
                                          context,
                                          'Last name is required',
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _currentStep = 6;
                                      });

                                      // Navigate to profile image step
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  _buildProfileImageScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('NEXT'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  // Add a helper method for the profile image screen
  Widget _buildProfileImageScreen() {
    // Add an immediate check that we have an email value before showing this screen
    if (_signupEmail.isEmpty) {
      print("WARNING: Empty _signupEmail when building profile image screen!");
      // Try to recover from the controller if possible
      if (_emailController.text.isNotEmpty) {
        _signupEmail = _emailController.text;
        print("Recovered email from controller: '$_signupEmail'");
      }
    } else {
      print("Confirmed email value before profile screen: '$_signupEmail'");
    }

    return StatefulBuilder(
      builder:
          (context, setState) => Stack(
            children: [
              Scaffold(
                body: SafeArea(
                  child: Form(
                    key: _profileImageFormKey,
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: ProfileImageStep(
                            profileImageFile: _profileImageFile,
                            onPickImage: (ImageSource source) async {
                              try {
                                final picker = ImagePicker();
                                final XFile? pickedFile = await picker
                                    .pickImage(
                                      source: source,
                                      maxWidth: 600,
                                      maxHeight: 600,
                                      imageQuality: 80,
                                    );

                                if (pickedFile != null) {
                                  setState(() {
                                    _profileImageFile = File(pickedFile.path);
                                  });
                                  // Also update parent state
                                  this.setState(() {});
                                }
                              } catch (e) {
                                ToastUtil.showErrorToast(
                                  context,
                                  'Error picking image: $e',
                                );
                              }
                            },
                            selectedLocale: _selectedLocale,
                            showLanguageInfo: false,
                          ),
                        ),
                        // Navigation buttons
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                            // Clear state when going back to prevent view stacking issues
                                            this.setState(() {
                                              _currentStep =
                                                  5; // Reset to personal info step
                                            });
                                            Navigator.pop(context);
                                          },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('BACK'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                            // Add debug print to verify this is being called
                                            print(
                                              "GET STARTED button clicked on profile image step",
                                            );

                                            // First update the parent's state to ensure we're on the right step
                                            this.setState(() {
                                              _currentStep =
                                                  6; // Ensure we're on profile image step
                                              _isLoading = true;
                                            });

                                            // Then update the local state
                                            setState(() {
                                              // Local loading state
                                            });

                                            // Directly call the parent's method from here
                                            // This is important to ensure we have the right context
                                            // and state when making the API call
                                            print(
                                              "About to call _handleManualSignup from profile image step",
                                            );
                                            _handleManualSignup();
                                          },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('GET STARTED'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Full-screen loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 40,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryColor,
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Creating your account...',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please wait a moment',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  void _handleSignInSelected() {
    print("_handleSignInSelected called, navigating to signin step");

    // Set the flag to indicate we're in sign-in flow
    setState(() {
      // Set this explicitly to false to ensure sign-in UI is shown
      _isSignupFlow = false;
    });

    // Navigate to signin step directly using the wrapper
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SignInStepWrapper(
              emailController: _signinEmailController,
              passwordController: _signinPasswordController,
              emailError: _signinEmailError,
              passwordError: _signinPasswordError,
              isLoading: _isLoading,
              onForgotPassword: _handleForgotPassword,
              onEmailChanged: () {
                if (_signinEmailError != null) {
                  setState(() {
                    _signinEmailError = null;
                  });
                }
              },
              onGoogleSignIn: _handleGoogleSignIn,
              onSignIn: _handleSignIn,
              onBack: () {
                // Reset state to prevent view stacking when going back to welcome screen
                setState(() {
                  _currentStep = 1; // Reset to welcome/auth options step
                  // Clear any sign in form data
                  _signinEmailError = null;
                  _signinPasswordError = null;
                  _signinEmailController.clear();
                  _signinPasswordController.clear();
                  _signinObscurePassword = true;
                });
                Navigator.pop(context);
              },
            ),
      ),
    );
  }

  void _handleForgotPassword() {
    // This method is called when the "Forgot Password" link is clicked

    // First save the email if available for potential use on the reset password screen
    String email = '';
    try {
      if (_signinEmailController.text.isNotEmpty &&
          _signinEmailController.text.contains('@')) {
        email = _signinEmailController.text;
      }
    } catch (e) {
      // Handle any potential access to disposed controllers
      debugPrint('Error accessing email controller: $e');
    }

    // Clear signin form controllers before navigation to avoid conflicts
    _signinEmailController.text = '';
    _signinPasswordController.text = '';

    // Use pushReplacement to replace the current screen entirely
    // This helps avoid TextEditingController issues when navigating between screens
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(initialEmail: email),
      ),
    );
  }

  String _getStepTitle() {
    if (!_isSignupFlow && _currentStep == 2) {
      return 'Sign In to Your Account';
    }

    switch (_currentStep) {
      case 0:
        return 'Choose Your Language';
      case 1:
        return 'Welcome to Hero Budget';
      case 2:
        return 'Sign In to Your Account';
      case 3:
        return 'Create an Account';
      case 4:
        return 'Create a Password';
      case 5:
        return 'Personal Information';
      case 6:
        return 'Profile Picture';
      default:
        return '';
    }
  }

  String _getStepDescription() {
    if (!_isSignupFlow && _currentStep == 2) {
      return 'Enter your credentials to access your account';
    }

    switch (_currentStep) {
      case 0:
        return 'Select your preferred language and region for the app.';
      case 1:
        return 'The smart way to manage your finances';
      case 2:
        return 'Enter your credentials to access your account';
      case 3:
        return 'Enter your email to create an account or continue with Google.';
      case 4:
        return 'Create a secure password for your account.';
      case 5:
        return 'Tell us more about yourself.';
      case 6:
        return 'Add a profile picture to personalize your account.';
      default:
        return '';
    }
  }

  Future<bool> _validateCurrentStep() async {
    // Validate only fields in the current step
    switch (_currentStep) {
      case 0:
        // Language step - save selection and continue
        await LanguageService.saveLanguagePreference(_selectedLocale);
        setState(() {
          _languageSelected = true;
        });
        return true;

      case 1:
        // Auth options - always valid
        return true;

      case 2:
        // Sign in step - validation happens in handleSignIn
        if (!_isSignupFlow) {
          return true;
        }
        // Should not reach here in signup flow
        return false;

      case 3:
        // Email step for signup
        if (_emailController.text.isEmpty ||
            !_emailController.text.contains('@')) {
          ToastUtil.showErrorToast(
            context,
            'Please enter a valid email address',
          );
          return false;
        }

        // Check if email already exists
        setState(() {
          _isLoading = true;
        });

        bool emailExists = await AuthService.checkEmailExists(
          _emailController.text,
        );

        setState(() {
          _isLoading = false;
          if (emailExists) {
            _emailError = 'This email is already registered';
            ToastUtil.showCustomToast(
              context,
              'Account with this email already exists. Try signing in instead.',
              backgroundColor: AppTheme.secondaryColor,
              action: SnackBarAction(
                label: 'Sign In',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                  _handleSignInSelected();
                },
              ),
            );
          }
        });

        return !emailExists;

      case 4:
        // Password step
        if (_passwordController.text.isEmpty) {
          ToastUtil.showErrorToast(context, 'Please enter a password');
          return false;
        }

        if (_passwordController.text.length < 6) {
          ToastUtil.showErrorToast(
            context,
            'Password must be at least 6 characters',
          );
          return false;
        }

        if (_confirmPasswordController.text != _passwordController.text) {
          ToastUtil.showErrorToast(context, 'Passwords do not match');
          return false;
        }

        return true;

      case 5:
        // Personal info step
        if (_givenNameController.text.isEmpty) {
          ToastUtil.showErrorToast(context, 'First name is required');
          return false;
        }

        if (_familyNameController.text.isEmpty) {
          ToastUtil.showErrorToast(context, 'Last name is required');
          return false;
        }

        return true;

      case 6:
        // Profile image step
        if (_profileImageFile == null) {
          ToastUtil.showWarningToast(
            context,
            'No profile image selected. You can add one later.',
          );
        }
        return true;

      default:
        return true;
    }
  }

  Future<void> _handleSignIn() async {
    if (!mounted) return;

    // Validate form if we're on the sign in screen
    if (_signInFormKey.currentState != null &&
        !_signInFormKey.currentState!.validate()) {
      return;
    }

    // Validate email and password
    if (_signinEmailController.text.isEmpty ||
        !_signinEmailController.text.contains('@')) {
      setState(() {
        _signinEmailError = 'Please enter a valid email address';
      });
      return;
    }

    if (_signinPasswordController.text.isEmpty) {
      setState(() {
        _signinPasswordError = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _signinEmailError = null;
      _signinPasswordError = null;
    });

    try {
      final result = await SignInService.signIn(
        _signinEmailController.text,
        _signinPasswordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        // Success
        final userInfo = result['user'];
        final userId = userInfo['id'].toString();

        // Navigate to dashboard and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DashboardScreen(userId: userId, userInfo: userInfo),
          ),
          (route) => false, // This removes all previous routes
        );
      } else {
        // Show error message
        ToastUtil.showErrorToast(context, result['error']);

        // Set specific field errors if applicable
        if (result['error'].toString().contains('email')) {
          setState(() {
            _signinEmailError = 'Invalid email address';
          });
        }
        if (result['error'].toString().contains('password')) {
          setState(() {
            _signinPasswordError = 'Invalid password';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showErrorToast(context, 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleManualSignup() async {
    if (!mounted) return;

    // Add debug print
    print("_handleManualSignup method called");
    print("Current stored email value: '$_signupEmail'");
    print("Current controller email value: '${_emailController.text}'");

    // Check which step we're on and use the appropriate form key
    // The issue is that we have different form keys for different screens
    GlobalKey<FormState>? formKeyToValidate;

    if (_currentStep == 6) {
      formKeyToValidate = _profileImageFormKey;
    } else {
      formKeyToValidate = _signUpFormKey;
    }

    // Validate form before submission only if we have a form to validate
    // For profile image step, there's no validation required
    if (formKeyToValidate != null &&
        formKeyToValidate.currentState != null &&
        !formKeyToValidate.currentState!.validate()) {
      print("Form validation failed");
      return;
    }

    // Email handling - always prioritize the _signupEmail value that was captured
    // at the email validation step, since _emailController might have been reset
    // during navigation
    String emailToUse = _signupEmail;

    // Only as a fallback, use controller if _signupEmail is empty
    if (emailToUse.isEmpty && _emailController.text.isNotEmpty) {
      print(
        "Using email from controller as fallback: '${_emailController.text}'",
      );
      emailToUse = _emailController.text;
    }

    // Check if email is empty - this is a critical error
    if (emailToUse.isEmpty) {
      print("ERROR: Email is empty! This should not happen.");
      ToastUtil.showErrorToast(
        context,
        'Email address is required. Please restart the signup process.',
      );
      return;
    }

    print("Final email to use for registration: '$emailToUse'");

    setState(() {
      _isLoading = true;
    });

    try {
      // Register user
      print("Calling AuthService.registerUser");
      print("Debug - Email value: '$emailToUse'");

      final result = await AuthService.registerUser(
        email: emailToUse,
        password: _passwordController.text,
        givenName: _givenNameController.text,
        familyName: _familyNameController.text,
        locale: _selectedLocale,
        verifiedEmail: _verifiedEmail,
        profileImage: _profileImageFile,
      );

      if (!mounted) return;

      if (result['success']) {
        // Success
        final userInfo = result['user'];
        final userId = userInfo['id'].toString();

        // Save user to localStorage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('user_info', jsonEncode(userInfo));

        // Check if email is verified
        final bool isEmailVerified = userInfo['verified_email'] ?? false;

        if (isEmailVerified) {
          // If email is verified, go directly to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      DashboardScreen(userId: userId, userInfo: userInfo),
            ),
          );
        } else {
          // If email is not verified, go to verification screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EmailVerificationScreen(
                    userId: userId,
                    userInfo: userInfo,
                  ),
            ),
          );
        }
      } else {
        // Show error message
        ToastUtil.showErrorToast(context, result['error']);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showErrorToast(context, 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signInWithGoogle();

      if (!mounted) return;

      if (result['success']) {
        // Success
        final userInfo = result['user'];
        final userId = userInfo['id'].toString();

        // Get the locale from the user info, ensuring it's not empty
        String userLocale = userInfo['locale'] ?? '';
        // If the locale is empty in the response, use the selected locale
        if (userLocale.isEmpty) {
          userLocale = _selectedLocale.isEmpty ? 'en-US' : _selectedLocale;
          print(
            'User locale empty in response, using selected locale: $userLocale',
          );
        } else {
          print('Got user locale from response: $userLocale');
        }

        // Save user to localStorage using standardized keys
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(SignInService.userIdKey, userId);
        await prefs.setString(SignInService.userDataKey, jsonEncode(userInfo));

        // Save the user's locale preference
        await LanguageService.saveLanguagePreference(userLocale);
        print('Saved user locale preference: $userLocale');

        // Navigate to dashboard and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DashboardScreen(userId: userId, userInfo: userInfo),
          ),
          (route) => false, // This removes all previous routes
        );
      } else {
        // Show error message
        ToastUtil.showErrorToast(context, result['error']);
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showErrorToast(context, 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
