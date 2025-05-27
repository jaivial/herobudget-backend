import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/extensions.dart';
import 'components/user_profile_section.dart';
import 'components/settings_section.dart';
import 'components/actions_section.dart';

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

  void _debugImageFormats() {
    if (_user == null) return;
    print('===== DEBUG IMAGE FORMATS =====');
    if (_user!.displayImage != null) {
      print('displayImage length: ${_user!.displayImage!.length}');
      if (_user!.displayImage!.isNotEmpty) {
        final preview = _user!.displayImage!.substring(
          0,
          min(10, _user!.displayImage!.length),
        );
        print('displayImage preview: $preview...');
      }
      bool seemsValidBase64 = RegExp(
        r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$',
      ).hasMatch(_user!.displayImage!);
      print('Seems valid base64: $seemsValidBase64');
      if (_user!.displayImage!.startsWith('data:')) {
        print('displayImage has data: prefix');
      }
      try {
        final bytes = base64Decode(_user!.displayImage!);
        print('Successfully decoded as raw base64: ${bytes.length} bytes');
      } catch (e) {
        print('Raw base64 decode failed: $e');
        try {
          String cleaned = _user!.displayImage!
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .replaceAll(' ', '');
          if (cleaned.startsWith(RegExp(r'data:image\/[^;]+;base64,'))) {
            cleaned = cleaned.split(';base64,')[1];
          }
          while (cleaned.length % 4 != 0) {
            cleaned += '=';
          }
          final bytes = base64Decode(cleaned);
          print('Successfully decoded after cleaning: ${bytes.length} bytes');
        } catch (e) {
          print('Cleaned base64 decode failed: $e');
        }
      }
    } else {
      print('displayImage is null');
    }
    if (_user!.picture != null) {
      if (_user!.picture!.isNotEmpty) {
        final preview = _user!.picture!.substring(
          0,
          min(10, _user!.picture!.length),
        );
        print('picture preview: $preview...');
      }
      print('picture exists and seems to be a URL');
    } else {
      print('picture is null');
    }
    print('===== END DEBUG =====');
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Intentar obtener el usuario actual
      final user = await AuthService.getCurrentUser();

      // Obtener el idioma preferido actual
      final currentLocale =
          await LanguageService.getLanguagePreference() ?? 'en';

      if (user == null) {
        // Si no hay usuario, intentar obtenerlo desde el servicio de dashboard
        final userId = await DashboardService.getCurrentUserId();

        if (userId != null && userId.isNotEmpty) {
          final userInfo = await DashboardService.fetchUserInfo(userId);
          final loadedUser = UserModel.fromJson(userInfo);

          // Asegurarse de que el idioma del usuario coincida con el idioma preferido actual
          final updatedUser =
              (loadedUser.locale != currentLocale)
                  ? loadedUser.updateLocale(currentLocale)
                  : loadedUser;

          setState(() {
            _user = updatedUser;
            _isLoading = false;
          });
          _debugImageFormats();
        } else {
          setState(() {
            _errorMessage =
                context.tr.translate('error_loading_data') ??
                'No se pudo cargar la información del usuario';
            _isLoading = false;
          });
        }
      } else {
        // Asegurarse de que el idioma del usuario coincida con el idioma preferido actual
        final updatedUser =
            (user.locale != currentLocale)
                ? user.updateLocale(currentLocale)
                : user;

        setState(() {
          _user = updatedUser;
          _isLoading = false;
        });
        _debugImageFormats();
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
          UserProfileSection(user: _user, onProfileUpdated: _loadUserData),

          const SizedBox(height: 24),

          // Settings section
          SettingsSection(
            user: _user,
            currentThemeMode: _currentThemeMode,
            onUserUpdated: _loadUserData,
          ),

          const SizedBox(height: 24),

          // Actions section
          const ActionsSection(),
        ],
      ),
    );
  }
}
