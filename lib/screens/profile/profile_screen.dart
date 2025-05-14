import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/language_service.dart';
import '../../services/app_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/extensions.dart';
import '../../widgets/language_selector_widget.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String _errorMessage = '';
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemeMode();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Intentar obtener el usuario actual
      final user = await AuthService.getCurrentUser();

      if (user == null) {
        // Si no hay usuario, intentar obtenerlo desde el servicio de dashboard
        final userId = await DashboardService.getCurrentUserId();

        if (userId != null && userId.isNotEmpty) {
          final userInfo = await DashboardService.fetchUserInfo(userId);
          setState(() {
            _user = UserModel.fromJson(userInfo);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                context.tr.translate('error_loading_data') ??
                'No se pudo cargar la información del usuario';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${context.tr.translate('error_loading_data')}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadThemeMode() async {
    final mode = await AppTheme.getThemeMode();
    setState(() {
      _currentThemeMode = mode;
    });
  }

  // Método para cerrar sesión
  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr.translate('logout')),
          content: Text(
            context.tr.translate('logout_confirmation') ??
                '¿Estás seguro que deseas cerrar sesión?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(context.tr.translate('logout')),
            ),
          ],
        );
      },
    );

    // Si el usuario confirma, proceder con el cierre de sesión
    if (confirmLogout == true) {
      await AuthService.signOut(context);
      // Redirigir al usuario a la pantalla de onboarding
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.translate('profile')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile section
          _buildUserProfileSection(),

          const SizedBox(height: 24),

          // Settings section
          _buildSettingsSection(),

          const SizedBox(height: 24),

          // Actions section
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              backgroundImage: _getProfileImage(),
              child:
                  _user?.displayImage == null
                      ? Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary,
                      )
                      : null,
            ),

            const SizedBox(height: 16),

            // User name
            Text(
              _user?.name ?? context.tr.translate('demo_user'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // User email
            Text(
              _user?.email ?? 'email@example.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // Verification status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _user?.verifiedEmail == true
                      ? Icons.verified_user
                      : Icons.warning,
                  color:
                      _user?.verifiedEmail == true
                          ? Colors.green
                          : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _user?.verifiedEmail == true
                      ? context.tr.translate('email_verified')
                      : context.tr.translate('email_not_verified'),
                  style: TextStyle(
                    color:
                        _user?.verifiedEmail == true
                            ? Colors.green
                            : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Edit profile button
            OutlinedButton.icon(
              onPressed: () {
                // Implement edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr.translate('edit_profile_coming_soon'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: Text(context.tr.translate('edit_profile')),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.translate('settings'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Language configuration
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr.translate('language')),
              subtitle: Text(_getLanguageName(_user?.locale ?? 'en')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguageSelector,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(),

            // Theme configuration
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(context.tr.translate('theme')),
              subtitle: Text(_getThemeName(_currentThemeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showThemeSelector,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(),

            // Notifications configuration
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(context.tr.translate('notifications')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr.translate('notifications_coming_soon'),
                    ),
                  ),
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr.translate('actions'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Logout button
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.tr.translate('logout'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: _handleLogout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const Divider(),

            // Delete account button
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                context.tr.translate('delete_account'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                // Implement delete account
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr.translate('delete_account_coming_soon'),
                    ),
                  ),
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: LanguageSelectorWidget(
            showCloseButton: true,
            onLocaleSelected: (locale) async {
              // Save language preference and notify change
              await LanguageService.saveLanguagePreference(locale);
              languageNotifier.notifyLanguageChanged(locale);

              // Update user if available
              if (_user != null) {
                setState(() {
                  _user = _user!.updateLocale(locale);
                });
              }

              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.translate('select_theme'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: Text(context.tr.translate('theme_system')),
                onTap: () => _changeTheme(ThemeMode.system),
                selected: _currentThemeMode == ThemeMode.system,
              ),
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: Text(context.tr.translate('theme_light')),
                onTap: () => _changeTheme(ThemeMode.light),
                selected: _currentThemeMode == ThemeMode.light,
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(context.tr.translate('theme_dark')),
                onTap: () => _changeTheme(ThemeMode.dark),
                selected: _currentThemeMode == ThemeMode.dark,
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeTheme(ThemeMode mode) async {
    setState(() {
      _currentThemeMode = mode;
    });

    // Save theme preference
    await AppTheme.saveThemeMode(mode);

    // Notify theme change
    themeChangeNotifier.notifyThemeChange(mode);

    // Close modal
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  ImageProvider? _getProfileImage() {
    if (_user == null) {
      return null;
    }

    // First try to use displayImage if available
    if (_user!.displayImage != null && _user!.displayImage!.isNotEmpty) {
      // If it's a Google user, displayImage is a URL
      if (_user!.googleId != null && _user!.googleId!.isNotEmpty) {
        return NetworkImage(_user!.displayImage!);
      }
      // If it's a regular user, displayImage might be base64
      try {
        return MemoryImage(base64Decode(_user!.displayImage!));
      } catch (e) {
        print('Error decoding profile image: $e');
      }
    }

    // Then try to use picture if available (usually for Google users)
    if (_user!.picture != null && _user!.picture!.isNotEmpty) {
      return NetworkImage(_user!.picture!);
    }

    // Fallback to the default avatar
    return const AssetImage('assets/avatars/default_avatar.png');
  }

  String _getLanguageName(String languageCode) {
    final Map<String, String> languages = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ar': 'العربية',
    };

    return languages[languageCode] ?? languageCode;
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.tr.translate('theme_system');
      case ThemeMode.light:
        return context.tr.translate('theme_light');
      case ThemeMode.dark:
        return context.tr.translate('theme_dark');
      default:
        return context.tr.translate('theme_system');
    }
  }
}
