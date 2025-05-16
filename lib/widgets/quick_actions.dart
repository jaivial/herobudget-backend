import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../screens/category/categories_list_screen.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onIncomePressed;
  final VoidCallback? onExpensePressed;
  final VoidCallback? onPayBillPressed;
  final VoidCallback? onAddCategoryPressed;

  const QuickActionsWidget({
    super.key,
    this.onIncomePressed,
    this.onExpensePressed,
    this.onPayBillPressed,
    this.onAddCategoryPressed,
  });

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
          Text(
            context.tr.translate('quick_actions'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Grid de acciones rápidas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              ActionButton(
                icon: Icons.attach_money,
                label: context.tr.translate('add_income'),
                iconColor: Colors.green,
                backgroundColor: Colors.green.withOpacity(0.1),
                onPressed: onIncomePressed,
              ),
              ActionButton(
                icon: Icons.shopping_cart,
                label: context.tr.translate('add_expense'),
                iconColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
                onPressed: onExpensePressed,
              ),
              ActionButton(
                icon: Icons.payment,
                label: context.tr.translate('pay_bill'),
                iconColor: Colors.blue,
                backgroundColor: Colors.blue.withOpacity(0.1),
                onPressed: onPayBillPressed,
              ),
              ActionButton(
                icon: Icons.category,
                label: context.tr.translate('add_category'),
                iconColor: Colors.purple,
                backgroundColor: Colors.purple.withOpacity(0.1),
                onPressed:
                    onAddCategoryPressed ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoriesListScreen(),
                        ),
                      );
                    },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
