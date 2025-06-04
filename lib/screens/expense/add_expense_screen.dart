import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../services/expense_service.dart';
import '../../services/category_service.dart';
import '../../utils/extensions.dart';
import '../../utils/currency_utils.dart';
import '../category/add_category_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  final Function? onSuccess;

  const AddExpenseScreen({super.key, this.onSuccess});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseService = ExpenseService();
  final _categoryService = CategoryService();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = ''; // Will be set from loaded categories
  String _selectedPaymentMethod = 'cash'; // Default payment method
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  // Lista de categorías cargadas desde la base de datos
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      // Cargar solo categorías de tipo gasto
      final categories = await _categoryService.fetchCategories(
        type: 'expense',
      );
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;

        // Seleccionar la primera categoría si hay alguna disponible
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first.name;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 1),
      ), // Allow today and yesterday
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Parse amount from text field
        final amount = double.parse(
          _amountController.text.replaceAll(',', '.'),
        );

        // Create expense object
        final expense = Expense(
          userId: '', // Will be filled in by the service
          amount: amount,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          description: _descriptionController.text,
        );

        // Save expense
        await _expenseService.addExpense(expense);

        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.translate('expense_added_successfully')),
            ),
          );

          // Call the success callback if provided
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }

          // Close the screen
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currencySymbol = CurrencyUtils.getCurrencySymbolForLocale(
      Localizations.localeOf(context),
    );

    // Check if current locale uses Euro currency
    final bool isEuroLocale =
        [
          'es',
          'de',
          'fr',
          'it',
          'pt',
          'nl',
          'el',
        ].contains(Localizations.localeOf(context).languageCode) &&
        currencySymbol == '€';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.translate('add_expense')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body:
          _isLoadingCategories
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      context.tr.translate('loading_categories'),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount field with decoration
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: context.tr.translate('amount'),
                              // For Euro: show as suffix (value€), for others: show as prefix (€value)
                              prefixText: isEuroLocale ? null : currencySymbol,
                              suffixText: isEuroLocale ? currencySymbol : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.5)
                                      : Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              labelStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                              ),
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr.translate('enter_amount');
                              }
                              try {
                                final amount = double.parse(
                                  value.replaceAll(',', '.'),
                                );
                                if (amount <= 0) {
                                  return context.tr.translate(
                                    'amount_must_be_positive',
                                  );
                                }
                              } catch (e) {
                                return context.tr.translate(
                                  'enter_valid_amount',
                                );
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date selector
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: context.tr.translate('date'),
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.9)
                                        : null,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Category dropdown with add button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.tr.translate('category'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    // Navigate to the add category screen
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AddCategoryScreen(
                                              onSuccess: () {
                                                // This will be called when a category is successfully added
                                              },
                                            ),
                                      ),
                                    );

                                    // If the user added a category successfully, reload the categories
                                    if (result == true) {
                                      await _loadCategories();
                                    }
                                  },
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.9)
                                            : null,
                                  ),
                                  label: Text(
                                    context.tr.translate('add_new'),
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withOpacity(0.9)
                                              : null,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _categories.isEmpty
                                ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error.withOpacity(0.5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          context.tr.translate(
                                            'no_expense_categories',
                                          ),
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withOpacity(0.3)
                                              : Colors.grey.shade300,
                                    ),
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context)
                                                .colorScheme
                                                .surfaceVariant
                                                .withOpacity(0.5)
                                            : Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    menuMaxHeight: 350,
                                    itemHeight: 75,
                                    elevation: 8,
                                    iconSize: 28,
                                    decoration: InputDecoration(
                                      labelText: context.tr.translate(
                                        'select_category',
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 32,
                                          ),
                                      hintStyle: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white.withOpacity(0.7)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                      ),
                                      labelStyle: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white.withOpacity(0.9)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(0.5)
                                                : Theme.of(context).cardColor,
                                        height: 0.1,
                                      ),
                                    ),
                                    value:
                                        _selectedCategory.isEmpty
                                            ? _categories.first.name
                                            : _selectedCategory,
                                    selectedItemBuilder: (
                                      BuildContext context,
                                    ) {
                                      return _categories.map<Widget>((
                                        Category category,
                                      ) {
                                        return Row(
                                          children: [
                                            Container(
                                              width: 65,
                                              height: 65,
                                              margin: const EdgeInsets.only(
                                                right: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error
                                                      .withOpacity(0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          2.0,
                                                        ),
                                                    child: Text(
                                                      category.emoji,
                                                      style: const TextStyle(
                                                        fontSize: 90,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                category.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList();
                                    },
                                    icon: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: Icon(
                                        Icons.arrow_drop_down_circle,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white.withOpacity(0.9)
                                                : null,
                                      ),
                                    ),
                                    items:
                                        _categories.map((Category category) {
                                          return DropdownMenuItem<String>(
                                            value: category.name,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  margin: const EdgeInsets.only(
                                                    right: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .error
                                                                .withOpacity(
                                                                  0.2,
                                                                )
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .error
                                                                .withOpacity(
                                                                  0.15,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                                  .withOpacity(
                                                                    0.3,
                                                                  )
                                                              : Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .error
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: FittedBox(
                                                      fit: BoxFit.contain,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4.0,
                                                            ),
                                                        child: Text(
                                                          category.emoji,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 30,
                                                              ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    category.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white
                                                              : Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .onSurface,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedCategory = newValue;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return context.tr.translate(
                                          'select_category',
                                        );
                                      }
                                      return null;
                                    },
                                    dropdownColor:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.surface
                                            : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Payment method selector
                        Text(
                          context.tr.translate('payment_method'),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentMethodButton(
                                'cash',
                                context.tr.translate('cash'),
                                Icons.money,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPaymentMethodButton(
                                'bank',
                                context.tr.translate('bank'),
                                Icons.account_balance,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: context.tr.translate('description'),
                            border: const OutlineInputBorder(),
                            labelStyle: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.9)
                                      : null,
                            ),
                          ),
                          maxLines: 3,
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
                            onPressed: _isLoading ? null : _saveExpense,
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : Text(context.tr.translate('save')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildPaymentMethodButton(String method, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? isDarkMode
                      ? theme.colorScheme.error.withOpacity(0.7)
                      : theme.colorScheme.errorContainer.withOpacity(0.7)
                  : isDarkMode
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                  : null,
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.error
                    : isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? isDarkMode
                          ? Colors.white
                          : theme.colorScheme.error
                      : isDarkMode
                      ? Colors.white.withOpacity(0.8)
                      : null,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? isDarkMode
                            ? Colors.white
                            : theme.colorScheme.error
                        : isDarkMode
                        ? Colors.white
                        : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
