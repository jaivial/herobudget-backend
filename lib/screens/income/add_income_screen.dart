import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/income_model.dart';
import '../../services/income_service.dart';
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

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Salary'; // Default category
  String _selectedPaymentMethod = 'bank'; // Default payment method
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  // Categorías predefinidas (en un entorno real, estas vendrían de la base de datos)
  final List<String> _categories = [
    'Salary',
    'Freelance',
    'Investments',
    'Gifts',
    'Other',
  ];

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
      body: SingleChildScrollView(
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
                      final amount = double.parse(value.replaceAll(',', '.'));
                      if (amount <= 0) {
                        return context.tr.translate('amount_must_be_positive');
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
                        Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: context.tr.translate('category'),
                    border: const OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items:
                      _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Payment method selector
                Text(
                  context.tr.translate('payment_method'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(context.tr.translate('cash')),
                        selected: _selectedPaymentMethod == 'cash',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPaymentMethod = 'cash';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(context.tr.translate('bank')),
                        selected: _selectedPaymentMethod == 'bank',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPaymentMethod = 'bank';
                            });
                          }
                        },
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

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveIncome,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(context.tr.translate('save_income')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
