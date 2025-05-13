import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_localizations.dart';

class PeriodSelector extends StatefulWidget {
  final String initialPeriod;
  final Function(String) onPeriodChanged;
  final Function(DateTime, DateTime) onCustomRangeSelected;

  const PeriodSelector({
    super.key,
    this.initialPeriod = 'monthly',
    required this.onPeriodChanged,
    required this.onCustomRangeSelected,
  });

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  late String _currentPeriod;
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.initialPeriod;
  }

  // Obtener el título del periodo actual
  String get periodTitle {
    final DateFormat formatter = DateFormat.yMMM();

    switch (_currentPeriod) {
      case 'daily':
        return DateFormat.yMd().format(_currentDate);
      case 'weekly':
        final startOfWeek = _currentDate.subtract(
          Duration(days: _currentDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}';
      case 'monthly':
        return formatter.format(_currentDate);
      case 'quarterly':
        final quarter = ((_currentDate.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${_currentDate.year}';
      case 'semiannual':
        final half = (_currentDate.month <= 6) ? 1 : 2;
        return 'H$half ${_currentDate.year}';
      case 'annual':
        return _currentDate.year.toString();
      case 'custom':
        return context.tr.translate('custom_period');
      default:
        return formatter.format(_currentDate);
    }
  }

  // Navegar al periodo anterior
  void _navigateToPreviousPeriod() {
    setState(() {
      switch (_currentPeriod) {
        case 'daily':
          _currentDate = _currentDate.subtract(const Duration(days: 1));
          break;
        case 'weekly':
          _currentDate = _currentDate.subtract(const Duration(days: 7));
          break;
        case 'monthly':
          _currentDate = DateTime(
            _currentDate.year,
            _currentDate.month - 1,
            _currentDate.day,
          );
          break;
        case 'quarterly':
          _currentDate = DateTime(
            _currentDate.year,
            _currentDate.month - 3,
            _currentDate.day,
          );
          break;
        case 'semiannual':
          _currentDate = DateTime(
            _currentDate.year,
            _currentDate.month - 6,
            _currentDate.day,
          );
          break;
        case 'annual':
          _currentDate = DateTime(
            _currentDate.year - 1,
            _currentDate.month,
            _currentDate.day,
          );
          break;
      }
    });
    widget.onPeriodChanged(_currentPeriod);
  }

  // Navegar al periodo siguiente
  void _navigateToNextPeriod() {
    final now = DateTime.now();
    DateTime nextDate;

    switch (_currentPeriod) {
      case 'daily':
        nextDate = _currentDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDate = _currentDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        nextDate = DateTime(
          _currentDate.year,
          _currentDate.month + 1,
          _currentDate.day,
        );
        break;
      case 'quarterly':
        nextDate = DateTime(
          _currentDate.year,
          _currentDate.month + 3,
          _currentDate.day,
        );
        break;
      case 'semiannual':
        nextDate = DateTime(
          _currentDate.year,
          _currentDate.month + 6,
          _currentDate.day,
        );
        break;
      case 'annual':
        nextDate = DateTime(
          _currentDate.year + 1,
          _currentDate.month,
          _currentDate.day,
        );
        break;
      default:
        return;
    }

    // Solo permitir avanzar hasta la fecha actual
    if (nextDate.isAfter(now)) {
      return;
    }

    setState(() {
      _currentDate = nextDate;
    });
    widget.onPeriodChanged(_currentPeriod);
  }

  // Cambiar el tipo de periodo
  void _changePeriodType(String periodType) {
    setState(() {
      _currentPeriod = periodType;
      _currentDate = DateTime.now(); // Resetear a la fecha actual
    });
    widget.onPeriodChanged(_currentPeriod);
  }

  // Mostrar el selector de rango personalizado
  void _showCustomRangeSelector() {
    // Configurar fechas iniciales
    DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime endDate = DateTime.now();
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.translate('select_date_range'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de fecha de inicio
                  ListTile(
                    title: Text(
                      context.tr.translate('start_date'),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.9) : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(startDate),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.7) : null,
                      ),
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color:
                          isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2010),
                        lastDate: endDate,
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          startDate = pickedDate;
                        });
                      }
                    },
                  ),

                  // Selector de fecha de fin
                  ListTile(
                    title: Text(
                      context.tr.translate('end_date'),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.9) : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().format(endDate),
                      style: TextStyle(
                        color:
                            isDarkMode ? Colors.white.withOpacity(0.7) : null,
                      ),
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color:
                          isDarkMode
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setModalState(() {
                          endDate = pickedDate;
                        });
                      }
                    },
                  ),

                  const Spacer(),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDarkMode
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                        ),
                        child: Text(context.tr.translate('cancel')),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPeriod = 'custom';
                          });
                          Navigator.pop(context);
                          widget.onCustomRangeSelected(startDate, endDate);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(context.tr.translate('apply')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Controles de navegación de periodo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón de periodo anterior
            IconButton(
              onPressed: _navigateToPreviousPeriod,
              icon: const Icon(Icons.chevron_left),
              tooltip: context.tr.translate('previous_period'),
            ),

            // Título del periodo actual
            Expanded(
              child: GestureDetector(
                onTap: () => _showCustomRangeSelector(),
                child: Text(
                  periodTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    // Mejorar contraste en modo oscuro
                    color: isDarkMode ? Colors.white : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Botón de periodo siguiente
            IconButton(
              onPressed: _navigateToNextPeriod,
              icon: const Icon(Icons.chevron_right),
              tooltip: context.tr.translate('next_period'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Selector de tipo de periodo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PeriodTypeButton(
                label: context.tr.translate('daily_period'),
                isSelected: _currentPeriod == 'daily',
                onTap: () => _changePeriodType('daily'),
              ),
              _PeriodTypeButton(
                label: context.tr.translate('weekly_period'),
                isSelected: _currentPeriod == 'weekly',
                onTap: () => _changePeriodType('weekly'),
              ),
              _PeriodTypeButton(
                label: context.tr.translate('monthly_period'),
                isSelected: _currentPeriod == 'monthly',
                onTap: () => _changePeriodType('monthly'),
              ),
              _PeriodTypeButton(
                label: context.tr.translate('quarterly_period'),
                isSelected: _currentPeriod == 'quarterly',
                onTap: () => _changePeriodType('quarterly'),
              ),
              _PeriodTypeButton(
                label: context.tr.translate('semiannual_period'),
                isSelected: _currentPeriod == 'semiannual',
                onTap: () => _changePeriodType('semiannual'),
              ),
              _PeriodTypeButton(
                label: context.tr.translate('annual_period'),
                isSelected: _currentPeriod == 'annual',
                onTap: () => _changePeriodType('annual'),
              ),
              _PeriodTypeButton(
                label: context.tr.translate('custom_period'),
                isSelected: _currentPeriod == 'custom',
                onTap: _showCustomRangeSelector,
                icon: Icons.calendar_today,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Usar colores fijos que garanticen visibilidad en modo oscuro
    final Color backgroundColor =
        isSelected
            ? (isDarkMode
                ? const Color(0xFF6A1B9A)
                : Theme.of(context).colorScheme.primaryContainer)
            : (isDarkMode
                ? const Color(0xFF2D2D2D)
                : Theme.of(context).colorScheme.surface);

    // Usar color de texto blanco para garantizar visibilidad en modo oscuro
    final Color textColor =
        isSelected
            ? Colors.white
            : (isDarkMode
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              width: 1.5,
              color:
                  isSelected
                      ? (isDarkMode
                          ? Colors.purple.shade300
                          : Theme.of(context).colorScheme.primary)
                      : (isDarkMode
                          ? Colors.grey
                          : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3)),
            ),
          ),
          elevation: isSelected ? 1 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
