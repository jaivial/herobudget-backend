import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../utils/app_localizations.dart';
import '../../theme/app_theme.dart';

class PayBillScreen extends StatefulWidget {
  final Invoice? preselectedInvoice;

  const PayBillScreen({Key? key, this.preselectedInvoice}) : super(key: key);

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  List<Invoice> _unpaidInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  bool _processingPayment = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Invoice>> _invoicesByDay = {};

  // Variables para el formulario
  Invoice? _selectedInvoice;
  String _paymentMethod = 'bank'; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _loadUnpaidInvoices();
  }

  Future<void> _loadUnpaidInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoices = await _invoiceService.fetchInvoices();

      // Filtrar solo las facturas no pagadas
      final unpaidInvoices =
          invoices.where((invoice) => !invoice.paid).toList();

      // Agrupar las facturas por día
      final Map<DateTime, List<Invoice>> invoicesByDay = {};

      for (final invoice in unpaidInvoices) {
        final dueDate = DateTime.parse(invoice.dueDate);
        final dateKey = DateTime(dueDate.year, dueDate.month, dueDate.day);

        if (invoicesByDay.containsKey(dateKey)) {
          invoicesByDay[dateKey]!.add(invoice);
        } else {
          invoicesByDay[dateKey] = [invoice];
        }
      }

      setState(() {
        _unpaidInvoices = unpaidInvoices;
        _filteredInvoices = unpaidInvoices;
        _invoicesByDay = invoicesByDay;
        _isLoading = false;

        // If there's a preselected invoice, set it as selected
        if (widget.preselectedInvoice != null) {
          final preselected = unpaidInvoices.firstWhere(
            (invoice) => invoice.id == widget.preselectedInvoice!.id,
            orElse: () => widget.preselectedInvoice!,
          );
          _selectedInvoice = preselected;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading invoices: $e');
    }
  }

  void _filterInvoicesByDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      final dateKey = DateTime(day.year, day.month, day.day);

      if (_invoicesByDay.containsKey(dateKey)) {
        _filteredInvoices = _invoicesByDay[dateKey]!;
      } else {
        _filteredInvoices = [];
      }

      // Deseleccionar factura si no está en el día seleccionado
      if (_selectedInvoice != null) {
        final isInFilteredList = _filteredInvoices.any(
          (invoice) => invoice.id == _selectedInvoice!.id,
        );
        if (!isInFilteredList) {
          _selectedInvoice = null;
        }
      }
    });
  }

  void _resetFilter() {
    setState(() {
      _selectedDay = null;
      _filteredInvoices = _unpaidInvoices;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.translate('pay_bill')),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _unpaidInvoices.isEmpty
              ? _buildEmptyInvoicesView()
              : _buildPayBillForm(),
    );
  }

  Widget _buildEmptyInvoicesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            context.tr.translate('no_pending_bills'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr.translate('add_bill_to_pay'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPayBillForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendario mensual
          _buildMonthlyCalendar(),

          const SizedBox(height: 20),

          // Título de la sección de facturas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedDay != null
                      ? "${context.tr.translate('select_bill_to_pay')} - ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}"
                      : context.tr.translate('select_bill_to_pay'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_selectedDay != null)
                TextButton.icon(
                  onPressed: _resetFilter,
                  icon: const Icon(Icons.filter_list_off),
                  label: Text(context.tr.translate('all')),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Mostrar mensaje cuando no hay facturas para la fecha seleccionada
          if (_selectedDay != null && _filteredInvoices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      context.tr.translate('no_bills'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),

          // Listado de facturas pendientes (filtradas o todas)
          if (_filteredInvoices.isNotEmpty) _buildBillSelector(),

          const SizedBox(height: 24),

          // Información detallada de la factura seleccionada
          if (_selectedInvoice != null) _buildInvoiceDetails(),

          const SizedBox(height: 20),

          // Método de pago
          if (_selectedInvoice != null) _buildPaymentMethodSelector(),

          // Botón de confirmación
          if (_selectedInvoice != null) ...[
            const SizedBox(height: 24),
            _buildConfirmButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.tr.translate('upcoming_bills'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return _selectedDay != null && isSameDay(_selectedDay!, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              _filterInvoicesByDay(selectedDay);
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final dateKey = DateTime(date.year, date.month, date.day);
                if (_invoicesByDay.containsKey(dateKey) &&
                    _invoicesByDay[dateKey]!.isNotEmpty) {
                  final invoices = _invoicesByDay[dateKey]!;
                  final hasOverdue = invoices.any((invoice) => invoice.overdue);

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            hasOverdue
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredInvoices.length,
        separatorBuilder:
            (context, index) => Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              height: 1,
            ),
        itemBuilder: (context, index) {
          final invoice = _filteredInvoices[index];
          final isSelected = _selectedInvoice?.id == invoice.id;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedInvoice = invoice;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                borderRadius:
                    index == 0
                        ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        )
                        : index == _filteredInvoices.length - 1
                        ? const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                        : BorderRadius.zero,
              ),
              child: Row(
                children: [
                  // Icono de la categoría (no de la factura)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getColorForCategory(
                        invoice.category,
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForCategory(invoice.category),
                      color: _getColorForCategory(invoice.category),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información de la factura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${context.tr.translate('due_date')}: ${invoice.dueDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                invoice.overdue
                                    ? Colors.red
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Monto de la factura
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${invoice.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (invoice.overdue)
                        Text(
                          '${invoice.overdueDays} ${context.tr.translate('days_overdue')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),

                  // Indicador de selección
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    final invoice = _selectedInvoice!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            context.tr.translate('bill_details'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Detalles
          _buildDetailRow(context.tr.translate('bill_name'), invoice.name),
          _buildDetailRow(
            context.tr.translate('amount'),
            '\$${invoice.amount.toStringAsFixed(2)}',
          ),
          _buildDetailRow(context.tr.translate('category'), invoice.category),
          _buildDetailRow(context.tr.translate('due_date'), invoice.dueDate),
          if (invoice.description != null && invoice.description!.isNotEmpty)
            _buildDetailRow(
              context.tr.translate('description'),
              invoice.description!,
            ),

          // Estado
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  invoice.overdue
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              invoice.overdue
                  ? '${context.tr.translate('overdue')}: ${invoice.overdueDays} ${context.tr.translate('days')}'
                  : context.tr.translate('pending'),
              style: TextStyle(
                color: invoice.overdue ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            context.tr.translate('payment_method'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Opciones de pago
          Row(
            children: [
              // Opción Efectivo
              Expanded(
                child: _buildPaymentMethodOption(
                  'cash',
                  Icons.payments_outlined,
                  context.tr.translate('cash'),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),

              // Opción Banco
              Expanded(
                child: _buildPaymentMethodOption(
                  'bank',
                  Icons.account_balance_outlined,
                  context.tr.translate('bank'),
                  Colors.blue,
                ),
              ),
            ],
          ),

          // Nota informativa
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.translate('payment_method_info'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String methodValue,
    IconData icon,
    String label,
    Color accentColor,
  ) {
    final bool isSelected = _paymentMethod == methodValue;

    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = methodValue;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? accentColor.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? accentColor.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? accentColor
                          : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? accentColor
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),

            // Texto
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? accentColor
                        : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            // Indicador seleccionado
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: accentColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    // Simplificado para el ejemplo, se podría usar un mapa más completo
    switch (category.toLowerCase()) {
      case 'utilities':
        return Icons.power;
      case 'rent':
        return Icons.home;
      case 'subscription':
        return Icons.subscriptions;
      case 'credit card':
        return Icons.credit_card;
      case 'loan':
        return Icons.account_balance;
      case 'insurance':
        return Icons.security;
      case 'healthcare':
        return Icons.medical_services;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getColorForCategory(String category) {
    // Simplificado para el ejemplo, se podría usar un mapa más completo
    switch (category.toLowerCase()) {
      case 'utilities':
        return Colors.orange;
      case 'rent':
        return Colors.indigo;
      case 'subscription':
        return Colors.purple;
      case 'credit card':
        return Colors.red;
      case 'loan':
        return Colors.green;
      case 'insurance':
        return Colors.blue;
      case 'healthcare':
        return Colors.teal;
      default:
        return Colors.amber;
    }
  }

  Widget _buildConfirmButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen del pago
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.translate('payment_summary'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Detalles del resumen
              _buildSummaryRow(
                context.tr.translate('bill'),
                _selectedInvoice!.name,
              ),
              _buildSummaryRow(
                context.tr.translate('amount'),
                '\$${_selectedInvoice!.amount.toStringAsFixed(2)}',
                isHighlighted: true,
              ),
              _buildSummaryRow(
                context.tr.translate('payment_method'),
                _paymentMethod == 'cash'
                    ? context.tr.translate('cash')
                    : context.tr.translate('bank'),
              ),
              _buildSummaryRow(
                context.tr.translate('date'),
                DateTime.now().toString().split(' ')[0],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Botón para confirmar el pago
        ElevatedButton(
          onPressed: _processingPayment ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child:
              _processingPayment
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(context.tr.translate('processing')),
                    ],
                  )
                  : Text(
                    context.tr.translate('confirm_payment'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlighted ? 16 : null,
              color:
                  isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Procesar el pago de la factura
  Future<void> _processPayment() async {
    if (_selectedInvoice == null) return;

    setState(() {
      _processingPayment = true;
    });

    try {
      // Llamar al servicio para pagar la factura
      final success = await _invoiceService.payInvoice(
        _selectedInvoice!.id,
        _paymentMethod,
      );

      if (success) {
        _showSuccessSnackBar(context.tr.translate('payment_successful'));

        // Esperar un momento para que el usuario vea el mensaje de éxito
        await Future.delayed(const Duration(seconds: 1));

        // Volver a la pantalla anterior
        if (!mounted) return;
        Navigator.of(context).pop(true); // Pasar true para indicar éxito
      } else {
        _showErrorSnackBar(context.tr.translate('payment_failed'));
        setState(() {
          _processingPayment = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('${context.tr.translate('payment_error')}: $e');
      setState(() {
        _processingPayment = false;
      });
    }
  }
}
