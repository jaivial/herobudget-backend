import 'package:flutter_test/flutter_test.dart';
import 'package:hero_budget/models/dashboard_model.dart';

void main() {
  group('DashboardModel', () {
    test('fromJson creates a valid model from JSON', () {
      // Arrange
      final Map<String, dynamic> json = {
        'period': 'monthly',
        'date': '2023-07-01',
        'budget_overview': {
          'money_flow': {'percent': 10.0, 'from_previous': 500.0},
          'remaining_amount': 750.0,
          'total_amount': 1000.0,
          'spent_amount': 150.0,
          'upcoming_amount': 100.0,
          'combined_expense': 250.0,
          'expense_percent': 25.0,
          'daily_rate': 8.33,
          'high_spending': false,
        },
        'savings_overview': {
          'percent': 80.0,
          'available': 800.0,
          'goal': 1000.0,
          'need_to_save': 200.0,
          'daily_target': 6.67,
        },
        'cash_distribution': {
          'month': 'July 2023',
          'cash_amount': 300.0,
          'cash_percent': 30.0,
          'bank_amount': 700.0,
          'bank_percent': 70.0,
          'monthly_total': 1000.0,
        },
        'finance_metrics': {
          'income': 2000.0,
          'expenses': 800.0,
          'bills': 400.0,
        },
        'upcoming_bills': [
          {
            'id': 1,
            'name': 'Rent',
            'amount': 800.0,
            'due_date': '2023-07-05',
            'paid': false,
            'overdue': false,
            'overdue_days': 0,
            'recurring': true,
            'category': 'Housing',
            'icon': '🏠',
          },
          {
            'id': 2,
            'name': 'Electricity',
            'amount': 100.0,
            'due_date': '2023-07-10',
            'paid': false,
            'overdue': false,
            'overdue_days': 0,
            'recurring': true,
            'category': 'Utilities',
            'icon': '⚡',
          },
        ],
      };

      // Act
      final DashboardModel dashboard = DashboardModel.fromJson(json);

      // Assert
      expect(dashboard.period, 'monthly');
      expect(dashboard.date, '2023-07-01');
      expect(dashboard.budgetOverview.remainingAmount, 750.0);
      expect(dashboard.budgetOverview.totalAmount, 1000.0);
      expect(dashboard.budgetOverview.spentAmount, 150.0);
      expect(dashboard.budgetOverview.upcomingAmount, 100.0);
      expect(dashboard.budgetOverview.combinedExpense, 250.0);
      expect(dashboard.budgetOverview.expensePercent, 25.0);
      expect(dashboard.budgetOverview.dailyRate, 8.33);
      expect(dashboard.budgetOverview.highSpending, false);

      expect(dashboard.budgetOverview.moneyFlow.percent, 10.0);
      expect(dashboard.budgetOverview.moneyFlow.fromPrevious, 500.0);

      expect(dashboard.savingsOverview.percent, 80.0);
      expect(dashboard.savingsOverview.available, 800.0);
      expect(dashboard.savingsOverview.goal, 1000.0);
      expect(dashboard.savingsOverview.needToSave, 200.0);
      expect(dashboard.savingsOverview.dailyTarget, 6.67);

      expect(dashboard.cashDistribution.month, 'July 2023');
      expect(dashboard.cashDistribution.cashAmount, 300.0);
      expect(dashboard.cashDistribution.cashPercent, 30.0);
      expect(dashboard.cashDistribution.bankAmount, 700.0);
      expect(dashboard.cashDistribution.bankPercent, 70.0);
      expect(dashboard.cashDistribution.monthlyTotal, 1000.0);

      expect(dashboard.financeMetrics.income, 2000.0);
      expect(dashboard.financeMetrics.expenses, 800.0);
      expect(dashboard.financeMetrics.bills, 400.0);

      expect(dashboard.upcomingBills.length, 2);
      expect(dashboard.upcomingBills[0].id, 1);
      expect(dashboard.upcomingBills[0].name, 'Rent');
      expect(dashboard.upcomingBills[0].amount, 800.0);
      expect(dashboard.upcomingBills[0].dueDate, '2023-07-05');
      expect(dashboard.upcomingBills[0].paid, false);
      expect(dashboard.upcomingBills[0].overdue, false);
      expect(dashboard.upcomingBills[0].overdueDays, 0);
      expect(dashboard.upcomingBills[0].recurring, true);
      expect(dashboard.upcomingBills[0].category, 'Housing');
      expect(dashboard.upcomingBills[0].icon, '🏠');
    });

    test('toJson converts model to valid JSON', () {
      // Arrange
      final dashboardModel = DashboardModel(
        period: 'monthly',
        date: '2023-07-01',
        budgetOverview: BudgetOverview(
          moneyFlow: MoneyFlow(percent: 10.0, fromPrevious: 500.0),
          remainingAmount: 750.0,
          totalAmount: 1000.0,
          spentAmount: 150.0,
          upcomingAmount: 100.0,
          combinedExpense: 250.0,
          expensePercent: 25.0,
          dailyRate: 8.33,
          highSpending: false,
          totalIncome: 2000.0,
        ),
        savingsOverview: SavingsOverview(
          percent: 80.0,
          available: 800.0,
          goal: 1000.0,
          needToSave: 200.0,
          dailyTarget: 6.67,
        ),
        cashDistribution: CashBankDistribution(
          month: 'July 2023',
          cashAmount: 300.0,
          cashPercent: 30.0,
          bankAmount: 700.0,
          bankPercent: 70.0,
          monthlyTotal: 1000.0,
        ),
        financeMetrics: FinanceMetrics(
          income: 2000.0,
          expenses: 800.0,
          bills: 400.0,
        ),
        upcomingBills: [
          Bill(
            id: 1,
            name: 'Rent',
            amount: 800.0,
            dueDate: '2023-07-05',
            paid: false,
            overdue: false,
            overdueDays: 0,
            recurring: true,
            category: 'Housing',
            icon: '🏠',
          ),
          Bill(
            id: 2,
            name: 'Electricity',
            amount: 100.0,
            dueDate: '2023-07-10',
            paid: false,
            overdue: false,
            overdueDays: 0,
            recurring: true,
            category: 'Utilities',
            icon: '⚡',
          ),
        ],
      );

      // Act
      final Map<String, dynamic> json = dashboardModel.toJson();

      // Assert
      expect(json['period'], 'monthly');
      expect(json['date'], '2023-07-01');

      expect(json['budget_overview']['remaining_amount'], 750.0);
      expect(json['budget_overview']['total_amount'], 1000.0);
      expect(json['budget_overview']['spent_amount'], 150.0);
      expect(json['budget_overview']['upcoming_amount'], 100.0);
      expect(json['budget_overview']['combined_expense'], 250.0);
      expect(json['budget_overview']['expense_percent'], 25.0);
      expect(json['budget_overview']['daily_rate'], 8.33);
      expect(json['budget_overview']['high_spending'], false);

      expect(json['budget_overview']['money_flow']['percent'], 10.0);
      expect(json['budget_overview']['money_flow']['from_previous'], 500.0);

      expect(json['savings_overview']['percent'], 80.0);
      expect(json['savings_overview']['available'], 800.0);
      expect(json['savings_overview']['goal'], 1000.0);
      expect(json['savings_overview']['need_to_save'], 200.0);
      expect(json['savings_overview']['daily_target'], 6.67);

      expect(json['cash_distribution']['month'], 'July 2023');
      expect(json['cash_distribution']['cash_amount'], 300.0);
      expect(json['cash_distribution']['cash_percent'], 30.0);
      expect(json['cash_distribution']['bank_amount'], 700.0);
      expect(json['cash_distribution']['bank_percent'], 70.0);
      expect(json['cash_distribution']['monthly_total'], 1000.0);

      expect(json['finance_metrics']['income'], 2000.0);
      expect(json['finance_metrics']['expenses'], 800.0);
      expect(json['finance_metrics']['bills'], 400.0);

      expect(json['upcoming_bills'].length, 2);
      expect(json['upcoming_bills'][0]['id'], 1);
      expect(json['upcoming_bills'][0]['name'], 'Rent');
      expect(json['upcoming_bills'][0]['amount'], 800.0);
      expect(json['upcoming_bills'][0]['due_date'], '2023-07-05');
      expect(json['upcoming_bills'][0]['paid'], false);
      expect(json['upcoming_bills'][0]['overdue'], false);
      expect(json['upcoming_bills'][0]['overdue_days'], 0);
      expect(json['upcoming_bills'][0]['recurring'], true);
      expect(json['upcoming_bills'][0]['category'], 'Housing');
      expect(json['upcoming_bills'][0]['icon'], '🏠');
    });

    test('handles empty JSON gracefully', () {
      // Act
      final DashboardModel dashboard = DashboardModel.fromJson({});

      // Assert
      expect(dashboard.period, 'monthly'); // Default value
      expect(dashboard.date, '');
      expect(dashboard.budgetOverview.totalAmount, 0.0);
      expect(dashboard.savingsOverview.available, 0.0);
      expect(dashboard.cashDistribution.monthlyTotal, 0.0);
      expect(dashboard.financeMetrics.income, 0.0);
      expect(dashboard.upcomingBills.length, 0);
    });
  });
}
