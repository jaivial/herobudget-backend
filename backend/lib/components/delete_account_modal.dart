import 'package:flutter/material.dart';
import '../utils/extensions.dart';

class DeleteAccountModal extends StatefulWidget {
  const DeleteAccountModal({super.key});

  @override
  State<DeleteAccountModal> createState() => _DeleteAccountModalState();
}

class _DeleteAccountModalState extends State<DeleteAccountModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con ícono de advertencia
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_rounded,
                              size: 32,
                              color: colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr.translate('delete_account_warning'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Contenido principal
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Descripción principal
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(
                                0.3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              context.tr.translate('delete_account_data_list'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Mensaje de irreversibilidad con estilo destacado
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.error.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    context.tr.translate(
                                      'delete_account_irreversible',
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botones de acción
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Primera fila: Botón Cancelar
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                side: BorderSide(
                                  color: colorScheme.outline,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.tr.translate('cancel'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Segunda fila: Botón Eliminar Permanentemente
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_forever_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      context.tr.translate(
                                        'delete_permanently',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Modal para mostrar el progreso de eliminación
class DeletingAccountModal extends StatelessWidget {
  const DeletingAccountModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.error,
                    strokeWidth: 3,
                  ),
                  Icon(
                    Icons.delete_forever_rounded,
                    color: colorScheme.error,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr.translate('deleting_account') ??
                  'Eliminando cuenta...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Por favor espera...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
