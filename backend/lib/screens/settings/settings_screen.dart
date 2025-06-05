import 'package:flutter/material.dart';
import '../../widgets/localized_text.dart';
import '../../utils/extensions.dart';
import '../../examples/language_selector_test.dart';
import '../../widgets/language_selector_modal.dart';
import '../../services/language_service.dart';
import '../../utils/locale_util.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrentLocale();
  }

  Future<void> _loadCurrentLocale() async {
    final locale = await LocaleUtil.getCurrentLocale();
    setState(() {
      _selectedLanguage = locale.languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Language'),
            subtitle: Text(
              LocaleUtil.getDisplayName(Locale(_selectedLanguage)),
            ),
            onTap: () {
              _showLanguageSelectionDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: LocaleUtil.getSupportedLocales().length,
              itemBuilder: (context, index) {
                final locale = LocaleUtil.getSupportedLocales()[index];
                final isSelected = locale.languageCode == _selectedLanguage;

                return ListTile(
                  title: Text(LocaleUtil.getDisplayName(locale)),
                  trailing:
                      isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                  onTap: () async {
                    await LocaleUtil.saveLocale(locale);
                    setState(() {
                      _selectedLanguage = locale.languageCode;
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
