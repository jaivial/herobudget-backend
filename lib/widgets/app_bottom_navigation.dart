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
      height: 70,
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
              context,
              icon: Icons.home_rounded,
              label: 'Inicio',
              index: 0,
            ),
          ),

          // Botón para ir a Transacciones
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'Transacciones',
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
              label: 'Estadísticas',
              index: 2,
            ),
          ),

          // Botón para ir al Perfil
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.person_rounded,
              label: 'Perfil',
              index: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
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
}
