import 'package:flutter/material.dart';

import '../models/transaction_models.dart';
import '../utils/extensions.dart';

class TransactionFiltersDialog extends StatefulWidget {
  final TransactionFilters currentFilters;
  final List<String> availableCategories;
  final Function(TransactionFilters) onFiltersChanged;

  const TransactionFiltersDialog({
    super.key,
    required this.currentFilters,
    required this.availableCategories,
    required this.onFiltersChanged,
  });

  @override
  State<TransactionFiltersDialog> createState() =>
      _TransactionFiltersDialogState();
}

class _TransactionFiltersDialogState extends State<TransactionFiltersDialog> {
  late TransactionFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.translate('filters'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters = const TransactionFilters();
                  });
                },
                child: Text(context.tr.translate('clear_all')),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction types
                  _FilterSection(
                    title: context.tr.translate('transaction_types'),
                    child: Wrap(
                      spacing: 8,
                      children:
                          TransactionType.values.map((type) {
                            final isSelected =
                                _filters.transactionTypes?.contains(type) ??
                                false;
                            return FilterChip(
                              label: Text(context.tr.translate(type.value)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final types = List<TransactionType>.from(
                                    _filters.transactionTypes ?? [],
                                  );
                                  if (selected) {
                                    types.add(type);
                                  } else {
                                    types.remove(type);
                                  }
                                  _filters = _filters.copyWith(
                                    transactionTypes:
                                        types.isEmpty ? null : types,
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment methods
                  _FilterSection(
                    title: context.tr.translate('payment_methods'),
                    child: Wrap(
                      spacing: 8,
                      children:
                          PaymentMethod.values.map((method) {
                            final isSelected =
                                _filters.paymentMethods?.contains(method) ??
                                false;
                            return FilterChip(
                              label: Text(context.tr.translate(method.value)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final methods = List<PaymentMethod>.from(
                                    _filters.paymentMethods ?? [],
                                  );
                                  if (selected) {
                                    methods.add(method);
                                  } else {
                                    methods.remove(method);
                                  }
                                  _filters = _filters.copyWith(
                                    paymentMethods:
                                        methods.isEmpty ? null : methods,
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Categories
                  _FilterSection(
                    title: context.tr.translate('categories'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.availableCategories.map((category) {
                            final isSelected =
                                _filters.categories?.contains(category) ??
                                false;
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final categories = List<String>.from(
                                    _filters.categories ?? [],
                                  );
                                  if (selected) {
                                    categories.add(category);
                                  } else {
                                    categories.remove(category);
                                  }
                                  _filters = _filters.copyWith(
                                    categories:
                                        categories.isEmpty ? null : categories,
                                  );
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bill status (only show if bills are included in transaction types)
                  if (_filters.transactionTypes?.contains(
                        TransactionType.bill,
                      ) ??
                      true)
                    _FilterSection(
                      title: context.tr.translate('bill_status'),
                      child: Wrap(
                        spacing: 8,
                        children:
                            BillStatusFilter.values.map((status) {
                              final isSelected = _filters.billStatus == status;
                              return FilterChip(
                                label: Text(context.tr.translate(status.name)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _filters = _filters.copyWith(
                                      billStatus: selected ? status : null,
                                    );
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr.translate('cancel')),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(_filters);
                  Navigator.pop(context);
                },
                child: Text(context.tr.translate('apply_filters')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget for filter sections
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
