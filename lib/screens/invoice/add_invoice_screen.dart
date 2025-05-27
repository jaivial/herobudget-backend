import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category_model.dart';
import '../../models/invoice_model.dart';
import '../../services/category_service.dart';
import '../../services/invoice_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/currency_utils.dart';
import '../category/add_category_screen.dart';

class AddInvoiceScreen extends StatefulWidget {
  final Function? onSuccess;

  const AddInvoiceScreen({super.key, this.onSuccess});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryService = CategoryService();
  final _invoiceService = InvoiceService();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Fechas
  DateTime _startDate = DateTime.now();
  DateTime _paymentDate = DateTime.now();

  // Categoría y método de pago
  String _selectedCategory = '';
  String _selectedPaymentMethod = 'bank'; // Default payment method

  // Regularidad de pago
  String _selectedRegularity = 'monthly'; // Default regularity

  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String? _errorMessage;

  // Lista de categorías cargadas
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

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Parsear el importe
        final amount = double.parse(
          _amountController.text.replaceAll(',', '.'),
        );

        // Formatear las fechas
        final startDateFormatted = DateFormat('yyyy-MM-dd').format(_startDate);
        final paymentDueDate = DateFormat('yyyy-MM-dd').format(_paymentDate);

        // Verificar que los campos obligatorios no estén vacíos
        if (_selectedCategory.isEmpty) {
          setState(() {
            _errorMessage = context.tr.translate('select_category');
            _isLoading = false;
          });
          return;
        }

        // Usar el servicio para añadir la factura
        final success = await _invoiceService.addInvoice(
          name: _selectedCategory.isNotEmpty ? _selectedCategory : 'Invoice',
          amount: amount,
          dueDate: paymentDueDate,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          recurring:
              _selectedRegularity !=
              'custom', // Si no es personalizado, es recurrente
          description:
              _descriptionController.text.isNotEmpty
                  ? _descriptionController.text
                  : null,
          startDate: startDateFormatted,
          regularity: _selectedRegularity,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr.translate('invoice_added_successfully') != ''
                      ? context.tr.translate('invoice_added_successfully')
                      : 'Factura agregada con éxito',
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );

            // Call the success callback if provided
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            }

            // Close the screen and return success result
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            _errorMessage = 'Error al guardar la factura';
            _isLoading = false;
          });
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
      appBar: AppBar(
        title: Text(context.tr.translate('add_invoice')),
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
                        // Campo de importe
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
                              prefixText: currencySymbol,
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
                                color: Theme.of(context).colorScheme.primary,
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

                        // Fecha de inicio de facturación
                        InkWell(
                          onTap: () => _selectStartDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText:
                                  context.tr.translate('start_date') != ''
                                      ? context.tr.translate('start_date')
                                      : 'Fecha de inicio',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
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
                                  DateFormat('yyyy-MM-dd').format(_startDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Día de pago
                        InkWell(
                          onTap: () => _selectPaymentDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText:
                                  context.tr.translate('payment_day') != ''
                                      ? context.tr.translate('payment_day')
                                      : 'Día de pago',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.event,
                                color: Theme.of(context).colorScheme.primary,
                              ),
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
                                  DateFormat('yyyy-MM-dd').format(_paymentDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Regularidad de pago
                        Text(
                          context.tr.translate('payment_regularity') != ''
                              ? context.tr.translate('payment_regularity')
                              : 'Regularidad de pago',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.outline.withOpacity(0.3)
                                      : Colors.grey.shade300,
                            ),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.5)
                                    : Theme.of(context).cardColor,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedRegularity,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              prefixIcon: Icon(
                                Icons.repeat,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text(
                                  context.tr.translate('daily_period') != ''
                                      ? context.tr.translate('daily_period')
                                      : 'Diaria',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text(
                                  context.tr.translate('weekly_period') != ''
                                      ? context.tr.translate('weekly_period')
                                      : 'Semanal',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'monthly',
                                child: Text(
                                  context.tr.translate('monthly_period') != ''
                                      ? context.tr.translate('monthly_period')
                                      : 'Mensual',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'quarterly',
                                child: Text(
                                  context.tr.translate('quarterly_period') != ''
                                      ? context.tr.translate('quarterly_period')
                                      : 'Trimestral',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'semiannual',
                                child: Text(
                                  context.tr.translate('semiannual_period') !=
                                          ''
                                      ? context.tr.translate(
                                        'semiannual_period',
                                      )
                                      : 'Semestral',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'annual',
                                child: Text(
                                  context.tr.translate('annual_period') != ''
                                      ? context.tr.translate('annual_period')
                                      : 'Anual',
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedRegularity = value;
                                });
                              }
                            },
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            dropdownColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.surface
                                    : Theme.of(context).cardColor,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Categoría con botón de añadir
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
                                : InkWell(
                                  onTap: () {
                                    _showCategorySelector();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
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
                                    ),
                                    child: Row(
                                      children: [
                                        // Icono de categoría (emoji)
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getCategoryEmoji(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Nombre de la categoría
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.tr.translate(
                                                  'select_category',
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedCategory.isEmpty
                                                    ? context.tr.translate(
                                                      'select_category',
                                                    )
                                                    : _selectedCategory,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_drop_down),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Método de pago selector
                        Text(
                          context.tr.translate('payment_method'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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

                        // Campo de descripción
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: context.tr.translate('description'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(
                              Icons.description,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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

                        // Mensaje de error si existe
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

                        // Botón de guardar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveInvoice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator()
                                    : Text(
                                      context.tr.translate('save'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                      ? theme.colorScheme.primary.withOpacity(0.7)
                      : theme.colorScheme.primaryContainer.withOpacity(0.7)
                  : isDarkMode
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                  : null,
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
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
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? isDarkMode
                          ? Colors.white
                          : theme.colorScheme.primary
                      : isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected
                        ? isDarkMode
                            ? Colors.white
                            : theme.colorScheme.primary
                        : isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener el emoji de la categoría seleccionada
  String _getCategoryEmoji() {
    if (_selectedCategory.isEmpty || _categories.isEmpty) {
      return '📂'; // Emoji predeterminado si no hay categoría seleccionada
    }

    // Buscar la categoría seleccionada
    final selectedCat = _categories.firstWhere(
      (cat) => cat.name == _selectedCategory,
      orElse:
          () => Category(
            id: 0,
            name: '',
            emoji: '📂',
            type: 'expense',
            userId: '',
          ),
    );

    return selectedCat.emoji;
  }

  // Método para mostrar el selector de categorías
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.translate('select_category'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCategory = category.name;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
