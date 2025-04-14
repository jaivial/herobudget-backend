import 'package:flutter/material.dart';
import '../utils/extensions.dart';
import '../services/language_service.dart';

/// A widget that demonstrates how to use translations in the app
class LocalizedTextExample extends StatelessWidget {
  const LocalizedTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr.translate('welcome'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.translate('select_language'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Show some common UI elements with translations
              ElevatedButton(
                onPressed: () {},
                child: Text(context.tr.translate('continue')),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {},
                child: Text(context.tr.translate('cancel')),
              ),
              const SizedBox(height: 16),
              // Show the current locale
              FutureBuilder<String?>(
                future: LanguageService.getLanguagePreference(),
                builder: (context, snapshot) {
                  String localeInfo = "Current locale: ";
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    localeInfo += "Loading...";
                  } else if (snapshot.hasError) {
                    localeInfo += "Error";
                  } else if (snapshot.hasData && snapshot.data != null) {
                    localeInfo += snapshot.data!;
                  } else {
                    localeInfo += "Unknown";
                  }
                  return Text(localeInfo);
                },
              ),
              const SizedBox(height: 8),
              Text('Available translations:'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  _buildTranslatedChip(context, 'dashboard'),
                  _buildTranslatedChip(context, 'expenses'),
                  _buildTranslatedChip(context, 'income'),
                  _buildTranslatedChip(context, 'budget'),
                  _buildTranslatedChip(context, 'settings'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslatedChip(BuildContext context, String key) {
    return Chip(label: Text(context.tr.translate(key)));
  }
}
