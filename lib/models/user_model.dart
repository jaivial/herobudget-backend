import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? givenName;
  final String? familyName;
  final String? picture; // URL para usuarios de Google
  final String?
  displayImage; // Base64 para usuarios regulares (profile_image_blob)
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

    // Manejar campo de imagen de perfil
    String? displayImage = json['display_image'];

    // Si no hay display_image pero hay profile_image_blob, usar eso
    if ((displayImage == null || displayImage.isEmpty) &&
        json['profile_image_blob'] != null &&
        json['profile_image_blob'].toString().isNotEmpty) {
      print('Using profile_image_blob as displayImage');
      displayImage = json['profile_image_blob'].toString();
    }

    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      givenName: json['given_name'],
      familyName: json['family_name'],
      picture: json['picture'],
      displayImage: displayImage,
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

  // Método para obtener la imagen de perfil adecuada en formato ImageProvider
  ImageProvider? getProfileImage() {
    // Diagnóstico básico
    if (displayImage != null && displayImage!.isNotEmpty) {
      final preview = displayImage!.substring(0, min(10, displayImage!.length));
      print(
        'UserModel: displayImage preview: $preview... (length: ${displayImage!.length})',
      );
    }
    if (picture != null && picture!.isNotEmpty) {
      final preview = picture!.substring(0, min(10, picture!.length));
      print(
        'UserModel: picture preview: $preview... (length: ${picture!.length})',
      );

      // Si el campo picture comienza con "/9j/" es una imagen JPEG en base64
      if (picture!.startsWith("/9j/")) {
        print('UserModel: Detected JPEG base64 in picture field');
        try {
          final bytes = base64Decode(picture!);
          print('UserModel: Successfully decoded JPEG: ${bytes.length} bytes');
          return MemoryImage(bytes);
        } catch (e) {
          print('UserModel: Failed to decode JPEG from picture: $e');
        }
      }
    }

    // Para usuarios de Google, priorizar el campo 'picture' como URL
    if (googleId != null && googleId!.isNotEmpty) {
      print('UserModel: Google user detected');
      // Primero intentar usar 'picture' como URL (si no es base64)
      if (picture != null &&
          picture!.isNotEmpty &&
          !picture!.startsWith("/9j/")) {
        try {
          print('UserModel: Trying NetworkImage with picture');
          return NetworkImage(picture!);
        } catch (e) {
          print('UserModel: Error loading Google picture: $e');
        }
      }

      // Si no hay 'picture' o falló, intentar usar 'displayImage' como URL
      if (displayImage != null && displayImage!.isNotEmpty) {
        try {
          print('UserModel: Trying NetworkImage with displayImage');
          return NetworkImage(displayImage!);
        } catch (e) {
          print('UserModel: Error loading displayImage as URL: $e');
        }
      }
    }
    // Para usuarios regulares (no Google)
    else {
      print('UserModel: Regular user detected');

      // Si el campo picture contiene una imagen base64 (comienza con /9j/), ya intentamos usarla arriba

      // Intentar usar 'displayImage' como base64 (profile_image_blob)
      if (displayImage != null && displayImage!.isNotEmpty) {
        try {
          // Intento 1: decodificar directamente como base64
          try {
            print('UserModel: Attempt 1 - Direct base64 decode');
            final bytes = base64Decode(displayImage!);
            print('UserModel: Direct decode successful: ${bytes.length} bytes');
            return MemoryImage(bytes);
          } catch (e) {
            print('UserModel: Direct base64 decode failed: $e');
          }

          // Intento 2: tratar con el prefijo WebP
          try {
            print('UserModel: Attempt 2 - WebP handling');
            String base64Image = displayImage!;
            if (!base64Image.startsWith('data:')) {
              base64Image = 'data:image/webp;base64,${base64Image}';
            }

            if (base64Image.contains(';base64,')) {
              base64Image = base64Image.split(';base64,')[1];
            }

            final bytes = base64Decode(base64Image);
            print('UserModel: WebP handling successful: ${bytes.length} bytes');
            return MemoryImage(bytes);
          } catch (e) {
            print('UserModel: WebP decode failed: $e');
          }

          // Intento 3: remover caracteres problemáticos
          try {
            print('UserModel: Attempt 3 - Cleaning string');
            String cleanBase64 = displayImage!
                .replaceAll('\n', '')
                .replaceAll('\r', '')
                .replaceAll(' ', '');

            if (cleanBase64.startsWith(RegExp(r'data:image\/[^;]+;base64,'))) {
              cleanBase64 = cleanBase64.split(';base64,')[1];
            }

            // Asegurar que la longitud sea múltiplo de 4
            while (cleanBase64.length % 4 != 0) {
              cleanBase64 += '=';
            }

            final bytes = base64Decode(cleanBase64);
            print('UserModel: Cleaning successful: ${bytes.length} bytes');
            return MemoryImage(bytes);
          } catch (e) {
            print('UserModel: Clean decode failed: $e');
          }

          // Intento 4: Manejar formato específico visto en logs
          try {
            print('UserModel: Attempt 4 - Handling specific format');
            // Verificar si comienza con "/9j/" que es típico de JPEG en base64
            if (displayImage!.startsWith("/9j/")) {
              final bytes = base64Decode(displayImage!);
              print(
                'UserModel: JPEG format handling successful: ${bytes.length} bytes',
              );
              return MemoryImage(bytes);
            }
          } catch (e) {
            print('UserModel: JPEG format handling failed: $e');
          }
        } catch (e) {
          print('UserModel: All decode attempts failed: $e');
        }
      } else {
        print('UserModel: No displayImage available');
      }

      // Si no hay 'displayImage' o falla la decodificación, intentar 'picture' como URL (no como base64)
      if (picture != null &&
          picture!.isNotEmpty &&
          !picture!.startsWith("/9j/")) {
        try {
          print('UserModel: Falling back to picture as URL');
          return NetworkImage(picture!);
        } catch (e) {
          print('UserModel: Error loading picture as URL: $e');
        }
      }
    }

    print('UserModel: Using default avatar image');
    // Fallback a la imagen de assets
    return const AssetImage('assets/avatars/default_avatar.png');
  }
}
