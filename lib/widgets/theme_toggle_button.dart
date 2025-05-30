import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeToggleButton extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final bool showLabel;
  final Color? backgroundColor;
  final Color? iconColor;

  const ThemeToggleButton({
    super.key,
    this.padding,
    this.showLabel = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> {
  ThemeMode _currentThemeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await AppTheme.getThemeMode();
    if (mounted) {
      setState(() {
        _currentThemeMode = mode;
      });
    }
  }

  Future<void> _toggleTheme() async {
    final newMode =
        _currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    // Guardar la preferencia
    await AppTheme.saveThemeMode(newMode);

    // Actualizar el estado local
    if (mounted) {
      setState(() {
        _currentThemeMode = newMode;
      });
    }

    // Notificar el cambio globalmente
    themeChangeNotifier.notifyThemeChange(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _currentThemeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    final iconColor =
        widget.iconColor ??
        (theme.brightness == Brightness.dark
            ? Colors.white
            : theme.colorScheme.primary);

    final backgroundColor =
        widget.backgroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.1));

    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
        ),
        child:
            widget.showLabel
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                      color: iconColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDarkMode ? 'Light' : 'Dark',
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                : Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                  color: iconColor,
                ),
      ),
    );
  }
}
