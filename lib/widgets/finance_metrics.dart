import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import 'package:intl/intl.dart';

class FinanceMetricsWidget extends StatelessWidget {
  final FinanceMetrics metrics;

  const FinanceMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finance Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Tarjetas de métricas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricCard(
                icon: Icons.attach_money,
                iconBackground: Colors.yellow,
                title: 'Income',
                amount: metrics.income,
              ),

              MetricCard(
                icon: Icons.shopping_cart,
                iconBackground: Colors.red,
                title: 'Expenses',
                amount: metrics.expenses,
              ),

              MetricCard(
                icon: Icons.receipt_long,
                iconBackground: Colors.blue,
                title: 'Bills',
                amount: metrics.bills,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final double amount;

  const MetricCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Formateo de moneda
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      width: MediaQuery.of(context).size.width * 0.26,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBackground.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconBackground, size: 24),
          ),

          const SizedBox(height: 12),

          // Título
          Text(
            title,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Cantidad
          Text(
            '${amount.toInt()}\$',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class UpcomingBillsWidget extends StatelessWidget {
  final List<Bill> bills;
  final VoidCallback? onAddBill;

  const UpcomingBillsWidget({super.key, required this.bills, this.onAddBill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y descripción
          const Text(
            'Upcoming Bills',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Plan ahead for your scheduled payments',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Lista de facturas
          bills.isEmpty
              ? _EmptyBillsList(onAddBill: onAddBill)
              : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return BillItem(bill: bills[index]);
                },
              ),

          // Botón para agregar nueva factura
          if (bills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: InkWell(
                onTap: onAddBill,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Bill',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyBillsList extends StatelessWidget {
  final VoidCallback? onAddBill;

  const _EmptyBillsList({this.onAddBill});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.receipt_long_outlined,
          size: 60,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        Text(
          'No upcoming bills',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your first bill to start tracking',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onAddBill,
          icon: const Icon(Icons.add),
          label: const Text('Add Bill'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class BillItem extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onPayBill;

  const BillItem({super.key, required this.bill, this.onPayBill});

  @override
  Widget build(BuildContext context) {
    // Formateo de moneda
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    // Determinar colores basados en el estado
    final Color borderColor =
        bill.overdue
            ? Colors.red.shade300
            : Theme.of(context).colorScheme.outline.withOpacity(0.2);

    final Color backgroundColor =
        bill.overdue
            ? Colors.red.shade50
            : Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Barra lateral para facturas vencidas
          if (bill.overdue)
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icono de la factura
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bill.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Detalles de la factura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado de la factura (si está vencida)
                        if (bill.overdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Overdue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // Nombre y categoría
                        Text(
                          bill.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        if (bill.overdue)
                          Text(
                            'Overdue by ${bill.overdueDays} days • ${bill.recurring ? 'Recurring' : 'One-time'}',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Monto y fecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(bill.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDueDate(bill.dueDate),
                        style: TextStyle(
                          color:
                              bill.overdue
                                  ? Colors.red.shade800
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
