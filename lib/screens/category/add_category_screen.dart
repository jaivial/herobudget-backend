import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../utils/extensions.dart';
import '../../utils/string_extensions.dart';
import '../../utils/emoji_utils.dart';

class AddCategoryScreen extends StatefulWidget {
  final Function? onSuccess;
  final Category? categoryToEdit;

  const AddCategoryScreen({super.key, this.onSuccess, this.categoryToEdit});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryService = CategoryService();

  final _nameController = TextEditingController();
  String _selectedType = 'expense'; // Default type
  String _selectedEmoji = '📊'; // Default emoji
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditMode = false;
  final TextEditingController _customEmojiController = TextEditingController();

  // Lista de emojis disponibles
  final List<String> _emojis = [
    '📊',
    '💰',
    '🛒',
    '🏠',
    '🚗',
    '✈️',
    '🍔',
    '🍕',
    '👕',
    '👖',
    '👟',
    '💄',
    '💊',
    '🎬',
    '🎮',
    '📱',
    '💻',
    '📚',
    '🎓',
    '🏥',
    '🏦',
    '💼',
    '🧾',
    '🧮',
    '💸',
    '💳',
    '💵',
    '🏆',
    '🎁',
    '🎨',
    '🎭',
    '🎪',
  ];

  @override
  void initState() {
    super.initState();

    // Si estamos editando, cargar los datos de la categoría
    if (widget.categoryToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.categoryToEdit!.name;
      _selectedType = widget.categoryToEdit!.type;

      // Aplicar la utilidad de emoji para asegurar que se muestra correctamente
      _selectedEmoji = EmojiUtils.prepareForDisplay(
        widget.categoryToEdit!.emoji,
      );
      print('DEBUG - Emoji para edición: $_selectedEmoji');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customEmojiController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Normalizar el emoji antes de guardarlo
        String normalizedEmoji = _selectedEmoji;
        print(
          'DEBUG - Guardando emoji: $normalizedEmoji (longitud: ${normalizedEmoji.length})',
        );

        // IMPORTANTE: Verificar el modo de edición
        print(
          'DEBUG - Modo al guardar: ${_isEditMode ? "EDICIÓN" : "CREACIÓN"}',
        );

        // Si estamos en modo edición, mostrar el emoji original vs el nuevo
        if (_isEditMode) {
          print('DEBUG - Emoji original: ${widget.categoryToEdit!.emoji}');
          print('DEBUG - Emoji nuevo: $_selectedEmoji');
          print(
            'DEBUG - ¿Son iguales? ${widget.categoryToEdit!.emoji == _selectedEmoji}',
          );
        }

        // Solo reemplazar si está vacío
        if (normalizedEmoji.isEmpty) {
          normalizedEmoji = '📊';
          print('DEBUG - Emoji vacío, usando predeterminado');
        }

        // Create category object
        final category = Category(
          id: _isEditMode ? widget.categoryToEdit!.id : null,
          userId: _isEditMode ? widget.categoryToEdit!.userId : '',
          name: _nameController.text.trim(),
          type: _selectedType,
          emoji: normalizedEmoji,
        );

        // Log del objeto de categoría completo
        print('DEBUG - Objeto categoría a guardar: ${category.toJson()}');

        // Save or update category
        if (_isEditMode) {
          final updatedCategory = await _categoryService.updateCategory(
            category,
          );
          print('DEBUG - Categoría actualizada: ${updatedCategory.toJson()}');
        } else {
          await _categoryService.addCategory(category);
        }

        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? context.tr.translate('category_updated_successfully')
                    : context.tr.translate('category_added_successfully'),
              ),
            ),
          );

          // Call the success callback if provided
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }

          // Close the screen
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        print('DEBUG - Error al guardar categoría: $e');
      }
    }
  }

  Future<void> _openEmojiKeyboard() async {
    _customEmojiController.clear();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr.translate('select_emoji')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customEmojiController,
                  decoration: InputDecoration(
                    hintText: '😀 🎮 🚗 💰',
                    helperText: context.tr.translate('type_or_paste_emoji'),
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    // Limitar a un solo emoji
                    if (value.isNotEmpty) {
                      // Intentar extraer el primer emoji
                      final String firstEmoji = value.characters.first;
                      _customEmojiController.text = firstEmoji;
                      _customEmojiController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: firstEmoji.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Vista previa del emoji
                if (_customEmojiController.text.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _customEmojiController.text,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_customEmojiController.text.isNotEmpty) {
                    setState(() {
                      _selectedEmoji = _customEmojiController.text;

                      // Registro para depuración
                      print('DEBUG - Emoji seleccionado: $_selectedEmoji');
                      print(
                        'DEBUG - Longitud del emoji: ${_selectedEmoji.length}',
                      );

                      // Verificar si el emoji necesitará codificación
                      bool needsEncoding = EmojiUtils.containsEmoji(
                        _selectedEmoji,
                      );
                      print(
                        'DEBUG - ¿El emoji necesita codificación? $needsEncoding',
                      );
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: Text(context.tr.translate('select')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? context.tr.translate('edit_category')
              : context.tr.translate('add_category'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.tr.translate('category_name'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr.translate('enter_category_name');
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Category type selector
                Text(
                  context.tr.translate('category_type'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'income',
                        context.tr.translate('income'),
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeButton(
                        'expense',
                        context.tr.translate('expense'),
                        Icons.shopping_cart,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Emoji selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr.translate('select_emoji'),
                      style: const TextStyle(fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openEmojiKeyboard,
                      icon: const Icon(Icons.emoji_emotions),
                      label: Text(context.tr.translate('custom_emoji')),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _emojis.map((emoji) {
                          return _buildEmojiButton(emoji);
                        }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Selected emoji indicator
                Row(
                  children: [
                    Text(
                      context.tr.translate('selected_emoji'),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCategory,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                              _isEditMode
                                  ? context.tr.translate('update')
                                  : context.tr.translate('save'),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;

    // Capitalizar la primera letra del label
    final String displayLabel = label.capitalize();

    // Iconos mejorados y más descriptivos
    IconData betterIcon;
    List<Color> gradientColors;

    if (type == 'income') {
      betterIcon =
          Icons.account_balance_wallet; // Icono de billetera para ingresos
      gradientColors = [Colors.green.shade400, Colors.green.shade600];
    } else {
      betterIcon = Icons.shopping_cart; // Icono de carrito para gastos
      gradientColors = [Colors.red.shade400, Colors.red.shade600];
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  )
                  : null,
          color: isSelected ? null : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: isSelected ? 0 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.2)
                        : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                betterIcon,
                color: isSelected ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    final isSelected = _selectedEmoji == emoji;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmoji = emoji;
          print('DEBUG - Emoji seleccionado de predefinidos: $_selectedEmoji');
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
