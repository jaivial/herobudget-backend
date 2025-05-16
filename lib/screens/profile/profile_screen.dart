import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/language_service.dart';
import '../../services/app_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/extensions.dart';
import '../../widgets/language_selector_widget.dart';
import '../onboarding/onboarding_screen.dart';
import 'edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Método para verificar el formato de las imágenes
  void _debugImageFormats() {
    if (_user == null) return;

    print('===== DEBUG IMAGE FORMATS =====');

    // Verificar campos de imagen
    if (_user!.displayImage != null) {
      print('displayImage length: ${_user!.displayImage!.length}');

      // Mostrar solo los primeros 10 caracteres
      if (_user!.displayImage!.isNotEmpty) {
        final preview = _user!.displayImage!.substring(
          0,
          min(10, _user!.displayImage!.length),
        );
        print('displayImage preview: $preview...');
      }

      // Verificar si parece base64 válido
      bool seemsValidBase64 = RegExp(
        r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$',
      ).hasMatch(_user!.displayImage!);
      print('Seems valid base64: $seemsValidBase64');

      // Verificar si tiene prefijo
      if (_user!.displayImage!.startsWith('data:')) {
        print('displayImage has data: prefix');
      }

      // Intentar decodificar
      try {
        final bytes = base64Decode(_user!.displayImage!);
        print('Successfully decoded as raw base64: ${bytes.length} bytes');
      } catch (e) {
        print('Raw base64 decode failed: $e');

        // Intentar limpiar y decodificar
        try {
          String cleaned = _user!.displayImage!
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .replaceAll(' ', '');

          if (cleaned.startsWith(RegExp(r'data:image\/[^;]+;base64,'))) {
            cleaned = cleaned.split(';base64,')[1];
          }

          // Asegurar que la longitud sea múltiplo de 4
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
      // Mostrar solo los primeros 10 caracteres
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
                  _user?.displayImage == null && _user?.picture == null
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
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to edit profile screen
                _navigateToEditProfile();
              },
              icon: const Icon(Icons.edit),
              label: Text(
                context.tr.translate('edit_profile'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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

            // Fix emojis tool
            ListTile(
              leading: const Icon(Icons.emoji_emotions, color: Colors.amber),
              title: const Text('Reparar Emojis'),
              subtitle: const Text(
                'Solucionar problemas con emojis en categorías',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pushNamed('/fix_emojis');
              },
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

            // Test image update button (only in debug mode)
            if (kDebugMode)
              ListTile(
                leading: Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Test Profile Image Update',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: _testProfileImageUpdate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

            if (kDebugMode) const Divider(),

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

                // Verificar que la actualización se hizo correctamente
                print('Idioma actualizado en usuario: ${_user!.locale}');
              } else {
                print('No hay usuario para actualizar el idioma');
                // Si no hay usuario, recargar los datos
                _loadUserData();
              }

              Navigator.pop(context);

              // Forzar una actualización de la UI para reflejar el cambio de idioma
              setState(() {});
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

    // Usar el método centralizado en UserModel
    return _user!.getProfileImage();
  }

  String _getLanguageName(String languageCode) {
    // Usar el servicio de idioma para obtener el nombre correcto del idioma
    final supportedLanguages = LanguageService.getSupportedLanguagesList();
    for (final language in supportedLanguages) {
      if (language['code'] == languageCode) {
        // Devuelve el nombre del idioma sin el paréntesis y el idioma original
        final fullName = language['name'] ?? languageCode;
        // Si el nombre contiene espacios (como "Spanish (Español)"), toma el nombre original
        if (fullName.contains('(')) {
          // Extrae el texto entre paréntesis
          final match = RegExp(r'\((.*?)\)').firstMatch(fullName);
          if (match != null && match.groupCount >= 1) {
            return match.group(1)!;
          }
        }
        return fullName;
      }
    }
    return languageCode;
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

  // Método para navegar a la pantalla de edición de perfil
  Future<void> _navigateToEditProfile() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.translate('error_loading_user_data') ??
                'Error: No se pudo cargar la información del usuario',
          ),
        ),
      );
      return;
    }

    // Navegar directamente a la pantalla de edición de perfil sin verificar el servicio
    if (context.mounted) {
      final updatedUser = await Navigator.of(context).push<UserModel>(
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(user: _user!),
        ),
      );

      // Si el usuario actualizó su perfil, actualizar la UI
      if (updatedUser != null) {
        print('Perfil actualizado recibido: ${updatedUser.name}');

        // Verificar específicamente si la imagen fue actualizada
        if (updatedUser.displayImage != null &&
            updatedUser.displayImage!.isNotEmpty) {
          print('Nueva imagen detectada en el perfil actualizado');
        }

        setState(() {
          _user = updatedUser;
        });
      }
    }
  }

  // Método para probar la actualización de la imagen de perfil
  Future<void> _testProfileImageUpdate() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario para probar')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear una imagen de prueba simple (un cuadrado de color)
      String testImageBase64 = await _generateTestImageBase64();

      // Mostrar diagnóstico completo del usuario actual
      print('=========== DIAGNÓSTICO DE USUARIO ACTUAL ===========');
      print('ID: ${_user!.id}');
      print('Email: ${_user!.email}');
      print('Nombre: ${_user!.name}');
      if (_user!.displayImage != null) {
        print(
          'displayImage presente con longitud: ${_user!.displayImage!.length}',
        );
        print(
          'displayImage primeros bytes: ${_user!.displayImage!.substring(0, min(20, _user!.displayImage!.length))}',
        );
      } else {
        print('displayImage es NULL');
      }
      if (_user!.picture != null) {
        print('picture presente con longitud: ${_user!.picture!.length}');
        print(
          'picture primeros bytes: ${_user!.picture!.substring(0, min(20, _user!.picture!.length))}',
        );
      } else {
        print('picture es NULL');
      }
      print('==================================================');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ejecutando prueba de imagen...')),
      );

      // Ejecutar la prueba de actualización de imagen
      await ProfileService.testProfileImageUpdate(
        userId: int.parse(_user!.id),
        testImageBase64: testImageBase64,
      );

      // Realizar una actualización de imagen real y verificar que se haya actualizado correctamente
      print('=========== REALIZANDO ACTUALIZACIÓN REAL ===========');
      final updatedUser = await ProfileService.updateProfile(
        userId: int.parse(_user!.id),
        name: _user!.name, // mantener el mismo nombre
        profileImageBase64: testImageBase64, // usar la imagen de prueba
      );

      print('Usuario actualizado:');
      print('ID: ${updatedUser.id}');
      print('Email: ${updatedUser.email}');
      print('Nombre: ${updatedUser.name}');
      if (updatedUser.displayImage != null) {
        print(
          'displayImage presente con longitud: ${updatedUser.displayImage!.length}',
        );
        print(
          'displayImage primeros bytes: ${updatedUser.displayImage!.substring(0, min(20, updatedUser.displayImage!.length))}',
        );
      } else {
        print('displayImage es NULL');
      }
      if (updatedUser.picture != null) {
        print('picture presente con longitud: ${updatedUser.picture!.length}');
        print(
          'picture primeros bytes: ${updatedUser.picture!.substring(0, min(20, updatedUser.picture!.length))}',
        );
      } else {
        print('picture es NULL');
      }

      // Verificar si la imagen se actualizó correctamente
      final bool imageUpdateSuccessful =
          updatedUser.displayImage != null ||
          (updatedUser.picture != null &&
              updatedUser.picture!.startsWith('/9j/'));

      print(
        'Resultado de la actualización de imagen: ${imageUpdateSuccessful ? "EXITOSO" : "FALLIDO"}',
      );
      print('==================================================');

      // Actualizar el usuario en la UI
      setState(() {
        _user = updatedUser;
      });

      // Recargar los datos del usuario para confirmar que los cambios persisten
      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imageUpdateSuccessful
                ? 'Prueba completada con éxito. La imagen se actualizó correctamente.'
                : 'Prueba completada. La imagen no se actualizó correctamente. Verificar logs.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error en la prueba: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Genera una imagen de prueba como base64
  Future<String> _generateTestImageBase64() async {
    // Simular una imagen pequeña (1x1 pixel) para pruebas
    final List<int> bytes = [
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      8,
      6,
      0,
      0,
      0,
      31,
      21,
      196,
      137,
      0,
      0,
      0,
      13,
      73,
      68,
      65,
      84,
      120,
      1,
      99,
      100,
      96,
      0,
      0,
      0,
      6,
      0,
      3,
      118,
      149,
      185,
      234,
      0,
      0,
      0,
      0,
      73,
      69,
      78,
      68,
      174,
      66,
      96,
      130,
    ]; // PNG 1x1 rojo

    // Obtener imagen desde las preferencias compartidas (si existe)
    final prefs = await SharedPreferences.getInstance();
    String? savedImage = prefs.getString('test_profile_image');

    if (savedImage != null && savedImage.isNotEmpty) {
      print('Usando imagen de prueba guardada');
      return savedImage;
    }

    final String base64Image = base64Encode(bytes);

    // Guardar para uso futuro
    await prefs.setString('test_profile_image', base64Image);

    return base64Image;
  }
}
