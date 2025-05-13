class UserModel {
  final String id;
  final String email;
  final String name;
  final String? givenName;
  final String? familyName;
  final String? picture;
  final String? displayImage;
  final String locale;
  final bool verifiedEmail;
  final String? createdAt;
  final String? updatedAt;
  final String? googleId;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.givenName,
    this.familyName,
    this.picture,
    this.displayImage,
    this.googleId,
    required this.locale,
    required this.verifiedEmail,
    this.createdAt,
    this.updatedAt,
    this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String locale = json['locale'] ?? 'en';

    // Asegurar que solo usamos el código de idioma sin región
    if (locale.contains('-') || locale.contains('_')) {
      locale = locale.split(RegExp(r'[-_]'))[0];
    }

    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      givenName: json['given_name'],
      familyName: json['family_name'],
      picture: json['picture'],
      displayImage: json['display_image'],
      googleId: json['google_id'],
      locale: locale,
      verifiedEmail: json['verified_email'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      preferences:
          json['preferences'] is Map
              ? Map<String, dynamic>.from(json['preferences'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'given_name': givenName,
      'family_name': familyName,
      'picture': picture,
      'display_image': displayImage,
      'google_id': googleId,
      'locale': locale,
      'verified_email': verifiedEmail,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'preferences': preferences,
    };
  }

  // Método para crear una copia del modelo con campos actualizados
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? givenName,
    String? familyName,
    String? picture,
    String? displayImage,
    String? googleId,
    String? locale,
    bool? verifiedEmail,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      givenName: givenName ?? this.givenName,
      familyName: familyName ?? this.familyName,
      picture: picture ?? this.picture,
      displayImage: displayImage ?? this.displayImage,
      googleId: googleId ?? this.googleId,
      locale: locale ?? this.locale,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // Método para actualizar preferencias específicas sin modificar todo el mapa
  UserModel updatePreference(String key, dynamic value) {
    final updatedPreferences = Map<String, dynamic>.from(preferences ?? {});
    updatedPreferences[key] = value;

    return copyWith(preferences: updatedPreferences);
  }

  // Método específico para actualizar el idioma y mantener coherencia
  UserModel updateLocale(String newLocale) {
    // Asegurar que solo usamos el código de idioma sin región
    if (newLocale.contains('-') || newLocale.contains('_')) {
      newLocale = newLocale.split(RegExp(r'[-_]'))[0];
    }

    // Actualizar preferencia de idioma
    final updatedPreferences = Map<String, dynamic>.from(preferences ?? {});
    updatedPreferences['language'] = newLocale;

    return copyWith(locale: newLocale, preferences: updatedPreferences);
  }

  // Métodos de ayuda para información de localización
  bool get isRTL {
    // Idiomas de derecha a izquierda
    const List<String> rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(locale);
  }

  String get languageCode => locale;

  // Método para obtener el código de país basado en el idioma
  String get countryCode {
    // Mapeamos idiomas a códigos de país para regionalización
    const Map<String, String> languageToCountry = {
      'en': 'US',
      'es': 'ES',
      'fr': 'FR',
      'it': 'IT',
      'de': 'DE',
      'gsw': 'CH',
      'el': 'GR',
      'nl': 'NL',
      'da': 'DK',
      'ru': 'RU',
      'pt': 'PT',
      'zh': 'CN',
      'ja': 'JP',
      'hi': 'IN',
    };

    return languageToCountry[locale] ?? 'US';
  }
}
