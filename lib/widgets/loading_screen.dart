import 'package:flutter/material.dart';

/// Widget de pantalla de carga que ocupa toda la pantalla con efectos de fade in/out
/// Implementa un diseño elegante siguiendo la guía UI/UX con colores púrpura
class LoadingScreen extends StatefulWidget {
  final bool isLoading;
  final String? message;
  final Duration fadeDuration;
  final Widget? child;

  const LoadingScreen({
    super.key,
    required this.isLoading,
    this.message,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.child,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    if (widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (!widget.isLoading && _animationController.value == 0.0) {
          return widget.child ?? const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Contenido principal (si existe)
            if (widget.child != null) widget.child!,

            // Overlay de carga
            if (_animationController.value > 0.0)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    color: (isDarkMode ? Colors.black : Colors.white)
                        .withOpacity(0.85),
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLoadingContent(isDarkMode),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingContent(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spinner circular con colores púrpura
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6A1B9A).withOpacity(0.1),
            ),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Mensaje de carga
          if (widget.message != null)
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

          // Indicador de carga animado
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor: const Color(0xFF6A1B9A).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6A1B9A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget simple de spinner para uso rápido
class SimpleLoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const SimpleLoadingSpinner({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size * 0.1,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? const Color(0xFF6A1B9A),
        ),
      ),
    );
  }
}
