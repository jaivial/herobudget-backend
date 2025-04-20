import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/app_service.dart';
import '../utils/app_localizations.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class LanguageSelectorModal extends StatefulWidget {
  const LanguageSelectorModal({Key? key}) : super(key: key);

  @override
  State<LanguageSelectorModal> createState() => _LanguageSelectorModalState();
}

class _LanguageSelectorModalState extends State<LanguageSelectorModal> {
  String _currentLocale = 'en';
  List<Map<String, String>> _supportedLanguages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final locale = await LanguageService.getLanguagePreference();
      final localeString = locale ?? 'en';
      final languages = LanguageService.getSupportedLanguagesList();

      if (mounted) {
        setState(() {
          _currentLocale = localeString;
          _supportedLanguages = languages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing language selector data: $e');
      // Even on error, ensure we're not stuck in loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Set default values if needed
          if (_supportedLanguages.isEmpty) {
            _supportedLanguages = [
              {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
            ];
          }
        });
      }
    }
  }

  // Helper method to preload a language file
  Future<void> _preloadTranslationFile(String languageCode) async {
    try {
      final String jsonFileName = 'assets/l10n/$languageCode.json';
      await rootBundle.loadString(jsonFileName);
      print('Preloaded translation file: $jsonFileName');
    } catch (e) {
      print('Error preloading translation file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.translate('select_language'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Divider(),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final language = _supportedLanguages[index];
                    final isSelected = language['code'] == _currentLocale;

                    return ListTile(
                      leading: Text(
                        language['flag'] ?? '',
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(language['name'] ?? ''),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                      selected: isSelected,
                      onTap: () async {
                        if (language['code'] != null) {
                          final selectedLocale = language['code']!;

                          // Mark as selected in UI immediately - don't show loading spinner
                          setState(() {
                            _currentLocale = selectedLocale;
                          });

                          try {
                            // Update app locale first for immediate feedback
                            AppService.changeAppLocale(context, selectedLocale);

                            // Now do these operations in the background
                            Future.microtask(() async {
                              try {
                                // Preload the translation file in the background
                                await _preloadTranslationFile(selectedLocale);

                                // Save language preference locally
                                await LanguageService.saveLanguagePreference(
                                  selectedLocale,
                                );
                              } catch (e) {
                                print(
                                  'Background language operations error: $e',
                                );
                              }
                            });

                            // Close the modal immediately
                            if (context.mounted) {
                              Navigator.of(context).pop(selectedLocale);
                            }
                          } catch (e) {
                            print('Error during language change: $e');
                            // Still attempt to close the dialog even on error
                            if (context.mounted) {
                              Navigator.of(context).pop(selectedLocale);
                            }
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
