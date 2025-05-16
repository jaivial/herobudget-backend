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
import '../../widgets/budget_overview.dart';
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Start with the passed userInfo
    _latestUserInfo = widget.userInfo;

    // Then fetch latest user info and dashboard data
    _fetchLatestUserInfo();
    _loadUser();
    _refreshDashboard();
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

  void _refreshDashboard() {
    setState(() {
      _isDashboardLoading = true;
      _dashboardFuture = _dashboardService.fetchDashboardData(
        period: _currentPeriod,
      );

      // Cargar los datos de inmediato para tenerlos disponibles
      _dashboardFuture
          .then((data) {
            if (mounted) {
              setState(() {
                _dashboardModel = data;
                _isDashboardLoading = false;
              });
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _dashboardErrorMessage = error.toString();
                _isDashboardLoading = false;
              });
            }
          });
    });
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _currentPeriod = period;
    });
    _refreshDashboard();
  }

  void _onCustomRangeSelected(DateTime startDate, DateTime endDate) {
    // Lógica para manejar rango personalizado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.tr.translate('custom_period')}: ${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}',
        ),
      ),
    );
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
    if (_dashboardModel == null) {
      return Center(child: Text(context.tr.translate('no_data_available')));
    }

    return _buildDashboardMainContent(_dashboardModel!);
  }

  // Build the dashboard main content with data
  Widget _buildDashboardMainContent(DashboardModel dashboardData) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshDashboard();
      },
      child: ListView(
        // Add bottom padding to compensate for navigation bar
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100, // Increased space for navigation bar with bottom margin
        ),
        children: [
          // Period selector
          PeriodSelector(
            initialPeriod: _currentPeriod,
            onPeriodChanged: _onPeriodChanged,
            onCustomRangeSelected: _onCustomRangeSelected,
          ),

          const SizedBox(height: 20),

          // Budget overview
          BudgetOverviewWidget(budgetOverview: dashboardData.budgetOverview),

          const SizedBox(height: 20),

          // Savings overview
          SavingsOverviewWidget(
            savingsOverview: dashboardData.savingsOverview,
            onEditGoal: () {
              // Show dialog to edit goal
              _showEditGoalDialog(dashboardData.savingsOverview.goal);
            },
          ),

          const SizedBox(height: 20),

          // Cash and bank distribution
          CashBankDistributionWidget(
            distribution: dashboardData.cashDistribution,
            onTransferTap: () {
              // Show dialog to transfer between cash and bank
              _showTransferDialog(dashboardData.cashDistribution);
            },
          ),

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
            onAddCategoryPressed: () {
              _showAddCategoryDialog();
            },
          ),

          const SizedBox(height: 20),
        ],
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

              // Show feedback for selected action
              _showActionSnackbar(label);
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

  // Dialog to edit savings goal
  void _showEditGoalDialog(double currentGoal) {
    final TextEditingController controller = TextEditingController(
      text: currentGoal.toString(),
    );

    // Get currency symbol for current locale
    final String currencySymbol = CurrencyUtils.getCurrencySymbolForLocale(
      Localizations.localeOf(context),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr.translate('edit_goal')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.tr.translate('goal_amount'),
              prefixText: currencySymbol,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final double newGoal = double.parse(controller.text);
                  _savingsService.updateSavingsGoal(newGoal).then((success) {
                    if (success) {
                      _refreshDashboard();
                      Navigator.pop(context);
                    }
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
              child: Text(context.tr.translate('save')),
            ),
          ],
        );
      },
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

                      transferFuture.then((success) {
                        if (success) {
                          _refreshDashboard();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${context.tr.translate('transfer_successful')} ${currencySymbol}${amount.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                        }
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

  // Dialog to add bill
  void _showAddBillDialog() {
    // Implementación simplificada, mostrar solo un mensaje
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.translate('add_bill'))));
  }

  // Dialog to add income
  void _showAddIncomeDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.translate('add_income_dialog'))),
    );
  }

  // Dialog to add expense
  void _showAddExpenseDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.translate('add_expense_dialog'))),
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

    // Mostrar solo un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.translate('select_bill_to_pay'))),
    );
  }

  // Dialog to add category
  void _showAddCategoryDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.translate('add_category_dialog'))),
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
}
