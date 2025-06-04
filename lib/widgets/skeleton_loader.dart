import 'package:flutter/material.dart';

/// Widget que crea un efecto skeleton con shimmer animado para placeholders de carga
/// Sigue la guía UI/UX del proyecto con colores adaptativos para temas oscuro/claro
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircular;
  final Duration animationDuration;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.isCircular = false,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  /// Constructor para skeleton circular (avatares, iconos)
  const SkeletonLoader.circular({
    super.key,
    required double size,
    this.animationDuration = const Duration(milliseconds: 1500),
  }) : width = size,
       height = size,
       borderRadius = 0,
       isCircular = true;

  /// Constructor para skeleton de card
  const SkeletonLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = 12,
    this.animationDuration = const Duration(milliseconds: 1500),
  }) : isCircular = false;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat();
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.isCircular
                    ? BorderRadius.circular(widget.height / 2)
                    : BorderRadius.circular(widget.borderRadius),
            gradient: _buildShimmerGradient(isDarkMode),
          ),
        );
      },
    );
  }

  LinearGradient _buildShimmerGradient(bool isDarkMode) {
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0.0, 0.5 + (_animation.value * 0.5), 1.0],
      colors: [baseColor, highlightColor, baseColor],
    );
  }
}

/// Widget que crea múltiples líneas de skeleton para simular texto
class SkeletonText extends StatelessWidget {
  final int lines;
  final double height;
  final double spacing;
  final List<double>? lineWidths;

  const SkeletonText({
    super.key,
    this.lines = 3,
    this.height = 16,
    this.spacing = 8,
    this.lineWidths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        double width = 1.0;
        if (lineWidths != null && index < lineWidths!.length) {
          width = lineWidths![index];
        } else if (index == lines - 1) {
          width = 0.7; // Última línea más corta por defecto
        }

        return Column(
          children: [
            FractionallySizedBox(
              widthFactor: width,
              child: SkeletonLoader(height: height, borderRadius: 4),
            ),
            if (index < lines - 1) SizedBox(height: spacing),
          ],
        );
      }),
    );
  }
}

/// Widget que crea un skeleton para cards con imagen y texto
class SkeletonCard extends StatelessWidget {
  final double height;
  final bool hasImage;
  final bool hasSubtitle;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.hasImage = true,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Imagen/Avatar
          if (hasImage) ...[
            const SkeletonLoader.circular(size: 48),
            const SizedBox(width: 16),
          ],

          // Contenido de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: const SkeletonLoader(
                    height: 18,
                    width: double.infinity,
                    borderRadius: 4,
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 4),
                  Flexible(
                    child: const SkeletonLoader(
                      height: 14,
                      width: 150,
                      borderRadius: 4,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Flexible(
                  child: const SkeletonLoader(
                    height: 12,
                    width: 100,
                    borderRadius: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que crea una lista de skeleton cards
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool hasImage;
  final bool hasSubtitle;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
    this.hasImage = true,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return SkeletonCard(
          height: itemHeight,
          hasImage: hasImage,
          hasSubtitle: hasSubtitle,
        );
      },
    );
  }
}
