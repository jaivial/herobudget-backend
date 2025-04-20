import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _detectCurrentLocale();
  }

  Future<void> _detectCurrentLocale() async {
    final locale = await LanguageService.getLanguagePreference();
    if (locale != null && locale.isNotEmpty) {
      setState(() {
        _selectedLocale = locale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = LanguageService.getSupportedLanguagesList();
    final translate = AppLocalizations.of(context).translate;

    if (widget.isFullScreen) {
      return Scaffold(body: _buildLanguageList(languages, translate));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  translate('select_language'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.showCloseButton)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildLanguageList(languages, translate),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(
    List<Map<String, String>> languages,
    String Function(String) translate,
  ) {
    return ListView.builder(
      itemCount: languages.length,
      itemBuilder: (context, index) {
        final language = languages[index];
        final isSelected = language['code'] == _selectedLocale;

        return InkWell(
          onTap: () async {
            setState(() {
              _selectedLocale = language['code']!;
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
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(language['flag']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    language['name']!,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                      color:
                          isSelected ? AppTheme.primaryColor : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
