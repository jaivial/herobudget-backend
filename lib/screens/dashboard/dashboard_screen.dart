import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/language_service.dart';
import '../../services/app_service.dart';
import '../../utils/extensions.dart';
import '../../widgets/localized_text_example.dart';
import '../../widgets/language_selector_widget.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/budget_overview.dart' as widget_budget;
import '../../widgets/cash_bank_distribution.dart';
import '../../widgets/finance_metrics.dart';
import '../../widgets/period_selector.dart';
import '../../widgets/quick_actions.dart';
import '../../widgets/savings_overview.dart';
import '../../widgets/upcoming_bills.dart';
import '../../models/dashboard_model.dart';
import '../../services/savings_service.dart';
import '../../services/cash_bank_service.dart';
import '../../services/bills_service.dart';
import '../onboarding/onboarding_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import '../../utils/currency_utils.dart';
import '../income/add_income_screen.dart';
import '../expense/add_expense_screen.dart';
import '../category/categories_list_screen.dart';
import '../category/add_category_screen.dart';
import 'package:intl/intl.dart';
import '../invoice/add_invoice_screen.dart';
import '../invoice/pay_bill_screen.dart';
import '../../widgets/budget_overview_with_period.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userInfo;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userInfo,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DashboardService _dashboardService = DashboardService();
  final SavingsService _savingsService = SavingsService();
  final CashBankService _cashBankService = CashBankService();
  final BillsService _billsService = BillsService();
  late Future<DashboardModel> _dashboardFuture;
  String _currentPeriod = 'monthly';
  DateTime _selectedDate = DateTime.now();
  UserModel? _user;
  int _currentNavigationIndex = 0;
  Map<String, dynamic> _latestUserInfo = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // Control del menú de acciones rápidas
  bool _isQuickMenuExpanded = false;
  late AnimationController _animationController;

  // Definición de acciones rápidas
  late List<Map<String, dynamic>> _quickActions;

  // Estado de carga y error
  bool _isDashboardLoading = false;
  String? _dashboardErrorMessage;
  DashboardModel? _dashboardModel;

  // Cache para almacenar datos por periodo y fecha
  final Map<String, DashboardModel> _dashboardModelCache = {};

  // Key para refrescar el BudgetOverviewWithPeriod
  final GlobalKey _budgetOverviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Start with the passed userInfo
    _latestUserInfo = widget.userInfo;

    // Inicializar con datos simulados en lugar de llamadas API
    _user = UserModel(
      id: widget.userId.isEmpty ? "user123" : widget.userId,
      email: 'usuario@ejemplo.com',
      name: 'Usuario Demo',
      locale: 'es',
      verifiedEmail: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Cargar datos simulados
    _dashboardModel = _createMockDashboardData('monthly');
    _isDashboardLoading = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initQuickActions();
  }

  void _initQuickActions() {
    _quickActions = [
      {
        'icon': Icons.add_card,
        'label': context.tr.translate('add_income'),
        'color': Colors.green,
      },
      {
        'icon': Icons.shopping_bag,
        'label': context.tr.translate('add_expense'),
        'color': Colors.red,
      },
      {
        'icon': Icons.receipt,
        'label': context.tr.translate('pay_bill'),
        'color': Colors.blue,
      },
      {
        'icon': Icons.receipt_long,
        'label': context.tr.translate('add_invoice'),
        'color': Colors.amber,
      },
      {
        'icon': Icons.category,
        'label': context.tr.translate('add_category'),
        'color': Colors.orange,
      },
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleQuickMenu() {
    setState(() {
      _isQuickMenuExpanded = !_isQuickMenuExpanded;

      if (_isQuickMenuExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _fetchLatestUserInfo() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // First try with the userId passed to the widget
      if (widget.userId.isEmpty) {
        print("Attempting to fetch user info with ID: null");

        // If userId is not provided, try to get it from localStorage
        print(
          "User ID is empty or 'null', attempting to retrieve from localStorage",
        );
        final userId = await DashboardService.getCurrentUserId();

        if (userId == null || userId.isEmpty) {
          throw Exception('No valid user ID found');
        }

        print("Retrieved user ID from localStorage: $userId");
        try {
          final latestInfo = await DashboardService.fetchUserInfo(userId);

          if (mounted) {
            setState(() {
              _latestUserInfo = latestInfo;
              _isLoading = false;
            });

            // Cargar el idioma del usuario si está disponible
            if (latestInfo['locale'] != null &&
                latestInfo['locale'].isNotEmpty) {
              String userLocale = latestInfo['locale'];

              // Asegurar que tenemos solo el código de idioma sin el país (ej: 'en' en lugar de 'en-US')
              if (userLocale.contains('-')) {
                userLocale = userLocale.split('-')[0];
              }

              // Cargar el idioma utilizando el servicio
              await LanguageService.saveLanguagePreference(userLocale);

              // Notificar el cambio de idioma usando el languageNotifier
              languageNotifier.notifyLanguageChanged(userLocale);
            }
          }
        } catch (e) {
          // Check if this is a user not found error
          if (e.toString().contains('404') ||
              e.toString().contains('User not found') ||
              e.toString().contains('Failed to fetch user information')) {
            print(
              "User not found (404) - clearing data and returning to onboarding",
            );
            await _handleUserNotFound();
            return;
          } else {
            // Rethrow other errors to be caught in the outer catch block
            rethrow;
          }
        }
      } else {
        print("Using provided user ID: ${widget.userId}");
        try {
          final latestInfo = await DashboardService.fetchUserInfo(
            widget.userId,
          );

          if (mounted) {
            setState(() {
              _latestUserInfo = latestInfo;
              _isLoading = false;
            });

            // Cargar el idioma del usuario si está disponible
            if (latestInfo['locale'] != null &&
                latestInfo['locale'].isNotEmpty) {
              String userLocale = latestInfo['locale'];

              // Asegurar que tenemos solo el código de idioma sin el país (ej: 'en' en lugar de 'en-US')
              if (userLocale.contains('-')) {
                userLocale = userLocale.split('-')[0];
              }

              // Guardar la preferencia de idioma y notificar el cambio
              await LanguageService.saveLanguagePreference(userLocale);
              languageNotifier.notifyLanguageChanged(userLocale);
            }
          }
        } catch (e) {
          // Check if this is a user not found error
          if (e.toString().contains('404') ||
              e.toString().contains('User not found') ||
              e.toString().contains('Failed to fetch user information')) {
            print(
              "User not found (404) - clearing data and returning to onboarding",
            );
            await _handleUserNotFound();
            return;
          } else {
            // Rethrow other errors to be caught in the outer catch block
            rethrow;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch the latest user information';
          _isLoading = false;
        });
      }
      print('Error fetching user info: $e');
    }
  }

  // Helper method to handle user not found errors
  Future<void> _handleUserNotFound() async {
    try {
      // Clear user data from localStorage
      await AuthService.signOut(context);

      // Navigate to onboarding screen
      if (mounted && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during handling user not found: $e');
    }
  }

  Future<void> _loadUser() async {
    try {
      // Si se pasó la información de usuario en el constructor, usarla
      if (widget.userInfo.isNotEmpty) {
        // Crear modelo de usuario
        final userModel = UserModel.fromJson(widget.userInfo);

        setState(() {
          _user = userModel;
        });

        // Si el usuario tiene preferencia de idioma, usarla
        if (userModel.locale != null && userModel.locale!.isNotEmpty) {
          String userLocale = userModel.locale!;

          // Asegurar que tenemos solo el código de idioma sin el país (ej: 'en' en lugar de 'en-US')
          if (userLocale.contains('-')) {
            userLocale = userLocale.split('-')[0];
          }

          // Guardar la preferencia de idioma y notificar el cambio
          await LanguageService.saveLanguagePreference(userLocale);
          print('Setting user language to: $userLocale');
          languageNotifier.notifyLanguageChanged(userLocale);
        }

        return;
      }

      final userInfo = await DashboardService.getCurrentUserInfo();
      setState(() {
        _user = userInfo;
      });

      // Si el usuario tiene preferencia de idioma, usarla
      if (userInfo != null && userInfo.locale != null) {
        String userLocale = userInfo.locale;

        // Asegurar que tenemos solo el código de idioma sin el país
        if (userLocale.contains('-')) {
          userLocale = userLocale.split('-')[0];
        }

        // Guardar la preferencia de idioma y notificar el cambio
        await LanguageService.saveLanguagePreference(userLocale);
        print('Setting user language from getCurrentUserInfo to: $userLocale');
        languageNotifier.notifyLanguageChanged(userLocale);
      }
    } catch (e) {
      print('Error loading user: $e');
      // Mantener un usuario predeterminado para evitar romper la experiencia
      setState(() {
        _user = UserModel(
          id: widget.userId,
          email: 'user@example.com',
          name: 'Demo User',
          locale: 'en',
          verifiedEmail: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  void _refreshDashboard({bool useCache = false}) {
    // Log para diagnóstico antes de refrescar
    print(
      '🔄 Refreshing dashboard - Period: $_currentPeriod, Date: ${_selectedDate?.toString() ?? "now"}',
    );

    setState(() {
      _isDashboardLoading = true;

      // Usar datos locales simulados en lugar de hacer llamadas API
      _dashboardModel = _createMockDashboardData(_currentPeriod);
      _isDashboardLoading = false;

      print('✅ Dashboard refrescado con datos simulados locales');
    });
  }

  // Método para refrescar el BudgetOverviewWithPeriod
  Future<void> _refreshBudgetOverview() async {
    final budgetOverviewState = _budgetOverviewKey.currentState;
    if (budgetOverviewState != null) {
      // Usar dynamic para acceder al método público
      try {
        await (budgetOverviewState as dynamic).refreshBudgetData();
      } catch (e) {
        print('Error refreshing budget overview: $e');
      }
    }
  }

  void _onPeriodChanged(String period) {
    // Log del cambio de periodo para diagnóstico
    print('🕒 Period changed: $period (previous: $_currentPeriod)');

    setState(() {
      _currentPeriod = period;
    });

    // Usar datos de ejemplo locales en lugar de hacer llamadas API
    final mockData = _createMockDashboardData(period);
    setState(() {
      _dashboardModel = mockData;
      _isDashboardLoading = false;
    });
  }

  void _onDateChanged(DateTime date) {
    // Log del cambio de fecha para diagnóstico
    final oldDate =
        _selectedDate != null
            ? '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}'
            : 'null';
    final newDate = '${date.year}-${date.month}-${date.day}';
    print('📅 Date changed: $newDate (previous: $oldDate)');

    setState(() {
      _selectedDate = date;
    });

    // Usar datos de ejemplo locales en lugar de hacer llamadas API
    final mockData = _createMockDashboardData(_currentPeriod);
    setState(() {
      _dashboardModel = mockData;
      _isDashboardLoading = false;
    });
  }

  void _onCustomRangeSelected(DateTime startDate, DateTime endDate) {
    setState(() {
      _selectedDate = startDate;
      _currentPeriod = 'custom';
    });

    // Usar datos de ejemplo locales en lugar de hacer llamadas API
    final mockData = _createMockDashboardData('custom');
    setState(() {
      _dashboardModel = mockData;
      _isDashboardLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.tr.translate('custom_period')}: ${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}',
        ),
      ),
    );
  }

  // Método para crear datos simulados de dashboard
  DashboardModel _createMockDashboardData(String period) {
    // Datos simulados para BudgetOverview basados en el periodo
    final now = DateTime.now();
    final budgetOverview = _createMockBudgetOverview(period);

    // Datos simulados para el resto de los componentes
    return DashboardModel(
      period: period,
      date:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      budgetOverview: budgetOverview,
      savingsOverview: SavingsOverview(
        percent: 0.0,
        available: 0.0,
        goal: 0.0, // No goal set
        period: 'monthly',
        needToSave: 0.0,
        dailyTarget: 0.0,
      ),
      cashDistribution: _mockCashBankDistribution(),
      financeMetrics: _mockFinanceMetrics(),
      upcomingBills: _mockUpcomingBills(),
    );
  }

  // Crear datos simulados para BudgetOverview
  BudgetOverview _createMockBudgetOverview(String period) {
    // Adaptar los valores según el periodo
    double factor = 1.0;
    switch (period) {
      case 'daily':
        factor = 0.033;
        break;
      case 'weekly':
        factor = 0.25;
        break;
      case 'monthly':
        factor = 1.0;
        break;
      case 'quarterly':
        factor = 3.0;
        break;
      case 'semiannual':
        factor = 6.0;
        break;
      case 'annual':
        factor = 12.0;
        break;
      case 'custom':
        factor = 2.0;
        break;
    }

    final spentAmount = 3500.00 * factor;
    final upcomingAmount = 750.50 * factor;
    final totalAmount = 5000.00 * factor;
    final combinedExpense = spentAmount + upcomingAmount;
    final expensePercent = (combinedExpense / totalAmount) * 100;
    final totalIncome = totalAmount * 1.1; // 10% más de ingresos que gastos
    final remainingAmount = totalIncome - combinedExpense;

    return BudgetOverview(
      moneyFlow: MoneyFlow(percent: 5.5, fromPrevious: 495.80 * factor),
      remainingAmount: remainingAmount,
      totalAmount: totalAmount,
      spentAmount: spentAmount,
      upcomingAmount: upcomingAmount,
      combinedExpense: combinedExpense,
      expensePercent: expensePercent,
      dailyRate: combinedExpense / 30.0,
      highSpending: expensePercent > 90,
      totalIncome: totalIncome,
    );
  }

  // Datos simulados para CashBankDistribution
  CashBankDistribution _mockCashBankDistribution() {
    return CashBankDistribution(
      month: DateFormat('MMMM yyyy').format(DateTime.now()),
      cashAmount: 1200.0,
      cashPercent: 20.0,
      bankAmount: 4800.0,
      bankPercent: 80.0,
      monthlyTotal: 6000.0,
    );
  }

  // Datos simulados para FinanceMetrics
  FinanceMetrics _mockFinanceMetrics() {
    return FinanceMetrics(income: 5500.0, expenses: 3500.0, bills: 750.0);
  }

  // Datos simulados para UpcomingBills
  List<Bill> _mockUpcomingBills() {
    final now = DateTime.now();
    return [
      Bill(
        id: 1,
        name: 'Alquiler',
        amount: 850.0,
        dueDate:
            '${now.year}-${(now.month).toString().padLeft(2, '0')}-${(now.day + 5).toString().padLeft(2, '0')}',
        paid: false,
        overdue: false,
        overdueDays: 0,
        recurring: true,
        category: 'Vivienda',
        icon: 'home',
      ),
      Bill(
        id: 2,
        name: 'Internet',
        amount: 59.90,
        dueDate:
            '${now.year}-${(now.month).toString().padLeft(2, '0')}-${(now.day + 12).toString().padLeft(2, '0')}',
        paid: false,
        overdue: false,
        overdueDays: 0,
        recurring: true,
        category: 'Servicios',
        icon: 'wifi',
      ),
      Bill(
        id: 3,
        name: 'Teléfono',
        amount: 35.50,
        dueDate:
            '${now.year}-${(now.month).toString().padLeft(2, '0')}-${(now.day + 15).toString().padLeft(2, '0')}',
        paid: false,
        overdue: false,
        overdueDays: 0,
        recurring: true,
        category: 'Servicios',
        icon: 'phone',
      ),
    ];
  }

  // Formato consistente para las claves de caché
  String _formatDateForCache(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content (sin bottomNavigationBar)
          SafeArea(
            bottom: false, // No aplicar SafeArea en la parte inferior
            child: Column(
              children: [
                // App header
                AppHeader(user: _user),

                // Main content - Con padding inferior para dar espacio a la barra de navegación
                Expanded(
                  child:
                      _isDashboardLoading
                          ? _buildLoadingIndicator()
                          : _buildDashboardBody(),
                ),
              ],
            ),
          ),

          // Overlay oscuro cuando el menú de acciones rápidas está abierto
          if (_isQuickMenuExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleQuickMenu, // Cerrar el menú al tocar fuera
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      color: Colors.black.withOpacity(
                        0.5 * _animationController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Acciones rápidas - Aparecer en semicírculo cuando el menú está expandido
          if (_isQuickMenuExpanded) ..._buildQuickActions(),

          // Barra de navegación en la parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavigation(
              currentIndex: _currentNavigationIndex,
              onTabChanged: (index) {
                setState(() {
                  _currentNavigationIndex = index;
                });

                // Navegar a otras pantallas según el índice
                switch (index) {
                  case 0:
                    // Ya estamos en Dashboard/Home
                    break;
                  case 1:
                    // Mostrar mensaje sencillo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr.translate('expenses'))),
                    );
                    break;
                  case 2:
                    // Mostrar mensaje sencillo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr.translate('finance_metrics')),
                      ),
                    );
                    break;
                  case 3:
                    // Navegar a Perfil
                    Navigator.pushNamed(context, '/profile');
                    break;
                }
              },
            ),
          ),
        ],
      ),

      // Botón flotante de acciones rápidas
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleQuickMenu,
        backgroundColor:
            _isQuickMenuExpanded
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
        elevation: 8,
        child: AnimatedRotation(
          turns: _isQuickMenuExpanded ? 0.125 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Widget para mostrar indicador de carga
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.tr.translate('loading_data')),
        ],
      ),
    );
  }

  // Widget para construir el cuerpo principal del dashboard
  Widget _buildDashboardBody() {
    // Si no hay datos, crear datos simulados por defecto
    if (_dashboardModel == null) {
      _dashboardModel = _createMockDashboardData(_currentPeriod);
    }

    return _buildDashboardMainContent(_dashboardModel!);
  }

  // Build the dashboard main content with data
  Widget _buildDashboardMainContent(DashboardModel dashboardData) {
    return RefreshIndicator(
      onRefresh: () async {
        // Recargar con datos simulados en lugar de API
        setState(() {
          _dashboardModel = _createMockDashboardData(_currentPeriod);
          _isDashboardLoading = false;
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget overview integrado con period selector y fetch automático
            BudgetOverviewWithPeriod(key: _budgetOverviewKey),

            const SizedBox(height: 20),

            // Finance metrics
            FinanceMetricsWidget(metrics: dashboardData.financeMetrics),

            const SizedBox(height: 20),

            // Upcoming bills
            UpcomingBillsWidget(
              bills: dashboardData.upcomingBills,
              onAddBill: () {
                // Show modal to add bill
                _showAddBillDialog();
              },
            ),

            const SizedBox(height: 20),

            // Quick actions
            QuickActionsWidget(
              onIncomePressed: () {
                _showAddIncomeDialog();
              },
              onExpensePressed: () {
                _showAddExpenseDialog();
              },
              onPayBillPressed: () {
                _showPayBillDialog(dashboardData.upcomingBills);
              },
              onAddInvoicePressed: () {
                _showAddInvoiceDialog();
              },
              onAddCategoryPressed: () {
                _showAddCategoryDialog();
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Build quick actions in semicircle
  List<Widget> _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;

    // Radio del semicírculo donde se distribuirán las acciones
    final double radius = math.min(120, screenWidth * 0.35);

    // Posición base para las acciones (ajustar según sea necesario)
    const double baseBottomPosition =
        100; // Increased to match the taller navigation bar

    // Lista para almacenar los widgets de acciones
    List<Widget> actionWidgets = [];

    // Número de acciones
    final int numActions = _quickActions.length;

    for (int i = 0; i < numActions; i++) {
      // Distribuir las acciones en un semicírculo - parte inferior del círculo
      final double angle = math.pi + (math.pi * i / (numActions - 1));

      // Calcular la posición en el semicírculo
      final double x = radius * math.cos(angle);
      final double y = radius * math.sin(angle);

      final Map<String, dynamic> action = _quickActions[i];

      actionWidgets.add(
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Calcular posición con la animación
            double adjustedX = x * _animationController.value;
            double adjustedY = y * _animationController.value;

            // Centrar respecto al botón flotante
            double leftPosition = screenWidth / 2 - 28 + adjustedX;

            return Positioned(
              bottom: baseBottomPosition - adjustedY,
              left: leftPosition,
              child: Opacity(opacity: _animationController.value, child: child),
            );
          },
          child: _buildQuickActionItem(
            icon: action['icon'],
            label: action['label'],
            color: action['color'],
          ),
        ),
      );
    }

    return actionWidgets;
  }

  // Widget for each quick action item
  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _toggleQuickMenu(); // Close menu

              // Execute the corresponding action based on the label
              if (label == context.tr.translate('add_income')) {
                _showAddIncomeDialog();
              } else if (label == context.tr.translate('add_expense')) {
                _showAddExpenseDialog();
              } else if (label == context.tr.translate('pay_bill')) {
                _showPayBillDialog(_dashboardModel?.upcomingBills ?? []);
              } else if (label == context.tr.translate('add_invoice')) {
                _showAddInvoiceDialog();
              } else if (label == context.tr.translate('add_category')) {
                _showAddCategoryDialog();
              }
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Dialog to add bill
  void _showAddBillDialog() {
    // Implementación simplificada, mostrar solo un mensaje
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.translate('add_bill'))));
  }

  // Dialog to add income
  void _showAddIncomeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddIncomeScreen(
              onSuccess: () {
                // Refresh dashboard data when a new income is added
                _refreshDashboard();
              },
            ),
      ),
    );
  }

  // Dialog to add expense
  void _showAddExpenseDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddExpenseScreen(
              onSuccess: () {
                // Refresh dashboard data when a new expense is added
                _refreshDashboard();
              },
            ),
      ),
    );
  }

  // Dialog to pay bill
  void _showPayBillDialog(List<Bill> bills) {
    if (bills.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.translate('no_bills'))));
      return;
    }

    // Navegar a la pantalla de pago de facturas
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PayBillScreen()),
    ).then((result) {
      // Si regresa con éxito (true), actualizar el dashboard
      if (result == true) {
        _refreshDashboard();
      }
    });
  }

  // Dialog to add invoice
  void _showAddInvoiceDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddInvoiceScreen(
              onSuccess: () {
                // Cuando se añade una factura correctamente, actualizamos los datos del dashboard
                _refreshDashboard();
              },
            ),
      ),
    );
  }

  // Dialog to add category
  void _showAddCategoryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddCategoryScreen(
              onSuccess: () {
                // No need to do anything special for now
              },
            ),
      ),
    );
  }

  // Show a snackbar with the action label
  void _showActionSnackbar(String label) {
    // Get currency symbol for current locale
    final String currencySymbol = CurrencyUtils.getCurrencySymbolForLocale(
      Localizations.localeOf(context),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.tr.translate('action')}: ${label}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Método para convertir el BudgetOverview del backend al modelo local
  widget_budget.BudgetOverview _createLocalBudgetOverview(
    BudgetOverview backendModel,
  ) {
    return widget_budget.BudgetOverview(
      remainingAmount: backendModel.remainingAmount,
      expensePercent: backendModel.expensePercent,
      spentAmount: backendModel.spentAmount,
      upcomingAmount: backendModel.upcomingAmount,
      totalAmount: backendModel.totalAmount,
      combinedExpense: backendModel.combinedExpense,
      totalIncome: backendModel.totalIncome,
      dailyRate: backendModel.dailyRate,
      highSpending: backendModel.highSpending,
      moneyFlow: widget_budget.MoneyFlow(
        fromPrevious: backendModel.moneyFlow.fromPrevious,
      ),
      cashBankDistribution: widget_budget.PeriodCashBankDistribution(
        cashAmount: _dashboardModel?.cashDistribution.cashAmount ?? 0.0,
        cashPercent: _dashboardModel?.cashDistribution.cashPercent ?? 0.0,
        bankAmount: _dashboardModel?.cashDistribution.bankAmount ?? 0.0,
        bankPercent: _dashboardModel?.cashDistribution.bankPercent ?? 0.0,
        totalAmount: _dashboardModel?.cashDistribution.monthlyTotal ?? 0.0,
      ),
      savingsData: widget_budget.PeriodSavingsData(
        available: _dashboardModel?.savingsOverview.available ?? 0.0,
        goal: _dashboardModel?.savingsOverview.goal ?? 0.0,
        percent: _dashboardModel?.savingsOverview.percent ?? 0.0,
        totalBalance: backendModel.totalAmount,
      ),
    );
  }

  // Dialog to transfer between cash and bank
  void _showTransferDialog(CashBankDistribution distribution) {
    final amountController = TextEditingController();
    bool isCashToBank = true;

    // Get currency symbol for current locale
    final String currencySymbol = CurrencyUtils.getCurrencySymbolForLocale(
      Localizations.localeOf(context),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.tr.translate('transfer_money')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle to select transfer direction
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(context.tr.translate('cash_to_bank')),
                          selected: isCashToBank,
                          onSelected: (selected) {
                            setState(() {
                              isCashToBank = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text(context.tr.translate('bank_to_cash')),
                          selected: !isCashToBank,
                          onSelected: (selected) {
                            setState(() {
                              isCashToBank = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr.translate('amount'),
                      prefixText: currencySymbol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCashToBank
                        ? '${context.tr.translate('available_cash')}: ${currencySymbol}${distribution.cashAmount.toStringAsFixed(2)}'
                        : '${context.tr.translate('available_in_bank')}: ${currencySymbol}${distribution.bankAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      final double amount = double.parse(amountController.text);

                      // Check if there's enough money to transfer
                      if (isCashToBank && amount > distribution.cashAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr.translate('not_enough_cash'),
                            ),
                          ),
                        );
                        return;
                      } else if (!isCashToBank &&
                          amount > distribution.bankAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr.translate('not_enough_bank'),
                            ),
                          ),
                        );
                        return;
                      }

                      // Perform the transfer using the service
                      final Future<bool> transferFuture =
                          isCashToBank
                              ? _cashBankService.transferCashToBank(amount)
                              : _cashBankService.transferBankToCash(amount);

                      transferFuture
                          .then((success) {
                            if (success) {
                              _refreshDashboard();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${context.tr.translate('transfer_successful')} ${currencySymbol}${amount.toStringAsFixed(2)}',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr.translate('transfer_failed'),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          })
                          .catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${context.tr.translate('transfer_failed')}: ${error.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr.translate('please_enter_valid_amount'),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(context.tr.translate('transfer')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
