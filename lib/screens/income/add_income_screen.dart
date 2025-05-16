import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income_model.dart';
import '../../models/category_model.dart';
import '../../services/income_service.dart';
import '../../services/category_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/currency_utils.dart';

class AddIncomeScreen extends StatefulWidget {
  final Function? onSuccess;

  const AddIncomeScreen({super.key, this.onSuccess});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeService = IncomeService();
  final _categoryService = CategoryService();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = ''; // Will be set from loaded categories
  String _selectedPaymentMethod = 'bank'; // Default payment method
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
      // Cargar solo categorías de tipo ingreso
      final categories = await _categoryService.fetchCategories(type: 'income');
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

  Future<void> _saveIncome() async {
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

        // Create income object
        final income = Income(
          userId: '', // Will be filled in by the service
          amount: amount,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          description: _descriptionController.text,
        );

        // Save income
        await _incomeService.addIncome(income);

        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.translate('income_added_successfully')),
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

    return Scaffold(
      appBar: AppBar(title: Text(context.tr.translate('add_income'))),
      body:
          _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: context.tr.translate('amount'),
                            prefixText: currencySymbol,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
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
                              return context.tr.translate('enter_valid_amount');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Date selector
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: context.tr.translate('date'),
                              border: const OutlineInputBorder(),
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

                        // Category dropdown
                        _categories.isEmpty
                            ? Text(
                              context.tr.translate('no_income_categories'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            )
                            : DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: context.tr.translate('category'),
                                border: const OutlineInputBorder(),
                              ),
                              value:
                                  _selectedCategory.isEmpty
                                      ? _categories.first.name
                                      : _selectedCategory,
                              items:
                                  _categories.map((Category category) {
                                    return DropdownMenuItem<String>(
                                      value: category.name,
                                      child: Row(
                                        children: [
                                          Text(category.emoji),
                                          const SizedBox(width: 8),
                                          Text(category.name),
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
                            onPressed: _isLoading ? null : _saveIncome,
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : null,
          border: Border.all(
            color:
                isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
