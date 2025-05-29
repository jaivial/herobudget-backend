import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/dashboard_model.dart';
import '../models/invoice_model.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/icon_utils.dart';

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

      final fullUrl = '$baseUrl?user_id=$userId';

      // Realizar la petición HTTP
      final response = await http.get(
        Uri.parse(fullUrl),
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
    required String dueDate,
    required String category,
    required String paymentMethod,
    required bool recurring,
    String? description,
    String? startDate,
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
        'due_date': dueDate,
        'category': category,
        'icon': icon,
        'recurring': recurring,
        'paid': false,
        'overdue': false,
        'overdue_days': 0,
        'payment_method': paymentMethod,
      };

      // Añadir campos opcionales si no son nulos
      if (description != null && description.isNotEmpty) {
        invoiceData['description'] = description;
      }
      if (startDate != null && startDate.isNotEmpty) {
        invoiceData['start_date'] = startDate;
      }
      if (regularity != null && regularity.isNotEmpty) {
        invoiceData['regularity'] = regularity;
      }

      final fullUrl = '$baseUrl/add';

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
  Future<bool> payInvoice(int invoiceId, String paymentMethod) async {
    try {
      // Obtener el ID de usuario desde SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Realizar la petición HTTP
      final response = await http.post(
        Uri.parse('$baseUrl/pay'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'bill_id': invoiceId,
          'payment_method': paymentMethod, // 'cash' o 'bank'
        }),
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
        Uri.parse('$baseUrl/update'),
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
        Uri.parse('$baseUrl/delete'),
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
        Uri.parse('$baseUrl/upcoming?user_id=$userId'),
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
}
