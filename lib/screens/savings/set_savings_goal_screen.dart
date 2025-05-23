import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/savings_service.dart';
import '../../utils/app_localizations.dart';
import '../../theme/app_theme.dart';

class SetSavingsGoalScreen extends StatefulWidget {
  const SetSavingsGoalScreen({super.key});

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
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.translate('user_not_authenticated')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final goalText = _goalController.text.trim();
    if (goalText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.translate('please_enter_goal_amount')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final goal = double.tryParse(goalText);
    if (goal == null || goal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.translate('please_enter_valid_amount')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedSavingsData = await _savingsService.setSavingsGoal(
        _userId!,
        goal,
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

        // Return the updated data to the previous screen
        Navigator.of(context).pop(updatedSavingsData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr.translate('error_updating_savings_goal')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                                    '${_currentSavingsData!.percent.toStringAsFixed(1)}%',
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
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
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

                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color:
                                    isDarkMode
                                        ? Colors.grey.withOpacity(0.5)
                                        : Colors.grey.shade400,
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
                                color: isDarkMode ? Colors.white : Colors.black,
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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
                  ],
                ),
              ),
    );
  }
}
