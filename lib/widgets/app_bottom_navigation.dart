import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
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

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Altura de la barra de navegación
    const double navBarHeight = 70.0;

    // Tamaño del botón central
    const double buttonSize = 65.0;

    // Punto de origen del botón sobre la barra
    const double buttonBottomOffset = 10.0;

    return Material(
      elevation: 8,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Barra de navegación principal
          Container(
            height: navBarHeight,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Botón para ir al Dashboard/Home
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Inicio',
                    index: 0,
                  ),
                ),

                // Botón para ir a Transacciones
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transacciones',
                    index: 1,
                  ),
                ),

                // Espacio para el botón central
                const Expanded(child: SizedBox()),

                // Botón para ir a Estadísticas
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Estadísticas',
                    index: 2,
                  ),
                ),

                // Botón para ir al Perfil
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Perfil',
                    index: 3,
                  ),
                ),
              ],
            ),
          ),

          // Botón central de acciones rápidas
          Positioned(
            bottom: buttonBottomOffset + navBarHeight / 2,
            child: _buildActionButton(buttonSize),
          ),

          // Menú de acciones rápidas
          if (_isExpanded) ..._buildQuickActions(screenWidth),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => widget.onTabChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(double size) {
    return GestureDetector(
      onTap: _toggleMenu,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:
              _isExpanded
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: AnimatedRotation(
          turns:
              _isExpanded
                  ? 0.125
                  : 0, // Rotación de 45 grados si está expandido
          duration: const Duration(milliseconds: 250),
          child: Icon(
            _isExpanded ? Icons.close : Icons.add,
            color: Colors.white,
            size: 35,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuickActions(double screenWidth) {
    // Definición de acciones rápidas
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.add_card, 'label': 'Ingreso', 'color': Colors.green},
      {'icon': Icons.shopping_bag, 'label': 'Gasto', 'color': Colors.red},
      {'icon': Icons.receipt, 'label': 'Factura', 'color': Colors.blue},
      {'icon': Icons.category, 'label': 'Categoría', 'color': Colors.orange},
    ];

    // Radio del círculo donde se distribuirán las acciones - ajustado para caber en pantalla
    final double radius = math.min(120, screenWidth * 0.35);

    // Crear widgets para cada acción
    List<Widget> actionWidgets = [];

    for (int i = 0; i < actions.length; i++) {
      // Calcular la posición en el círculo
      final double angle = (i * 2 * math.pi / actions.length) - math.pi / 2;
      final double x = radius * math.cos(angle);
      final double y = radius * math.sin(angle);

      final Map<String, dynamic> action = actions[i];

      actionWidgets.add(
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Ajustar la posición para evitar que se salga de la pantalla
            double adjustedX = x * _animationController.value;
            double leftPosition = screenWidth / 2 - 28 + adjustedX;

            // Asegurar que el botón no se salga de los márgenes (con un padding de 16px)
            leftPosition = math.max(
              16,
              math.min(screenWidth - 72, leftPosition),
            );

            return Positioned(
              bottom: 105 + y * _animationController.value,
              left: leftPosition,
              child: Opacity(opacity: _animationController.value, child: child),
            );
          },
          child: _buildActionItem(
            icon: action['icon'],
            label: action['label'],
            color: action['color'],
            onTap: () {
              _toggleMenu();
              // TODO: Implementar acción específica
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Acción: ${action['label']}')),
              );
            },
          ),
        ),
      );
    }

    return actionWidgets;
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
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
}
