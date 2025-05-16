import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../models/category_model.dart';
import '../../utils/emoji_utils.dart';

class FixEmojiScreen extends StatefulWidget {
  const FixEmojiScreen({super.key});

  @override
  State<FixEmojiScreen> createState() => _FixEmojiScreenState();
}

class _FixEmojiScreenState extends State<FixEmojiScreen> {
  bool _isLoading = false;
  List<Category> _categories = [];
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _logs.add("Cargando categorías...");
    });

    try {
      // Obtener el ID de usuario
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        _logs.add("Error: Usuario no autenticado");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Construir URL con parámetros
      var url = '${ApiConfig.categoriesEndpoint}?user_id=$userId';
      _logs.add("URL de consulta: $url");

      // Realizar la solicitud HTTP
      final response = await http.get(Uri.parse(url));
      _logs.add(
        "Respuesta (${response.statusCode}): ${response.body.substring(0, 100)}...",
      );

      // Verificar el código de estado
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          // Manejar caso donde data es null
          if (jsonData['data'] == null) {
            _logs.add("No hay categorías para arreglar");
            setState(() {
              _isLoading = false;
              _categories = [];
            });
            return;
          }

          final categoriesJson = jsonData['data'] as List;
          final categories =
              categoriesJson.map((json) => Category.fromJson(json)).toList();

          _logs.add("Se encontraron ${categories.length} categorías");
          setState(() {
            _categories = categories;
            _isLoading = false;
          });
        } else {
          _logs.add("Error: ${jsonData['message'] ?? 'Desconocido'}");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _logs.add("Error HTTP: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _logs.add("Excepción: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fixEmojis() async {
    setState(() {
      _isLoading = true;
      _logs.add("Comenzando el proceso de corrección de emojis...");
    });

    try {
      // Obtener el ID de usuario
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        _logs.add("Error: Usuario no autenticado");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Lista para contabilizar resultados
      int success = 0;
      int failures = 0;

      // Procesar cada categoría
      for (var category in _categories) {
        _logs.add(
          "Procesando categoría: ${category.name} (ID: ${category.id})",
        );

        // Asignar un emoji predeterminado basado en el ID
        // para tener variedad y asegurar que se guardan correctamente
        final defaultEmojis = [
          '📊',
          '💰',
          '🛒',
          '🏠',
          '🚗',
          '✈️',
          '🍔',
          '🍕',
          '💼',
          '💸',
          '💳',
          '💵',
        ];
        final index = (category.id ?? 1) % defaultEmojis.length;
        final newEmoji = defaultEmojis[index];

        _logs.add("Emoji asignado: $newEmoji");

        // Asegurar que el emoji esté correctamente codificado
        final encodedEmoji = EmojiUtils.prepareForStorage(newEmoji);
        _logs.add("Emoji codificado: $encodedEmoji");

        // Preparar la solicitud
        final requestBody = {
          'user_id': userId,
          'category_id': category.id,
          'name': category.name,
          'type': category.type,
          'emoji': encodedEmoji,
        };

        // URL para actualizar
        final url = '${ApiConfig.categoriesEndpoint}/update';
        _logs.add("URL de actualización: $url");

        try {
          // Realizar la solicitud HTTP
          final response = await http.post(
            Uri.parse(url),
            body: json.encode(requestBody),
            headers: {'Content-Type': 'application/json'},
          );

          _logs.add("Respuesta (${response.statusCode})");

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            if (jsonData['success'] == true) {
              _logs.add("✅ Categoría ${category.id} actualizada con éxito");
              success++;
            } else {
              _logs.add("❌ Error al actualizar: ${jsonData['message']}");
              failures++;
            }
          } else {
            _logs.add("❌ Error HTTP: ${response.statusCode}");
            failures++;
          }
        } catch (e) {
          _logs.add("❌ Excepción al actualizar: $e");
          failures++;
        }

        // Pequeña pausa para no sobrecargar el servidor
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _logs.add("===== RESUMEN =====");
      _logs.add("Total categorías: ${_categories.length}");
      _logs.add("Actualizadas con éxito: $success");
      _logs.add("Fallidas: $failures");

      // Refrescar las categorías para ver los cambios
      await _fetchCategories();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logs.add("❌ Error general: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reparar Emojis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta herramienta reparará los emojis corruptos en la base de datos.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // Información de categorías
            Text(
              'Categorías encontradas: ${_categories.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Lista de categorías
            if (_categories.isNotEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      title: Text(category.name),
                      subtitle: Text(
                        'Tipo: ${category.type}, ID: ${category.id}',
                      ),
                      trailing: Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Botón para iniciar la reparación
            ElevatedButton(
              onPressed: _isLoading ? null : _fixEmojis,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Reparar Emojis'),
            ),

            const SizedBox(height: 16),

            // Logs de la operación
            Text('Logs:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[_logs.length -
                          1 -
                          index], // Mostrar más recientes primero
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _logs[_logs.length - 1 - index].contains('Error') ||
                                    _logs[_logs.length - 1 - index].contains(
                                      '❌',
                                    )
                                ? Colors.red
                                : _logs[_logs.length - 1 - index].contains('✅')
                                ? Colors.green
                                : null,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
