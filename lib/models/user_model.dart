import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

/// Modelo que representa a un usuario en la aplicación.
///
/// Contiene toda la información relevante del usuario,
/// como su ID, email, nombre, información de perfil, etc.
class UserModel {
  final String id;
  final String? googleId;
  final String email;
  final String name;
  final String? givenName;
  final String? familyName;
  final String? picture;
  final String? displayImage;
  final String locale;
  final bool verifiedEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? password;
  final String? profileImageBlob;

  /// Constructor principal que inicializa un UserModel con todos sus campos.
  const UserModel({
    required this.id,
    this.googleId,
    required this.email,
    required this.name,
    this.givenName,
    this.familyName,
    this.picture,
    this.displayImage,
    this.profileImageBlob,
    required this.locale,
    required this.verifiedEmail,
    required this.createdAt,
    required this.updatedAt,
    this.password,
  });

  /// Crea una copia de este UserModel con los campos especificados modificados
  UserModel copyWith({
    String? id,
    String? googleId,
    String? email,
    String? name,
    String? givenName,
    String? familyName,
    String? picture,
    String? displayImage,
    String? profileImageBlob,
    String? locale,
    bool? verifiedEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      name: name ?? this.name,
      givenName: givenName ?? this.givenName,
      familyName: familyName ?? this.familyName,
      picture: picture ?? this.picture,
      displayImage: displayImage ?? this.displayImage,
      profileImageBlob: profileImageBlob ?? this.profileImageBlob,
      locale: locale ?? this.locale,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      password: password ?? this.password,
    );
  }

  /// Crea una instancia de UserModel a partir de un mapa JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Convertir las fechas de creación y actualización
    DateTime parsedCreatedAt;
    DateTime parsedUpdatedAt;

    try {
      parsedCreatedAt = DateTime.parse(json['created_at'] as String);
      parsedUpdatedAt = DateTime.parse(json['updated_at'] as String);
    } catch (e) {
      if (kDebugMode) {
        print('Error al parsear fecha: $e');
        print('Valor created_at: ${json['created_at']}');
        print('Valor updated_at: ${json['updated_at']}');
      }
      // Si hay error, usar fecha actual
      final now = DateTime.now();
      parsedCreatedAt = now;
      parsedUpdatedAt = now;
    }

    // Depuración para entender qué campos relacionados con imágenes están presentes
    if (kDebugMode) {
      if (json.containsKey('display_image')) {
        final displayImage = json['display_image'] as String?;
        if (displayImage != null && displayImage.isNotEmpty) {
          print(
            'UserModel.fromJson: display_image presente (${displayImage.length} bytes)',
          );
          if (displayImage.length > 20) {
            print(
              'UserModel.fromJson: display_image primeros 20 chars: ${displayImage.substring(0, 20)}',
            );
          }
        } else {
          print('UserModel.fromJson: display_image está vacío o nulo');
        }
      }

      if (json.containsKey('picture')) {
        final picture = json['picture'] as String?;
        if (picture != null && picture.isNotEmpty) {
          print(
            'UserModel.fromJson: picture presente (${picture.length} bytes)',
          );
          if (picture.length > 20) {
            print(
              'UserModel.fromJson: picture primeros 20 chars: ${picture.substring(0, 20)}',
            );
          }
        } else {
          print('UserModel.fromJson: picture está vacío o nulo');
        }
      }

      if (json.containsKey('profile_image_blob')) {
        final profileImageBlob = json['profile_image_blob'] as String?;
        if (profileImageBlob != null && profileImageBlob.isNotEmpty) {
          print(
            'UserModel.fromJson: profile_image_blob presente (${profileImageBlob.length} bytes)',
          );
          if (profileImageBlob.length > 20) {
            print(
              'UserModel.fromJson: profile_image_blob primeros 20 chars: ${profileImageBlob.substring(0, 20)}',
            );
          }
        } else {
          print('UserModel.fromJson: profile_image_blob está vacío o nulo');
        }
      }
    }

    return UserModel(
      id: json['id'].toString(),
      googleId: json['google_id'] as String?,
      email: json['email'] as String,
      name: json['name'] as String,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      picture: json['picture'] as String?,
      displayImage: json['display_image'] as String?,
      profileImageBlob: json['profile_image_blob'] as String?,
      locale: json['locale'] as String? ?? 'en',
      verifiedEmail: json['verified_email'] as bool? ?? false,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      password: json['password'] as String?,
    );
  }

  /// Convierte el modelo a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (googleId != null) 'google_id': googleId,
      'email': email,
      'name': name,
      if (givenName != null) 'given_name': givenName,
      if (familyName != null) 'family_name': familyName,
      if (picture != null) 'picture': picture,
      if (displayImage != null) 'display_image': displayImage,
      if (profileImageBlob != null) 'profile_image_blob': profileImageBlob,
      'locale': locale,
      'verified_email': verifiedEmail,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (password != null) 'password': password,
    };
  }

  /// Devuelve una copia del modelo con el idioma preferido actualizado
  UserModel updateLocale(String newLocale) {
    return copyWith(locale: newLocale, updatedAt: DateTime.now());
  }

  // Método para obtener la imagen de perfil adecuada en formato ImageProvider
  ImageProvider? getProfileImage() {
    // Diagnóstico básico
    if (kDebugMode) {
      if (displayImage != null && displayImage!.isNotEmpty) {
        print(
          'UserModel.getProfileImage: displayImage presente (${displayImage!.length} bytes)',
        );
        final preview = displayImage!.substring(
          0,
          min(20, displayImage!.length),
        );
        print('UserModel.getProfileImage: displayImage preview: $preview...');
      }

      if (profileImageBlob != null && profileImageBlob!.isNotEmpty) {
        print(
          'UserModel.getProfileImage: profileImageBlob presente (${profileImageBlob!.length} bytes)',
        );
        final preview = profileImageBlob!.substring(
          0,
          min(20, profileImageBlob!.length),
        );
        print(
          'UserModel.getProfileImage: profileImageBlob preview: $preview...',
        );
      }

      if (picture != null && picture!.isNotEmpty) {
        print(
          'UserModel.getProfileImage: picture presente (${picture!.length} bytes)',
        );
        final preview = picture!.substring(0, min(20, picture!.length));
        print('UserModel.getProfileImage: picture preview: $preview...');
      }
    }

    // Procesamiento de imagen priorizado

    // 1. Primero verificar el campo profileImageBlob (imagen almacenada en la base de datos)
    if (profileImageBlob != null && profileImageBlob!.isNotEmpty) {
      try {
        if (kDebugMode) {
          print(
            'UserModel.getProfileImage: Usando profileImageBlob como fuente de imagen',
          );
        }

        // Verificar si contiene el prefijo data:image
        if (profileImageBlob!.contains(';base64,')) {
          final base64Data = profileImageBlob!.split(';base64,')[1];
          return MemoryImage(base64Decode(base64Data));
        } else {
          // Intentar decodificar directamente
          final imageBytes = base64Decode(profileImageBlob!);
          return MemoryImage(imageBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'UserModel.getProfileImage: Error decodificando profileImageBlob: $e',
          );
        }
      }
    }

    // 2. Verificar el campo displayImage (podría ser una URL o un base64)
    if (displayImage != null && displayImage!.isNotEmpty) {
      try {
        if (kDebugMode) {
          print(
            'UserModel.getProfileImage: Usando displayImage como fuente de imagen',
          );
        }

        // Si parece una URL
        if (displayImage!.startsWith('http')) {
          return NetworkImage(displayImage!);
        }

        // Si parece base64
        if (displayImage!.contains(';base64,') ||
            displayImage!.startsWith('/9j/') || // JPEG
            displayImage!.startsWith('iVBOR')) {
          // PNG

          String base64Data = displayImage!;
          // Extraer los datos reales si tiene prefijo
          if (displayImage!.contains(';base64,')) {
            base64Data = displayImage!.split(';base64,')[1];
          }

          // Decodificar
          final imageBytes = base64Decode(base64Data);
          return MemoryImage(imageBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'UserModel.getProfileImage: Error decodificando displayImage: $e',
          );
        }
      }
    }

    // 3. Comprobar si el campo picture contiene una URL
    if (picture != null && picture!.isNotEmpty) {
      try {
        if (kDebugMode) {
          print(
            'UserModel.getProfileImage: Usando picture como fuente de imagen',
          );
        }

        // Si parece ser una URL
        if (picture!.startsWith('http')) {
          return NetworkImage(picture!);
        }

        // Si parece ser base64
        if (picture!.contains(';base64,') ||
            picture!.startsWith('/9j/') || // JPEG
            picture!.startsWith('iVBOR')) {
          // PNG

          String base64Data = picture!;
          // Extraer los datos reales si tiene prefijo
          if (picture!.contains(';base64,')) {
            base64Data = picture!.split(';base64,')[1];
          }

          // Decodificar
          final imageBytes = base64Decode(base64Data);
          return MemoryImage(imageBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print('UserModel.getProfileImage: Error decodificando picture: $e');
        }
      }
    }

    // Si no se pudo obtener imagen de ninguna fuente
    if (kDebugMode) {
      print('UserModel.getProfileImage: No se encontró imagen válida');
    }
    return null;
  }

  // Métodos de ayuda para información de localización
  String getFlag() {
    return '${getCountryCode(locale)}';
  }

  String getCountryCode(String locale) {
    final Map<String, String> languageToCountry = {
      'en': 'US',
      'es': 'ES',
      'fr': 'FR',
      'de': 'DE',
      'it': 'IT',
      'pt': 'PT',
      'ru': 'RU',
      'zh': 'CN',
      'ja': 'JP',
      'ar': 'SA',
    };
    return languageToCountry[locale] ?? 'US';
  }
}
