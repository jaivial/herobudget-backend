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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      givenName: json['given_name'],
      familyName: json['family_name'],
      picture: json['picture'],
      displayImage: json['display_image'],
      googleId: json['google_id'],
      locale: json['locale'] ?? 'en-US',
      verifiedEmail: json['verified_email'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
    };
  }
}
