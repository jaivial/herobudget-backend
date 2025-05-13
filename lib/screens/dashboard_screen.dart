import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../models/user_model.dart';
import '../services/dashboard_service.dart';
import '../services/savings_service.dart';
import '../services/cash_bank_service.dart';
import '../services/bills_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/budget_overview.dart';
import '../widgets/cash_bank_distribution.dart';
import '../widgets/finance_metrics.dart';
import '../widgets/period_selector.dart';
import '../widgets/quick_actions.dart';
import '../widgets/savings_overview.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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

  // Control del menú de acciones rápidas
  bool _isQuickMenuExpanded = false;
  late AnimationController _animationController;

  // Definición de acciones rápidas
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.add_card, 'label': 'Ingreso', 'color': Colors.green},
    {'icon': Icons.shopping_bag, 'label': 'Gasto', 'color': Colors.red},
    {'icon': Icons.receipt, 'label': 'Factura', 'color': Colors.blue},
    {'icon': Icons.category, 'label': 'Categoría', 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _refreshDashboard();

    // Inicializar el controlador de animación para el overlay y las acciones rápidas
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Alternar el estado del menú de acciones rápidas
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

  Future<void> _loadUser() async {
    try {
      final userInfo = await DashboardService.getCurrentUserInfo();
      setState(() {
        _user = userInfo;
      });
    } catch (e) {
      print('Error loading user: $e');
      // En caso de error, mantener un usuario por defecto para no interrumpir la experiencia
      setState(() {
        _user = UserModel(
          id: '1',
          email: 'user@example.com',
          name: 'Usuario Demo',
          locale: 'es',
          verifiedEmail: true,
        );
      });
    }
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _dashboardService.fetchDashboardData(
        period: _currentPeriod,
      );
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
    // Esto requeriría endpoints adicionales en el backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rango personalizado: ${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Contenido principal (sin bottomNavigationBar)
          SafeArea(
            bottom:
                false, // Importante: no aplicar SafeArea en la parte inferior
            child: Column(
              children: [
                // Cabecero de la aplicación
                AppHeader(
                  user: _user,
                  onLanguageChanged: (locale) {
                    // Cambiar idioma
                  },
                ),

                // Contenido principal - Con padding inferior para dar espacio a la barra de navegación
                Expanded(
                  child: FutureBuilder<DashboardModel>(
                    future: _dashboardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshDashboard,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData) {
                        return const Center(
                          child: Text('No hay datos disponibles'),
                        );
                      }

                      // Datos del dashboard
                      final dashboardData = snapshot.data!;

                      return RefreshIndicator(
                        onRefresh: () async {
                          _refreshDashboard();
                        },
                        child: ListView(
                          // Añadir padding inferior para compensar la barra de navegación
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom:
                                90, // Suficiente espacio para la barra de navegación
                          ),
                          children: [
                            // Selector de periodo
                            PeriodSelector(
                              initialPeriod: _currentPeriod,
                              onPeriodChanged: _onPeriodChanged,
                              onCustomRangeSelected: _onCustomRangeSelected,
                            ),

                            const SizedBox(height: 20),

                            // Resumen de presupuesto
                            BudgetOverviewWidget(
                              budgetOverview: dashboardData.budgetOverview,
                            ),

                            const SizedBox(height: 20),

                            // Resumen de ahorros
                            SavingsOverviewWidget(
                              savingsOverview: dashboardData.savingsOverview,
                              onEditGoal: () {
                                // Mostrar diálogo para editar meta
                                _showEditGoalDialog(
                                  dashboardData.savingsOverview.goal,
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Distribución de efectivo y banco
                            CashBankDistributionWidget(
                              distribution: dashboardData.cashDistribution,
                              onTransferTap: () {
                                // Mostrar diálogo para transferir entre efectivo y banco
                                _showTransferDialog(
                                  dashboardData.cashDistribution,
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Métricas financieras
                            FinanceMetricsWidget(
                              metrics: dashboardData.financeMetrics,
                            ),

                            const SizedBox(height: 20),

                            // Facturas próximas
                            UpcomingBillsWidget(
                              bills: dashboardData.upcomingBills,
                              onAddBill: () {
                                // Mostrar modal para agregar factura
                                _showAddBillDialog();
                              },
                            ),

                            const SizedBox(height: 20),

                            // Acciones rápidas
                            QuickActionsWidget(
                              onIncomePressed: () {
                                // Lógica para registrar ingreso
                                _showAddIncomeDialog();
                              },
                              onExpensePressed: () {
                                // Lógica para registrar gasto
                                _showAddExpenseDialog();
                              },
                              onPayBillPressed: () {
                                // Lógica para pagar factura
                                _showPayBillDialog(dashboardData.upcomingBills);
                              },
                              onAddCategoryPressed: () {
                                // Lógica para agregar categoría
                                _showAddCategoryDialog();
                              },
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
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
          if (_isQuickMenuExpanded) ..._buildQuickActions(screenWidth),

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
                    // Navegar a Transacciones
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navegando a Transacciones'),
                      ),
                    );
                    break;
                  case 2:
                    // Navegar a Estadísticas
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navegando a Estadísticas')),
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
        onPressed: () {
          print("FloatingActionButton pressed");
          _toggleQuickMenu();
        },
        backgroundColor:
            _isQuickMenuExpanded
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
        elevation: 8,
        child: AnimatedRotation(
          turns:
              _isQuickMenuExpanded
                  ? 0.125
                  : 0, // Rotación de 45 grados cuando está expandido
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.add, // Siempre usar el icono +, al rotarlo se verá como una x
            size: 35,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Construir las acciones rápidas en semicírculo
  List<Widget> _buildQuickActions(double screenWidth) {
    // Radio del semicírculo donde se distribuirán las acciones
    final double radius = math.min(120, screenWidth * 0.35);

    // Posición base para las acciones (ajustar según sea necesario)
    const double baseBottomPosition = 90;

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

  // Widget para cada elemento de acción rápida
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
              _toggleQuickMenu(); // Cerrar el menú

              // Mostrar feedback de la acción seleccionada
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Acción: $label')));
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

  // Diálogo para editar meta de ahorro
  void _showEditGoalDialog(double currentGoal) {
    final TextEditingController controller = TextEditingController(
      text: currentGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Savings Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Goal Amount',
              prefixText: '\$',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                try {
                  final double newGoal = double.parse(controller.text);
                  // Usar el nuevo servicio de ahorros
                  _savingsService.updateSavingsGoal(newGoal).then((success) {
                    if (success) {
                      _refreshDashboard();
                      Navigator.pop(context);
                    }
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para transferir entre efectivo y banco
  void _showTransferDialog(CashBankDistribution distribution) {
    final amountController = TextEditingController();
    bool isCashToBank = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Transfer Money'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle para seleccionar dirección de transferencia
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Cash to Bank'),
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
                          label: const Text('Bank to Cash'),
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
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCashToBank
                        ? 'Available cash: \$${distribution.cashAmount.toStringAsFixed(2)}'
                        : 'Available in bank: \$${distribution.bankAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      final double amount = double.parse(amountController.text);

                      // Verificar si hay suficiente dinero para transferir
                      if (isCashToBank && amount > distribution.cashAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough cash available'),
                          ),
                        );
                        return;
                      } else if (!isCashToBank &&
                          amount > distribution.bankAmount) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough bank balance available'),
                          ),
                        );
                        return;
                      }

                      // Realizar la transferencia usando el nuevo servicio
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
                                'Successfully transferred \$${amount.toStringAsFixed(2)}',
                              ),
                            ),
                          );
                        }
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                    }
                  },
                  child: const Text('Transfer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para agregar factura
  void _showAddBillDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final dueDateController = TextEditingController(
      text:
          DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0],
    );
    String selectedCategory = 'Utilities';
    String selectedIcon = '🏠';
    bool isRecurring = false;

    final List<String> categories = [
      'Utilities',
      'Housing',
      'Transportation',
      'Food',
      'Healthcare',
      'Insurance',
      'Entertainment',
      'Other',
    ];

    final List<String> icons = ['🏠', '💧', '⚡', '🚗', '🏥', '🎮', '📱', '💼'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Add New Bill',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Bill Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Due Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 7),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          dueDateController.text =
                              date.toString().split(' ')[0];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Icon'),
                  Wrap(
                    spacing: 8,
                    children:
                        icons.map((icon) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedIcon = icon;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      selectedIcon == icon
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Colors.grey.shade300,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Recurring Bill'),
                    value: isRecurring,
                    onChanged: (value) {
                      setState(() {
                        isRecurring = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                            return;
                          }

                          try {
                            final double amount = double.parse(
                              amountController.text,
                            );

                            // Usar el nuevo servicio de facturas
                            _billsService
                                .addBill(
                                  name: nameController.text,
                                  amount: amount,
                                  dueDate: dueDateController.text,
                                  category: selectedCategory,
                                  icon: selectedIcon,
                                  recurring: isRecurring,
                                )
                                .then((success) {
                                  if (success) {
                                    _refreshDashboard();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Bill added successfully',
                                        ),
                                      ),
                                    );
                                  }
                                });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount'),
                              ),
                            );
                          }
                        },
                        child: const Text('Add Bill'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Diálogo para agregar ingreso
  void _showAddIncomeDialog() {
    // Implementación similar a _showAddBillDialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add Income dialog')));
  }

  // Diálogo para agregar gasto
  void _showAddExpenseDialog() {
    // Implementación similar a _showAddBillDialog
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add Expense dialog')));
  }

  // Diálogo para pagar factura
  void _showPayBillDialog(List<Bill> bills) {
    if (bills.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No bills to pay')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Bill to Pay',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return ListTile(
                      leading: Text(
                        bill.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(bill.name),
                      subtitle: Text('Due: ${bill.dueDate}'),
                      trailing: Text('\$${bill.amount.toStringAsFixed(2)}'),
                      onTap: () {
                        // Usar el nuevo servicio de facturas
                        _billsService.payBill(bill.id).then((success) {
                          if (success) {
                            _refreshDashboard();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Paid ${bill.name} successfully'),
                              ),
                            );
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Diálogo para agregar categoría
  void _showAddCategoryDialog() {
    // Implementación del diálogo
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add Category dialog')));
  }
}
