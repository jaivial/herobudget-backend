import 'package:flutter/material.dart';

/// Una barra de navegación inferior simplificada sin lógica de botón +
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
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
            child: _buildNavItem(context, icon: Icons.home_rounded, index: 0),
          ),

          // Botón para ir a Transacciones
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.receipt_long_rounded,
              index: 1,
            ),
          ),

          // Espacio para el botón central (implementado con FloatingActionButton)
          const Expanded(child: SizedBox()),

          // Botón para ir a Estadísticas
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.bar_chart_rounded,
              index: 2,
            ),
          ),

          // Botón para ir al Perfil
          Expanded(
            child: _buildNavItem(context, icon: Icons.person_rounded, index: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onTabChanged(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withAlpha(153),
            size: 28,
          ),
        ],
      ),
    );
  }
}
