import 'package:flutter/material.dart';
import 'dart:async';
import '../services/language_service.dart';
import '../services/app_service.dart';
import '../utils/app_localizations.dart';
import 'language_selector_modal.dart';
import '../main.dart';

class LanguageSelectorButton extends StatefulWidget {
  const LanguageSelectorButton({Key? key}) : super(key: key);

  @override
  State<LanguageSelectorButton> createState() => _LanguageSelectorButtonState();
}

class _LanguageSelectorButtonState extends State<LanguageSelectorButton> {
  String _currentLocale = 'en';
  String _flagEmoji = '🇺🇸';
  StreamSubscription? _languageChangeSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocale();

    // Subscribe to language changes
    _languageChangeSubscription = languageChangeNotifier.languageChangeStream
        .listen((locale) {
          if (mounted) {
            setState(() {
              _currentLocale = locale;
              _flagEmoji = LanguageService.getLanguageFlag(locale);
            });
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentLocale();
  }

  @override
  void dispose() {
    _languageChangeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocale() async {
    final locale = await LanguageService.getLanguagePreference();
    final localeString = locale ?? 'en';
    final flag = LanguageService.getLanguageFlag(localeString);

    if (mounted) {
      setState(() {
        _currentLocale = localeString;
        _flagEmoji = flag;
      });
    }
  }

  void _showLanguageSelector(BuildContext context) async {
    final selectedLocale = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const LanguageSelectorModal();
      },
    );

    if (selectedLocale != null && selectedLocale != _currentLocale) {
      // No need to call notifyLanguageChange here, the modal already does it
      if (mounted) {
        setState(() {
          _currentLocale = selectedLocale;
          _flagEmoji = LanguageService.getLanguageFlag(selectedLocale);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = _currentLocale.toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => _showLanguageSelector(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_flagEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                languageCode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
