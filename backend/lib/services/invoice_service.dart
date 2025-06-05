import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../models/invoice_model.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/icon_utils.dart';
import '../models/recurring_invoice_model.dart';

/// Servicio para gestionar las facturas (invoices) utilizando la API de bills_management
class InvoiceService {
  static String get baseUrl => ApiConfig.billsManagementUrl;

  /// Obtiene la lista de facturas del usuario
  Future<List<Invoice>> fetchInvoices() async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fullUrl = ApiConfig.billsFetchEndpoint + '?user_id=$userId';

      // Realizar la petición HTTP
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];

          // Handle case when there are no invoices (data is null or empty)
          if (data == null || (data is List && data.isEmpty)) {
            print('✅ No invoices found - returning empty list');
            return <Invoice>[];
          }

          // The 'data' field contains the array of invoices
          if (data is List) {
            return data.map((invoice) => Invoice.fromJson(invoice)).toList();
          } else {
            throw Exception('Invoices data is not an array');
          }
        } else {
          throw Exception(
            'Failed to fetch invoices: ${responseData['message']}',
          );
        }
      } else {
        throw Exception('Error fetching invoices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchInvoices: $e');
      throw Exception('Error fetching invoices: $e');
    }
  }

  /// Añade una nueva factura
  Future<bool> addInvoice({
    required String name,
    required double amount,
    String? dueDate,
    required String startDate,
    required int paymentDay,
    required int durationMonths,
    required String category,
    required String paymentMethod,
    required bool recurring,
    String? description,
    String? regularity,
  }) async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Obtener el emoji de la categoría seleccionada
      String icon = await _getCategoryEmoji(userId, category);

      // Crear un mapa con los datos de la factura
      final Map<String, dynamic> invoiceData = {
        'user_id': userId,
        'name': name,
        'amount': amount,
        'start_date': startDate,
        'payment_day': paymentDay,
        'duration_months': durationMonths,
        'regularity': regularity ?? 'monthly',
        'category': category,
        'icon': icon,
        'recurring': recurring,
        'paid': false,
        'overdue': false,
        'overdue_days': 0,
        'payment_method': paymentMethod,
      };

      // Mantener dueDate para compatibilidad si se proporciona
      if (dueDate != null && dueDate.isNotEmpty) {
        invoiceData['due_date'] = dueDate;
      } else {
        // Si no se proporciona dueDate, usar startDate como fallback
        invoiceData['due_date'] = startDate;
      }

      // Añadir campos opcionales si no son nulos
      if (description != null && description.isNotEmpty) {
        invoiceData['description'] = description;
      }

      final fullUrl = ApiConfig.billsAddEndpoint;

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invoiceData),
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error adding invoice: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addInvoice: $e');
      return false;
    }
  }

  /// Marca una factura como pagada
  Future<bool> payInvoice(
    int invoiceId,
    String paymentMethod, {
    String? yearMonth, // Nuevo: mes específico a pagar (YYYY-MM)
    String? description, // Nuevo: descripción adicional
  }) async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Si no se proporciona yearMonth, usar el mes actual como valor por defecto
      final String effectiveYearMonth =
          yearMonth ??
          DateTime.now().toIso8601String().substring(0, 7); // Formato YYYY-MM

      // Crear el cuerpo de la solicitud
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'bill_id': invoiceId,
        'payment_method': paymentMethod, // 'cash' o 'bank'
        'year_month': effectiveYearMonth, // Campo requerido por el backend
      };

      // Añadir descripción si se proporciona
      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse(ApiConfig.billsPayEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error paying invoice: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in payInvoice: $e');
      return false;
    }
  }

  /// Actualiza los detalles de una factura
  Future<bool> updateInvoice({
    required int invoiceId,
    required String name,
    required double amount,
    required String dueDate,
    required String category,
    required bool recurring,
    String? description,
    String? paymentMethod,
    String? regularity,
    String? startDate,
  }) async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Crear un mapa con los datos de la factura
      final Map<String, dynamic> invoiceData = {
        'user_id': userId,
        'bill_id': invoiceId,
        'name': name,
        'amount': amount,
        'due_date': dueDate,
        'category': category,
        'icon': await _getCategoryEmoji(userId, category),
        'recurring': recurring,
      };

      // Añadir campos opcionales si no son nulos
      if (description != null && description.isNotEmpty) {
        invoiceData['description'] = description;
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        invoiceData['payment_method'] = paymentMethod;
      }
      if (startDate != null && startDate.isNotEmpty) {
        invoiceData['start_date'] = startDate;
      }
      if (regularity != null && regularity.isNotEmpty) {
        invoiceData['regularity'] = regularity;
      }

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse(ApiConfig.billsUpdateEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invoiceData),
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error updating invoice: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateInvoice: $e');
      return false;
    }
  }

  /// Elimina una factura
  Future<bool> deleteInvoice(int invoiceId) async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse(ApiConfig.billsDeleteEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'bill_id': invoiceId}),
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Error deleting invoice: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteInvoice: $e');
      return false;
    }
  }

  /// Obtiene las próximas facturas
  Future<List<Invoice>> fetchUpcomingInvoices() async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Realizar la petición HTTP
      final response = await http.get(
        Uri.parse(ApiConfig.billsUpcomingEndpoint + '?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Verificar si la respuesta es exitosa
      if (response.statusCode == 200) {
        // Parsear la respuesta JSON
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.map((invoice) => Invoice.fromJson(invoice)).toList();
        } else {
          throw Exception(
            'Failed to fetch upcoming invoices: ${responseData['message']}',
          );
        }
      } else {
        throw Exception(
          'Error fetching upcoming invoices: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchUpcomingInvoices: $e');
      throw Exception('Error fetching upcoming invoices: $e');
    }
  }

  /// Obtiene el emoji de una categoría específica
  Future<String> _getCategoryEmoji(String userId, String categoryName) async {
    try {
      final categoryService = CategoryService();
      final categories = await categoryService.fetchCategories(type: 'expense');

      // Buscar la categoría por nombre
      final category = categories.firstWhere(
        (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
        orElse:
            () => Category(
              id: 0,
              name: '',
              emoji: '',
              type: 'expense',
              userId: userId,
            ),
      );

      // Si encontramos la categoría y tiene emoji, usarlo
      if (category.emoji.isNotEmpty) {
        return category.emoji;
      }

      // Si no, usar IconUtils para obtener un emoji apropiado
      return IconUtils.getAppropriateEmoji(
        categoryName: categoryName,
        iconName: 'receipt_long',
      );
    } catch (e) {
      print('Error getting category emoji: $e');
      // Fallback: usar IconUtils
      return IconUtils.getAppropriateEmoji(
        categoryName: categoryName,
        iconName: 'receipt_long',
      );
    }
  }

  /// Obtiene facturas no pagadas para un período específico usando bill_payments
  Future<List<RecurringInvoice>> fetchUnpaidInvoicesForPeriod(
    String yearMonth,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fullUrl =
          '${ApiConfig.billsFetchEndpoint}?user_id=$userId&period=monthly&date=$yearMonth-01';

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];

          if (data == null || (data is List && data.isEmpty)) {
            return <RecurringInvoice>[];
          }

          if (data is List) {
            // Filtrar solo las no pagadas para este período
            return data
                .where((invoiceData) => invoiceData['paid'] == false)
                .map(
                  (invoiceData) =>
                      RecurringInvoice.fromJson(invoiceData, yearMonth),
                )
                .toList();
          } else {
            throw Exception('Invoice data is not an array');
          }
        } else {
          throw Exception(
            'Failed to fetch invoices: ${responseData['message']}',
          );
        }
      } else {
        throw Exception('Error fetching invoices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchUnpaidInvoicesForPeriod: $e');
      throw Exception('Error fetching invoices for period: $e');
    }
  }

  /// Obtiene facturas no pagadas para un rango de fechas (varios meses)
  Future<List<RecurringInvoice>> fetchUnpaidInvoicesForDateRange({
    DateTime? startDate,
    int monthsAhead = 6,
  }) async {
    final start = startDate ?? DateTime.now();
    final List<RecurringInvoice> allInvoices = [];

    // Generar lista de meses a consultar
    for (int i = 0; i < monthsAhead; i++) {
      final monthDate = DateTime(start.year, start.month + i, 1);
      final yearMonth =
          '${monthDate.year.toString().padLeft(4, '0')}-${monthDate.month.toString().padLeft(2, '0')}';

      try {
        final monthlyInvoices = await fetchUnpaidInvoicesForPeriod(yearMonth);
        allInvoices.addAll(monthlyInvoices);
      } catch (e) {
        print('Error fetching invoices for month $yearMonth: $e');
        // Continuar con el siguiente mes si hay error
      }
    }

    return allInvoices;
  }

  /// Paga una factura recurrente para un período específico
  Future<bool> payRecurringInvoice(
    RecurringInvoice recurringInvoice,
    String paymentMethod, {
    String? description,
  }) async {
    return await payInvoice(
      recurringInvoice.id,
      paymentMethod,
      yearMonth: recurringInvoice.yearMonth,
      description: description,
    );
  }
}
