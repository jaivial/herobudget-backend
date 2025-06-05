import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/extensions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/savings_overview_with_period.dart';

class SavingsOverviewScreen extends StatefulWidget {
  const SavingsOverviewScreen({super.key});

  @override
  State<SavingsOverviewScreen> createState() => _SavingsOverviewScreenState();
}

class _SavingsOverviewScreenState extends State<SavingsOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.backgroundDark : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(context.tr.translate('savings_overview')),
        backgroundColor: isDarkMode ? AppTheme.surfaceDark : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        systemOverlayStyle:
            isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? AppTheme.primaryColorDark.withOpacity(0.2)
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
                            context.tr.translate('savings_management'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            context.tr.translate('track_your_savings_goals'),
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
              ),

              const SizedBox(height: 24),

              // Savings Overview with Period Selector
              const SavingsOverviewWithPeriodSelector(),

              const SizedBox(height: 24),

              // Tips section
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
                        Icon(
                          Icons.lightbulb_outline,
                          color:
                              isDarkMode
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr.translate('savings_tips'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context,
                      isDarkMode,
                      context.tr.translate('tip_set_realistic_goals'),
                    ),
                    _buildTip(
                      context,
                      isDarkMode,
                      context.tr.translate('tip_automate_savings'),
                    ),
                    _buildTip(
                      context,
                      isDarkMode,
                      context.tr.translate('tip_track_progress_regularly'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, bool isDarkMode, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDarkMode
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
