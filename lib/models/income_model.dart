class Income {
  final int? id;
  final String userId;
  final double amount;
  final String date;
  final String category;
  final String paymentMethod;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  Income({
    this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      userId: json['user_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? '',
      category: json['category'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      description: json['description'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'amount': amount,
      'date': date,
      'category': category,
      'payment_method': paymentMethod,
    };

    // Add optional fields only if they are not null
    if (id != null) data['id'] = id;
    if (description != null && description!.isNotEmpty)
      data['description'] = description;

    return data;
  }

  // Create a copy of the income with modified fields
  Income copyWith({
    int? id,
    String? userId,
    double? amount,
    String? date,
    String? category,
    String? paymentMethod,
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
