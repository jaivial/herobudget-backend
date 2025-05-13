import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_budget/models/dashboard_model.dart';
import 'package:hero_budget/widgets/budget_overview.dart';

void main() {
  group('BudgetOverviewWidget', () {
    testWidgets('renders correctly with budget data', (
      WidgetTester tester,
    ) async {
      // Create a test BudgetOverview object
      final budgetOverview = BudgetOverview(
        moneyFlow: MoneyFlow(percent: 10.0, fromPrevious: 500.0),
        remainingAmount: 750.0,
        totalAmount: 1000.0,
        spentAmount: 150.0,
        upcomingAmount: 100.0,
        combinedExpense: 250.0,
        expensePercent: 25.0,
        dailyRate: 8.33,
        highSpending: false,
      );

      // Build our widget and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetOverviewWidget(budgetOverview: budgetOverview),
          ),
        ),
      );

      // Verify the widget displays the correct title
      expect(find.text('Budget Overview'), findsOneWidget);

      // Verify the widget displays the correct remaining amount
      expect(find.textContaining('750'), findsOneWidget);

      // Verify progress indicator is displayed
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Verify spent and upcoming amounts are displayed
      expect(find.textContaining('150'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('displays high spending warning when applicable', (
      WidgetTester tester,
    ) async {
      // Create a test BudgetOverview object with high spending flag
      final budgetOverview = BudgetOverview(
        moneyFlow: MoneyFlow(percent: 55.0, fromPrevious: 500.0),
        remainingAmount: 400.0,
        totalAmount: 1000.0,
        spentAmount: 500.0,
        upcomingAmount: 100.0,
        combinedExpense: 600.0,
        expensePercent: 60.0,
        dailyRate: 20.0,
        highSpending: true,
      );

      // Build our widget and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetOverviewWidget(budgetOverview: budgetOverview),
          ),
        ),
      );

      // Verify the high spending warning is displayed
      expect(find.textContaining('High Spending'), findsOneWidget);

      // Verify the warning icon is displayed
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('displays positive flow when money flow percent is positive', (
      WidgetTester tester,
    ) async {
      // Create a test BudgetOverview object with positive money flow
      final budgetOverview = BudgetOverview(
        moneyFlow: MoneyFlow(percent: 15.0, fromPrevious: 150.0),
        remainingAmount: 800.0,
        totalAmount: 1000.0,
        spentAmount: 150.0,
        upcomingAmount: 50.0,
        combinedExpense: 200.0,
        expensePercent: 20.0,
        dailyRate: 6.67,
        highSpending: false,
      );

      // Build our widget and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetOverviewWidget(budgetOverview: budgetOverview),
          ),
        ),
      );

      // Verify the positive flow indicator is displayed
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.text('+15.0%'), findsOneWidget);
    });

    testWidgets('displays negative flow when money flow percent is negative', (
      WidgetTester tester,
    ) async {
      // Create a test BudgetOverview object with negative money flow
      final budgetOverview = BudgetOverview(
        moneyFlow: MoneyFlow(percent: -10.0, fromPrevious: -100.0),
        remainingAmount: 700.0,
        totalAmount: 1000.0,
        spentAmount: 200.0,
        upcomingAmount: 100.0,
        combinedExpense: 300.0,
        expensePercent: 30.0,
        dailyRate: 10.0,
        highSpending: false,
      );

      // Build our widget and trigger a frame
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetOverviewWidget(budgetOverview: budgetOverview),
          ),
        ),
      );

      // Verify the negative flow indicator is displayed
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.text('-10.0%'), findsOneWidget);
    });
  });
}
