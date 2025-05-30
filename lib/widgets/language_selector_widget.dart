import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../utils/extensions.dart';

class LanguageSelectorWidget extends StatefulWidget {
  final Function(String)? onLocaleSelected;
  final bool showCloseButton;
  final bool isFullScreen;

  const LanguageSelectorWidget({
    super.key,
    this.onLocaleSelected,
    this.showCloseButton = false,
    this.isFullScreen = false,
  });

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  String _selectedLocale = 'en';
  List<Map<String, String>> _availableLanguages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _detectCurrentLocale();
    await _loadAvailableLanguages();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _detectCurrentLocale() async {
    final locale = await LanguageService.getLanguagePreference();
    if (locale != null && locale.isNotEmpty) {
      setState(() {
        _selectedLocale = locale;
      });
    }
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final allLanguages = LanguageService.getSupportedLanguagesList();
      final List<Map<String, String>> availableLanguages = [];

      // Check each language to see if its translation file exists
      for (final language in allLanguages) {
        final code = language['code'];
        if (code != null) {
          try {
            // Try to load the file to check if it exists
            await rootBundle.load('assets/l10n/$code.json');

            // If we get here, the file exists
            availableLanguages.add(language);
          } catch (e) {
            // File doesn't exist, skip this language
            print('Translation file for $code not found. Skipping.');
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableLanguages = availableLanguages;

          // If no languages were found (unlikely), at least include English
          if (_availableLanguages.isEmpty) {
            for (final language in allLanguages) {
              if (language['code'] == 'en') {
                _availableLanguages.add(language);
                break;
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error loading available languages: $e');
      // Fallback to the full list from the service
      if (mounted) {
        setState(() {
          _availableLanguages = LanguageService.getSupportedLanguagesList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final translate = context.tr.translate;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.isFullScreen) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isDarkMode
                      ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D3A)]
                      : [Colors.white, const Color(0xFFF5F5F7)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppTheme.primaryColor.withOpacity(0.2)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language,
                          size: 28,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        translate('select_language'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    translate('select_language_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDarkMode
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(child: _buildLanguageList(translate)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isDarkMode
                  ? [const Color(0xFF1E1E2E), const Color(0xFF2D2D3A)]
                  : [Colors.white, const Color(0xFFF5F5F7)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator at top of bottom sheet
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Encabezado mejorado para el selector
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: Row(
              children: [
                // Icono identificativo
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Título más prominente
                Expanded(
                  child: Text(
                    translate('select_language'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                // Botón de cierre mejorado
                if (widget.showCloseButton)
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
              ],
            ),
          ),

          // Subtítulo explicativo
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Text(
              translate('select_language_desc'),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),

          const Divider(height: 1),

          // Lista de idiomas
          Expanded(child: _buildLanguageList(translate)),
        ],
      ),
    );
  }

  Widget _buildLanguageList(Function(String) translate) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Colors.transparent;

    return Container(
      color: backgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: _availableLanguages.length,
        itemBuilder: (context, index) {
          final language = _availableLanguages[index];
          final isSelected = language['code'] == _selectedLocale;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? (isDarkMode
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.08))
                      : (isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.white),
              borderRadius: BorderRadius.circular(16),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              border: Border.all(
                color:
                    isSelected
                        ? AppTheme.primaryColor
                        : isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final selectedCode = language['code'];
                if (selectedCode == null) return;

                setState(() {
                  _selectedLocale = selectedCode;
                });

                // Save the selected locale
                await LanguageService.saveLanguagePreference(_selectedLocale);

                // Notify parent widget if callback is provided
                if (widget.onLocaleSelected != null) {
                  widget.onLocaleSelected!(_selectedLocale);
                }

                // Close dialog or screen if it's shown as a dialog
                if (widget.showCloseButton && widget.isFullScreen == false) {
                  Navigator.of(context).pop(_selectedLocale);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    // Bandera del idioma (con fondo decorativo)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          language['flag']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Nombre del idioma (con estilo mejorado)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language['name']!,
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 18,
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : (isDarkMode
                                          ? Colors.white
                                          : Colors.black87),
                            ),
                          ),
                          // Nombre nativo del idioma cuando está disponible
                          if (language['nativeName'] != null &&
                              language['nativeName'] != language['name'])
                            Text(
                              language['nativeName']!,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Check mark mejorado
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
