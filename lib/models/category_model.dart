class Category {
  final int? id;
  final String userId;
  final String name;
  final String type; // "income" o "expense"
  final String emoji;
  final String? createdAt;
  final String? updatedAt;

  Category({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.emoji,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      emoji: json['emoji'] ?? '📊',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'name': name,
      'type': type,
      'emoji': emoji,
    };

    // Add optional fields only if they are not null
    if (id != null) data['id'] = id;

    return data;
  }

  // Create a copy of the category with modified fields
  Category copyWith({
    int? id,
    String? userId,
    String? name,
    String? type,
    String? emoji,
    String? createdAt,
    String? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
