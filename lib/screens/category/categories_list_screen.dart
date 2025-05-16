import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/string_extensions.dart';
import 'add_category_screen.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final _categoryService = CategoryService();
  final _searchController = TextEditingController();

  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  String? _errorMessage;
  String?
  _selectedTypeFilter; // null means all categories, 'income' or 'expense' for filtering

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoryService.fetchCategories(
        type: _selectedTypeFilter,
      );

      setState(() {
        _categories = categories;
        _applySearchFilter(_searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearchFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_categories);
      } else {
        _filteredCategories =
            _categories.where((category) {
              return category.name.toLowerCase().contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _categoryService.deleteCategory(category.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.translate('category_deleted_successfully')),
          action: SnackBarAction(
            label: context.tr.translate('undo'),
            onPressed: () async {
              // Re-create the deleted category
              await _categoryService.addCategory(
                Category(
                  userId: category.userId,
                  name: category.name,
                  type: category.type,
                  emoji: category.emoji,
                ),
              );

              // Refresh the list
              _loadCategories();
            },
          ),
        ),
      );

      // Refresh the list
      _loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr.translate('error_deleting_category')}: ${e.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _editCategory(Category category) async {
    // Navigate to the edit category screen (reusing AddCategoryScreen with modifications)
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AddCategoryScreen(
              onSuccess: _loadCategories,
              categoryToEdit: category,
            ),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  void _navigateToAddCategory() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(onSuccess: _loadCategories),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.translate('categories'))),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.tr.translate('search_categories'),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _applySearchFilter,
                ),

                const SizedBox(height: 16),

                // Filter buttons
                Row(
                  children: [
                    Text(
                      context.tr.translate('filter_by_type'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    _buildFilterChip(
                      label: context.tr.translate('all'),
                      selected: _selectedTypeFilter == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedTypeFilter = null;
                          _loadCategories();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: context.tr.translate('income'),
                      selected: _selectedTypeFilter == 'income',
                      onSelected: (_) {
                        setState(() {
                          _selectedTypeFilter = 'income';
                          _loadCategories();
                        });
                      },
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: context.tr.translate('expense'),
                      selected: _selectedTypeFilter == 'expense',
                      onSelected: (_) {
                        setState(() {
                          _selectedTypeFilter = 'expense';
                          _loadCategories();
                        });
                      },
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredCategories.isEmpty
                    ? Center(
                      child: Text(
                        context.tr.translate('no_categories_found'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = _filteredCategories[index];
                        return _buildCategoryItem(category);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    // Capitalizar la primera letra del label
    final String displayLabel = label.capitalize();

    return FilterChip(
      label: Text(
        displayLabel,
        style: TextStyle(color: selected ? Colors.white : null),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: color != null ? color.withOpacity(0.1) : null,
      selectedColor: color ?? Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildCategoryItem(Category category) {
    // Determine text and icon color based on category type
    final Color typeColor =
        category.type == 'income' ? Colors.green : Colors.red;
    final IconData typeIcon =
        category.type == 'income' ? Icons.trending_up : Icons.trending_down;

    return Dismissible(
      key: Key('category_${category.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr.translate('confirm_delete')),
                content: Text(
                  '${context.tr.translate('delete_category_confirmation')}: ${category.name}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.tr.translate('cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      context.tr.translate('delete'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        _deleteCategory(category);
      },
      child: ListTile(
        leading: _buildEmojiContainer(category.emoji, typeColor),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(typeIcon, size: 16, color: typeColor),
            const SizedBox(width: 4),
            Text(
              // Usar el texto capitalizado
              category.type == 'income'
                  ? context.tr.translate('income').capitalize()
                  : context.tr.translate('expense').capitalize(),
              style: TextStyle(color: typeColor),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editCategory(category),
        ),
        onTap: () => _editCategory(category),
      ),
    );
  }

  // Widget personalizado para mostrar emojis
  Widget _buildEmojiContainer(String emoji, Color bgColor) {
    // Depurar: Imprimir la representación del emoji
    print('DEBUG - Emoji original: $emoji');

    // Asegurarse de que usamos el emoji correcto
    String displayEmoji = emoji;

    // Solo reemplazar si está vacío o es "ð" (carácter corrupto)
    if (emoji.isEmpty || emoji == "ð" || emoji == "ð ") {
      // Situación de error - emoji no válido
      displayEmoji = '📊'; // Emoji predeterminado
      print('DEBUG - Emoji inválido detectado, usando predeterminado');
    }

    print('DEBUG - Emoji a mostrar: $displayEmoji');

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          displayEmoji,
          style: const TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
