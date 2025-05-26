import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/savings_service.dart';
import '../../utils/app_localizations.dart';
import '../../utils/savings_period_calculator.dart';
import '../../theme/app_theme.dart';

// Custom formatter que maneja decimales de manera más robusta
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Permitir texto vacío
    if (newText.isEmpty) {
      return newValue;
    }

    // Permitir solo backspace sin restricciones adicionales
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Remover caracteres no válidos (solo dígitos y punto)
    String filteredText = newText.replaceAll(RegExp(r'[^\d.]'), '');

    // Si no hay cambios después del filtro, mantener el valor original
    if (filteredText == oldValue.text) {
      return oldValue;
    }

    // Prevenir múltiples puntos decimales
    int dotCount = '.'.allMatches(filteredText).length;
    if (dotCount > 1) {
      return oldValue;
    }

    // Si hay un punto, verificar que no haya más decimales de los permitidos
    if (filteredText.contains('.')) {
      List<String> parts = filteredText.split('.');
      if (parts.length == 2 && parts[1].length > decimalRange) {
        return oldValue;
      }
    }

    // Prevenir punto al inicio (solo si no es una operación de borrado)
    if (filteredText.startsWith('.') && filteredText.length > 1) {
      filteredText = '0$filteredText';
    }

    // Calcular la nueva posición del cursor de manera más segura
    int newOffset = newValue.selection.baseOffset;
    if (filteredText.length != newValue.text.length) {
      newOffset = filteredText.length;
    }

    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(
        offset: newOffset.clamp(0, filteredText.length),
      ),
    );
  }
}

class SetSavingsGoalScreen extends StatefulWidget {
  final double? totalBalance; // Dynamic balance from budget overview

  const SetSavingsGoalScreen({super.key, this.totalBalance});

  @override
  State<SetSavingsGoalScreen> createState() => _SetSavingsGoalScreenState();
}

class _SetSavingsGoalScreenState extends State<SetSavingsGoalScreen> {
  final TextEditingController _goalController = TextEditingController();
  final SavingsService _savingsService = SavingsService();
  bool _isLoading = false;
  bool _isLoadingCurrentData = true;
  SavingsData? _currentSavingsData;
  String? _userId;
  String _selectedPeriod = 'monthly';
  bool _isEditingExistingGoal = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSavingsData();
  }

  Future<void> _loadCurrentSavingsData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');

      if (_userId != null) {
        final savingsData = await _savingsService.getSavingsData(_userId!);
        setState(() {
          _currentSavingsData = savingsData;
          if (savingsData.goal > 0) {
            _goalController.text = savingsData.goal.toStringAsFixed(2);
            _selectedPeriod = savingsData.period;
            _isEditingExistingGoal = true;
          }
          _isLoadingCurrentData = false;
        });
      } else {
        setState(() {
          _isLoadingCurrentData = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr.translate('user_not_authenticated')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingCurrentData = false;
      });
      print('Error loading current savings data: $e');
    }
  }

  Future<void> _setSavingsGoal() async {
    String goalText = _goalController.text.trim();

    if (goalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.translate('please_enter_goal_amount')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Limpiar el texto y manejar casos edge
    goalText = goalText.replaceAll(RegExp(r'[^\d.]'), '');

    // Remover punto al final si existe
    if (goalText.endsWith('.')) {
      goalText = goalText.substring(0, goalText.length - 1);
    }

    // Si el texto está vacío después de la limpieza
    if (goalText.isEmpty ||
        goalText == '0' ||
        goalText == '0.0' ||
        goalText == '0.00') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.translate('please_enter_valid_amount')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final double goal = double.parse(goalText);

      if (goal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.translate('please_enter_valid_amount')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Update savings goal with period
      await _savingsService.setSavingsGoalWithPeriod(
        _userId!,
        goal,
        _selectedPeriod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.translate('savings_goal_updated_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.translate('error_updating_savings_goal')),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error setting savings goal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppTheme.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr.translate('delete_savings_goal'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            context.tr.translate('delete_savings_goal_confirmation'),
            style: TextStyle(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.tr.translate('cancel'),
                style: TextStyle(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSavingsGoal();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                context.tr.translate('delete'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSavingsGoal() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _savingsService.deleteSavingsGoal(_userId!);

      if (mounted) {
        // Reset the form to creation mode
        setState(() {
          _currentSavingsData = SavingsData(
            userId: _userId!,
            available: 0,
            goal: 0,
            period: 'monthly',
            percent: 0,
            needToSave: 0,
            dailyTarget: 0,
          );
          _goalController.clear();
          _selectedPeriod = 'monthly';
          _isEditingExistingGoal = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.translate('savings_goal_deleted_successfully'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.translate('error_deleting_savings_goal')),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error deleting savings goal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPeriodSelector() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  context.tr.translate('select_savings_period'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Period options
                ...SavingsPeriodCalculator.getAllPeriods().map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        context.tr.translate(period),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color:
                                    isDarkMode
                                        ? AppTheme.primaryColorDark
                                        : Colors.blue.shade600,
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor:
                          isSelected
                              ? (isDarkMode
                                  ? AppTheme.primaryColorDark.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1))
                              : null,
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.backgroundDark : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(context.tr.translate('set_savings_goal')),
        backgroundColor: isDarkMode ? AppTheme.surfaceDark : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
          if (_isEditingExistingGoal && !_isLoading)
            IconButton(
              onPressed: _showDeleteConfirmationDialog,
              icon: const Icon(Icons.delete_outline),
              tooltip: context.tr.translate('delete_savings_goal'),
              color: Colors.red,
            ),
        ],
      ),
      body:
          _isLoadingCurrentData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? AppTheme.primaryColorDark
                                              .withOpacity(0.2)
                                          : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.savings,
                                  color:
                                      isDarkMode
                                          ? AppTheme.primaryColorDark
                                          : Colors.blue.shade600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr.translate('savings_goal'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      context.tr.translate(
                                        'set_your_financial_target',
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isDarkMode
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current savings info (if available)
                    if (_currentSavingsData != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? AppTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.translate('current_savings_info'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr.translate('current_goal'),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  context.tr.formatCurrency(
                                    _currentSavingsData!.goal,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr.translate('available_savings'),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  context.tr.formatCurrency(
                                    widget.totalBalance ??
                                        _currentSavingsData!.available,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDarkMode
                                            ? AppTheme.primaryColorDark
                                            : Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (_currentSavingsData!.goal > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.tr.translate('progress'),
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? Colors.white.withOpacity(0.7)
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${_calculateProgressPercentage().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Goal input section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
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
                            context.tr.translate('new_savings_goal'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr.translate('enter_target_amount'),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Amount input field
                          TextFormField(
                            controller: _goalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              DecimalTextInputFormatter(decimalRange: 2),
                            ],
                            onChanged: (value) {
                              // Validación adicional en tiempo real si es necesario
                              if (value.isNotEmpty) {
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  // Si hay un error de parsing, no hacer nada
                                  // El formatter ya debería haber manejado esto
                                }
                              }
                            },
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              labelText: context.tr.translate('goal_amount'),
                              hintText: '0.00',
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color:
                                    isDarkMode
                                        ? AppTheme.primaryColorDark
                                        : Colors.blue.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      isDarkMode
                                          ? Colors.grey.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      isDarkMode
                                          ? AppTheme.primaryColorDark
                                          : Colors.blue.shade600,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  isDarkMode
                                      ? AppTheme.backgroundDark.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.05),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Period selector section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
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
                            context.tr.translate('savings_period'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr.translate('select_savings_period'),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Period selection selector
                          Center(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      isDarkMode
                                          ? Colors.grey.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    isDarkMode
                                        ? AppTheme.backgroundDark.withOpacity(
                                          0.3,
                                        )
                                        : Colors.grey.withOpacity(0.05),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _showPeriodSelector,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          color:
                                              isDarkMode
                                                  ? AppTheme.primaryColorDark
                                                  : Colors.blue.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            context.tr.translate(
                                              _selectedPeriod,
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color:
                                              isDarkMode
                                                  ? Colors.white.withOpacity(
                                                    0.7,
                                                  )
                                                  : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                side: BorderSide(
                                  color:
                                      isDarkMode
                                          ? Colors.grey.withOpacity(0.5)
                                          : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.tr.translate('cancel'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _setSavingsGoal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDarkMode
                                        ? AppTheme.primaryColorDark
                                        : Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        context.tr.translate('save_goal'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  double _calculateProgressPercentage() {
    if (_currentSavingsData == null || _currentSavingsData!.goal <= 0) {
      return 0.0;
    }

    final double currentSavings =
        widget.totalBalance ?? _currentSavingsData!.available;
    final double goal = _currentSavingsData!.goal;

    return (currentSavings / goal) * 100;
  }
}
