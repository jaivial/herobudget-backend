# Hero Budget Localization System

This document describes the implementation of the multilingual support system in Hero Budget.

## Overview

Hero Budget uses a simplified localization approach based on the Flutter Localizations package. This system supports multiple languages and allows users to dynamically change the app's language at runtime.

## Supported Languages

The application currently supports the following languages:

- English (en)
- Spanish (es)
- French (fr)
- Italian (it)
- German (de)
- Greek (el)
- Dutch (nl)
- Danish (da)
- Russian (ru)
- Portuguese (pt)
- Chinese (zh)
- Japanese (ja)
- Hindi (hi)

## File Structure

- **Translation files** are stored in JSON format in the `assets/l10n/` directory
- Each language has its own file named with its language code (e.g., `en.json`, `es.json`, `fr.json`)
- The translation files contain key-value pairs where the key is a unique identifier and the value is the translated text

## Implementation Details

### Core Components

1. **AppLocalizations** (`lib/utils/app_localizations.dart`)
   - Loads and manages translations
   - Provides the `translate(key)` method to retrieve translated text
   - Has a static `of(context)` method to access the current instance

2. **AppLocalizationsDelegate**
   - A delegate that creates the AppLocalizations instance
   - Handles locale changes

3. **LanguageService** (`lib/services/language_service.dart`)
   - Manages language preferences
   - Provides methods to get and set the current language
   - Persists language preferences to local storage and syncs with the server

### Usage

#### Setting Up

The MaterialApp widget is configured with the necessary localization settings:

```dart
MaterialApp(
  locale: _appLocale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  // ...
)
```

#### Accessing Translations

There are two ways to access translations in your widgets:

1. **Using the extension method:**

```dart
// In any widget
Text(context.tr.translate('welcome'))
```

2. **Using the AppLocalizations directly:**

```dart
final translate = AppLocalizations.of(context).translate;
Text(translate('welcome'))
```

#### Changing Language

To change the application language:

```dart
// Change to Spanish
await LanguageService.saveLanguagePreference('es');

// Force UI refresh
MyApp.refreshLocale(context, 'es');
```

## Adding a New Language

To add a new language:

1. Create a new JSON file in `assets/l10n/` with the language code (e.g., `de.json`)
2. Translate all the keys from `en.json` to the new language
3. Add the new locale to the `supportedLocales` list in `AppLocalizations`
4. Add the language details to the `supportedLanguages` map in `LanguageService`
5. Add the flag emoji to the `getLanguageFlag` method in `LanguageService`

## Best Practices

1. Always use translation keys instead of hardcoded strings
2. Keep translation keys simple and descriptive
3. Organize translation keys logically by feature or screen
4. Test the app with different languages to ensure layouts adapt properly
5. Handle RTL languages appropriately when supporting them 