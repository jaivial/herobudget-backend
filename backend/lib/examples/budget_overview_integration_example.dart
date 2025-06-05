import 'package:flutter/material.dart';
import '../widgets/budget_overview_monthly.dart';
import '../utils/app_localizations.dart';

/// Example screen showing how to use the integrated BudgetOverviewMonthly widget
/// This demonstrates the complete integration between the monthly selector and budget overview
/// with automatic data fetching from the microservice.
class BudgetOverviewIntegrationExample extends StatelessWidget {
  const BudgetOverviewIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('money_flow')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const BudgetOverviewMonthly(),
    );
  }
}

/// Alternative implementation showing how to embed the widget in a larger screen
class DashboardWithBudgetOverview extends StatelessWidget {
  const DashboardWithBudgetOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.translate('dashboard'))),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Other dashboard widgets can go here

            // Budget Overview Section
            const BudgetOverviewMonthly(),

            // More dashboard widgets can be added below
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Example showing how to customize the widget for specific use cases
class CustomBudgetOverviewExample extends StatefulWidget {
  const CustomBudgetOverviewExample({super.key});

  @override
  State<CustomBudgetOverviewExample> createState() =>
      _CustomBudgetOverviewExampleState();
}

class _CustomBudgetOverviewExampleState
    extends State<CustomBudgetOverviewExample> {
  bool _isCompactView = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('money_flow')),
        actions: [
          IconButton(
            icon: Icon(_isCompactView ? Icons.expand_more : Icons.expand_less),
            onPressed: () {
              setState(() {
                _isCompactView = !_isCompactView;
              });
            },
            tooltip: _isCompactView ? 'Expand View' : 'Compact View',
          ),
        ],
      ),
      body:
          _isCompactView
              ? const CompactBudgetView()
              : const BudgetOverviewMonthly(),
    );
  }
}

/// Compact version for situations where space is limited
class CompactBudgetView extends StatelessWidget {
  const CompactBudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: BudgetOverviewMonthly(),
    );
  }
}

/// Instructions widget showing developers how to implement the integration
class IntegrationInstructions extends StatelessWidget {
  const IntegrationInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Overview Integration Guide')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Overview Integration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This integration provides:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const BulletPoint('🔄 Automatic data fetching when period changes'),
            const BulletPoint('📊 Real-time budget overview from microservice'),
            const BulletPoint(
              '🕒 Period navigation (daily, weekly, monthly, etc.)',
            ),
            const BulletPoint('🌐 Multi-language support'),
            const BulletPoint('🔁 Pull-to-refresh functionality'),
            const BulletPoint('⚠️ Error handling with fallback data'),
            const SizedBox(height: 20),

            const Text(
              'Technical Implementation:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const CodeBlock('''
// Basic usage in any screen:
const BudgetOverviewMonthly()

// The widget automatically:
// 1. Initializes with current month
// 2. Fetches data from budget_overview_fetch microservice
// 3. Updates when user changes period or navigates dates
// 4. Handles errors gracefully with fallback data
'''),
            const SizedBox(height: 16),

            const Text(
              'Microservice Integration:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const BulletPoint(
              '🚀 Connects to port 8097 (budget_overview_fetch)',
            ),
            const BulletPoint('📡 Makes HTTP POST calls with period and date'),
            const BulletPoint(
              '📊 Fetches data from [periodtime]_cash_bank_balance tables',
            ),
            const BulletPoint('🔧 Returns calculated budget overview metrics'),
            const SizedBox(height: 20),

            const Text(
              'API Response Structure:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const CodeBlock('''
{
  "success": true,
  "data": {
    "remaining_amount": 1245.30,
    "expense_percent": 75.8,
    "spent_amount": 3500.00,
    "upcoming_amount": 750.50,
    "total_amount": 5000.00,
    "combined_expense": 4250.50,
    "total_income": 5495.80,
    "daily_rate": 141.68,
    "high_spending": false,
    "money_flow": {
      "from_previous": 495.80
    }
  }
}
'''),
          ],
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

class CodeBlock extends StatelessWidget {
  final String code;

  const CodeBlock(this.code, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        code,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
    );
  }
}
