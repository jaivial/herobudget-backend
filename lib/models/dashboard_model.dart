class DashboardModel {
  final String period;
  final String date;
  final BudgetOverview budgetOverview;
  final SavingsOverview savingsOverview;
  final CashBankDistribution cashDistribution;
  final FinanceMetrics financeMetrics;
  final List<Bill> upcomingBills;

  DashboardModel({
    required this.period,
    required this.date,
    required this.budgetOverview,
    required this.savingsOverview,
    required this.cashDistribution,
    required this.financeMetrics,
    required this.upcomingBills,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      period: json['period'] ?? 'monthly',
      date: json['date'] ?? '',
      budgetOverview: BudgetOverview.fromJson(json['budget_overview'] ?? {}),
      savingsOverview: SavingsOverview.fromJson(json['savings_overview'] ?? {}),
      cashDistribution: CashBankDistribution.fromJson(
        json['cash_distribution'] ?? {},
      ),
      financeMetrics: FinanceMetrics.fromJson(json['finance_metrics'] ?? {}),
      upcomingBills:
          (json['upcoming_bills'] as List<dynamic>?)
              ?.map((bill) => Bill.fromJson(bill))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'date': date,
      'budget_overview': budgetOverview.toJson(),
      'savings_overview': savingsOverview.toJson(),
      'cash_distribution': cashDistribution.toJson(),
      'finance_metrics': financeMetrics.toJson(),
      'upcoming_bills': upcomingBills.map((bill) => bill.toJson()).toList(),
    };
  }
}

class BudgetOverview {
  final MoneyFlow moneyFlow;
  final double remainingAmount;
  final double totalAmount;
  final double spentAmount;
  final double upcomingAmount;
  final double combinedExpense;
  final double expensePercent;
  final double dailyRate;
  final bool highSpending;
  final double totalIncome;

  BudgetOverview({
    required this.moneyFlow,
    required this.remainingAmount,
    required this.totalAmount,
    required this.spentAmount,
    required this.upcomingAmount,
    required this.combinedExpense,
    required this.expensePercent,
    required this.dailyRate,
    required this.highSpending,
    required this.totalIncome,
  });

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    return BudgetOverview(
      moneyFlow: MoneyFlow.fromJson(json['money_flow'] ?? {}),
      remainingAmount: json['remaining_amount']?.toDouble() ?? 0.0,
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      spentAmount: json['spent_amount']?.toDouble() ?? 0.0,
      upcomingAmount: json['upcoming_amount']?.toDouble() ?? 0.0,
      combinedExpense: json['combined_expense']?.toDouble() ?? 0.0,
      expensePercent: json['expense_percent']?.toDouble() ?? 0.0,
      dailyRate: json['daily_rate']?.toDouble() ?? 0.0,
      highSpending: json['high_spending'] ?? false,
      totalIncome: json['total_income']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'money_flow': moneyFlow.toJson(),
      'remaining_amount': remainingAmount,
      'total_amount': totalAmount,
      'spent_amount': spentAmount,
      'upcoming_amount': upcomingAmount,
      'combined_expense': combinedExpense,
      'expense_percent': expensePercent,
      'daily_rate': dailyRate,
      'high_spending': highSpending,
      'total_income': totalIncome,
    };
  }
}

class MoneyFlow {
  final double percent;
  final double fromPrevious;

  MoneyFlow({required this.percent, required this.fromPrevious});

  factory MoneyFlow.fromJson(Map<String, dynamic> json) {
    return MoneyFlow(
      percent: json['percent']?.toDouble() ?? 0.0,
      fromPrevious: json['from_previous']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'percent': percent, 'from_previous': fromPrevious};
  }
}

class SavingsOverview {
  final double percent;
  final double available;
  final double goal;
  final double needToSave;
  final double dailyTarget;

  SavingsOverview({
    required this.percent,
    required this.available,
    required this.goal,
    required this.needToSave,
    required this.dailyTarget,
  });

  factory SavingsOverview.fromJson(Map<String, dynamic> json) {
    return SavingsOverview(
      percent: json['percent']?.toDouble() ?? 0.0,
      available: json['available']?.toDouble() ?? 0.0,
      goal: json['goal']?.toDouble() ?? 0.0,
      needToSave: json['need_to_save']?.toDouble() ?? 0.0,
      dailyTarget: json['daily_target']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'percent': percent,
      'available': available,
      'goal': goal,
      'need_to_save': needToSave,
      'daily_target': dailyTarget,
    };
  }
}

class CashBankDistribution {
  final String month;
  final double cashAmount;
  final double cashPercent;
  final double bankAmount;
  final double bankPercent;
  final double monthlyTotal;

  CashBankDistribution({
    required this.month,
    required this.cashAmount,
    required this.cashPercent,
    required this.bankAmount,
    required this.bankPercent,
    required this.monthlyTotal,
  });

  factory CashBankDistribution.fromJson(Map<String, dynamic> json) {
    return CashBankDistribution(
      month: json['month'] ?? '',
      cashAmount: json['cash_amount']?.toDouble() ?? 0.0,
      cashPercent: json['cash_percent']?.toDouble() ?? 0.0,
      bankAmount: json['bank_amount']?.toDouble() ?? 0.0,
      bankPercent: json['bank_percent']?.toDouble() ?? 0.0,
      monthlyTotal: json['monthly_total']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'cash_amount': cashAmount,
      'cash_percent': cashPercent,
      'bank_amount': bankAmount,
      'bank_percent': bankPercent,
      'monthly_total': monthlyTotal,
    };
  }
}

class FinanceMetrics {
  final double income;
  final double expenses;
  final double bills;

  FinanceMetrics({
    required this.income,
    required this.expenses,
    required this.bills,
  });

  factory FinanceMetrics.fromJson(Map<String, dynamic> json) {
    return FinanceMetrics(
      income: json['income']?.toDouble() ?? 0.0,
      expenses: json['expenses']?.toDouble() ?? 0.0,
      bills: json['bills']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'income': income, 'expenses': expenses, 'bills': bills};
  }
}

class Bill {
  final int id;
  final String name;
  final double amount;
  final String dueDate;
  final bool paid;
  final bool overdue;
  final int overdueDays;
  final bool recurring;
  final String category;
  final String icon;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.paid,
    required this.overdue,
    required this.overdueDays,
    required this.recurring,
    required this.category,
    required this.icon,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      dueDate: json['due_date'] ?? '',
      paid: json['paid'] ?? false,
      overdue: json['overdue'] ?? false,
      overdueDays: json['overdue_days'] ?? 0,
      recurring: json['recurring'] ?? false,
      category: json['category'] ?? '',
      icon: json['icon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'due_date': dueDate,
      'paid': paid,
      'overdue': overdue,
      'overdue_days': overdueDays,
      'recurring': recurring,
      'category': category,
      'icon': icon,
    };
  }
}
