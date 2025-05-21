class Invoice {
  final int id;
  final String name;
  final double amount;
  final String dueDate;
  final bool paid;
  final bool overdue;
  final int overdueDays;
  final bool recurring;
  final String category;
  final String icon;
  final String? description;
  final String paymentMethod;
  final String? regularity;
  final String? startDate;
  final String? createdAt;
  final String? updatedAt;

  Invoice({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.paid,
    required this.overdue,
    required this.overdueDays,
    required this.recurring,
    required this.category,
    required this.icon,
    this.description,
    required this.paymentMethod,
    this.regularity,
    this.startDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      dueDate: json['due_date'] ?? '',
      paid: json['paid'] ?? false,
      overdue: json['overdue'] ?? false,
      overdueDays: json['overdue_days'] ?? 0,
      recurring: json['recurring'] ?? false,
      category: json['category'] ?? '',
      icon: json['icon'] ?? 'receipt_long',
      description: json['description'],
      paymentMethod: json['payment_method'] ?? 'bank',
      regularity: json['regularity'],
      startDate: json['start_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Convertir a Bill compatible con el API
  Map<String, dynamic> toBillJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'due_date': dueDate,
      'paid': paid,
      'overdue': overdue,
      'overdue_days': overdueDays,
      'recurring': recurring,
      'category': category,
      'icon': icon,
      'description': description,
      'payment_method': paymentMethod,
      'regularity': regularity,
      'start_date': startDate,
    };
  }

  // Crear una copia de la factura con algunos cambios
  Invoice copyWith({
    int? id,
    String? name,
    double? amount,
    String? dueDate,
    bool? paid,
    bool? overdue,
    int? overdueDays,
    bool? recurring,
    String? category,
    String? icon,
    String? description,
    String? paymentMethod,
    String? regularity,
    String? startDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paid: paid ?? this.paid,
      overdue: overdue ?? this.overdue,
      overdueDays: overdueDays ?? this.overdueDays,
      recurring: recurring ?? this.recurring,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      regularity: regularity ?? this.regularity,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Método para marcar como pagada
  Invoice markAsPaid() {
    return copyWith(paid: true, updatedAt: DateTime.now().toIso8601String());
  }

  // Método para calcular cuándo será el próximo pago según regularidad
  String calculateNextPaymentDate() {
    if (!recurring || regularity == null) {
      return dueDate;
    }

    // Parsear fecha de pago actual
    final DateTime currentDueDate = DateTime.parse(dueDate);

    // Calcular próxima fecha según regularidad
    switch (regularity) {
      case 'daily':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + 1,
        ).toIso8601String().split('T')[0];
      case 'weekly':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + 7,
        ).toIso8601String().split('T')[0];
      case 'monthly':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + 1,
          currentDueDate.day,
        ).toIso8601String().split('T')[0];
      case 'quarterly':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + 3,
          currentDueDate.day,
        ).toIso8601String().split('T')[0];
      case 'semiannual':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + 6,
          currentDueDate.day,
        ).toIso8601String().split('T')[0];
      case 'annual':
        return DateTime(
          currentDueDate.year + 1,
          currentDueDate.month,
          currentDueDate.day,
        ).toIso8601String().split('T')[0];
      default:
        return dueDate;
    }
  }
}
