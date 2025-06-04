import 'invoice_model.dart';

/// Modelo que representa una factura recurrente con información específica del período
/// Cada instancia representa un mes específico de pago de una factura recurrente
class RecurringInvoice {
  final Invoice baseInvoice;
  final String yearMonth; // Formato YYYY-MM - mes específico de este pago
  final String specificDueDate; // Fecha de vencimiento específica para este mes
  final bool paidForThisPeriod; // Estado de pago específico para este mes

  RecurringInvoice({
    required this.baseInvoice,
    required this.yearMonth,
    required this.specificDueDate,
    required this.paidForThisPeriod,
  });

  /// Factory constructor desde JSON del backend (bills con información de período)
  factory RecurringInvoice.fromJson(
    Map<String, dynamic> json,
    String yearMonth,
  ) {
    // Crear la factura base desde el JSON
    final baseInvoice = Invoice.fromJson(json);

    // La fecha específica se calcula en el backend y viene en due_date cuando se especifica yearMonth
    final specificDueDate = json['due_date'] ?? baseInvoice.dueDate;

    // El estado de pago específico del período viene en el campo 'paid'
    final paidForThisPeriod = json['paid'] ?? false;

    return RecurringInvoice(
      baseInvoice: baseInvoice,
      yearMonth: yearMonth,
      specificDueDate: specificDueDate,
      paidForThisPeriod: paidForThisPeriod,
    );
  }

  /// Factory constructor desde una Invoice base para un período específico
  factory RecurringInvoice.fromInvoice(
    Invoice invoice,
    String yearMonth,
    int paymentDay, {
    bool paid = false,
  }) {
    // Calcular la fecha específica para este mes
    final yearMonthParts = yearMonth.split('-');
    final year = int.parse(yearMonthParts[0]);
    final month = int.parse(yearMonthParts[1]);

    // Asegurar que el día de pago no exceda los días del mes
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final adjustedPaymentDay =
        paymentDay <= lastDayOfMonth ? paymentDay : lastDayOfMonth;

    final specificDate = DateTime(year, month, adjustedPaymentDay);
    final specificDueDate =
        '${specificDate.year.toString().padLeft(4, '0')}-${specificDate.month.toString().padLeft(2, '0')}-${specificDate.day.toString().padLeft(2, '0')}';

    return RecurringInvoice(
      baseInvoice: invoice,
      yearMonth: yearMonth,
      specificDueDate: specificDueDate,
      paidForThisPeriod: paid,
    );
  }

  // Getters para acceso fácil a propiedades de la factura base
  int get id => baseInvoice.id;
  String get name => baseInvoice.name;
  double get amount => baseInvoice.amount;
  String get category => baseInvoice.category;
  String get icon => baseInvoice.icon;
  String get paymentMethod => baseInvoice.paymentMethod;
  String? get description => baseInvoice.description;
  bool get recurring => baseInvoice.recurring;

  // Propiedades específicas del período
  String get dueDate => specificDueDate;
  bool get paid => paidForThisPeriod;

  // Calculadas basadas en la fecha específica
  bool get overdue {
    final today = DateTime.now();
    final due = DateTime.parse(specificDueDate);
    return !paidForThisPeriod && due.isBefore(today);
  }

  int get overdueDays {
    if (!overdue) return 0;
    final today = DateTime.now();
    final due = DateTime.parse(specificDueDate);
    return today.difference(due).inDays;
  }

  /// Convierte a JSON para compatibilidad con Invoice
  Map<String, dynamic> toJson() {
    final json = baseInvoice.toBillJson();
    json['due_date'] = specificDueDate;
    json['paid'] = paidForThisPeriod;
    json['overdue'] = overdue;
    json['overdue_days'] = overdueDays;
    json['year_month'] = yearMonth;
    return json;
  }

  /// Crea una copia con modificaciones
  RecurringInvoice copyWith({
    Invoice? baseInvoice,
    String? yearMonth,
    String? specificDueDate,
    bool? paidForThisPeriod,
  }) {
    return RecurringInvoice(
      baseInvoice: baseInvoice ?? this.baseInvoice,
      yearMonth: yearMonth ?? this.yearMonth,
      specificDueDate: specificDueDate ?? this.specificDueDate,
      paidForThisPeriod: paidForThisPeriod ?? this.paidForThisPeriod,
    );
  }

  @override
  String toString() {
    return 'RecurringInvoice(id: $id, name: $name, yearMonth: $yearMonth, paid: $paidForThisPeriod)';
  }
}
