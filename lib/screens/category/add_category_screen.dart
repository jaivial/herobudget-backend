import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../utils/app_localizations.dart';

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
    if (widget.categoryToEdit != null) {
      _isEditMode = true;
      _nameController.text = widget.categoryToEdit!.name;
      _selectedType = widget.categoryToEdit!.type;
      _selectedEmoji = widget.categoryToEdit!.emoji;
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
        // Create category object
        final category = Category(
          id: _isEditMode ? widget.categoryToEdit!.id : null,
          userId: _isEditMode ? widget.categoryToEdit!.userId : '',
          name: _nameController.text.trim(),
          type: _selectedType,
          emoji: _selectedEmoji,
        );

        // Save or update category
        if (_isEditMode) {
          await _categoryService.updateCategory(category);
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
            content: TextField(
              controller: _customEmojiController,
              decoration: InputDecoration(hintText: '😀 🎮 🚗 💰'),
              autofocus: true,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _customEmojiController.text = value[0];
                }
              },
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
                      _selectedEmoji = _customEmojiController.text[0];
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
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeButton(
                        'expense',
                        context.tr.translate('expense'),
                        Icons.trending_down,
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
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
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
      ),
    );
  }
}
