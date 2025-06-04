import 'package:flutter/material.dart';
import 'loading_screen.dart';
import 'skeleton_loader.dart';

/// Tipos de overlay de carga disponibles
enum LoadingOverlayType {
  spinner, // Spinner circular simple
  fullScreen, // Pantalla completa elegante
  skeleton, // Skeleton loader
}

/// Widget wrapper que añade un overlay de carga sobre cualquier contenido
/// Proporciona diferentes tipos de loading states siguiendo la guía UI/UX
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final LoadingOverlayType type;
  final String? message;
  final Duration fadeDuration;
  final int skeletonItemCount;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.type = LoadingOverlayType.spinner,
    this.message,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.skeletonItemCount = 5,
  });

  /// Constructor específico para skeleton loading
  const LoadingOverlay.skeleton({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.skeletonItemCount = 5,
  }) : type = LoadingOverlayType.skeleton;

  /// Constructor específico para pantalla completa
  const LoadingOverlay.fullScreen({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.fadeDuration = const Duration(milliseconds: 300),
  }) : type = LoadingOverlayType.fullScreen,
       skeletonItemCount = 5;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingOverlayType.fullScreen:
        return LoadingScreen(
          isLoading: isLoading,
          message: message,
          fadeDuration: fadeDuration,
          child: child,
        );

      case LoadingOverlayType.skeleton:
        return _buildSkeletonOverlay();

      case LoadingOverlayType.spinner:
      default:
        return _buildSpinnerOverlay();
    }
  }

  Widget _buildSpinnerOverlay() {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: SimpleLoadingSpinner(size: 32)),
          ),
      ],
    );
  }

  Widget _buildSkeletonOverlay() {
    return AnimatedSwitcher(
      duration: fadeDuration,
      child: isLoading ? _buildSkeletonContent() : child,
    );
  }

  Widget _buildSkeletonContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SkeletonList(
          itemCount: skeletonItemCount,
          itemHeight: 80,
          hasImage: true,
          hasSubtitle: true,
        ),
      ),
    );
  }
}

/// Widget helper para mostrar loading state en listas
class LoadingListTile extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final bool hasLeading;
  final bool hasSubtitle;

  const LoadingListTile({
    super.key,
    required this.isLoading,
    required this.child,
    this.hasLeading = true,
    this.hasSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SkeletonCard(
        height: 72,
        hasImage: hasLeading,
        hasSubtitle: hasSubtitle,
      );
    }
    return child;
  }
}

/// Extension para facilitar el uso de LoadingOverlay
extension LoadingOverlayExtension on Widget {
  /// Envuelve el widget con un overlay de carga
  Widget withLoadingOverlay({
    required bool isLoading,
    LoadingOverlayType type = LoadingOverlayType.spinner,
    String? message,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) {
    return LoadingOverlay(
      isLoading: isLoading,
      type: type,
      message: message,
      fadeDuration: fadeDuration,
      child: this,
    );
  }

  /// Envuelve el widget con skeleton loading
  Widget withSkeletonLoading({
    required bool isLoading,
    int itemCount = 5,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) {
    return LoadingOverlay.skeleton(
      isLoading: isLoading,
      skeletonItemCount: itemCount,
      fadeDuration: fadeDuration,
      child: this,
    );
  }

  /// Envuelve el widget con loading de pantalla completa
  Widget withFullScreenLoading({
    required bool isLoading,
    String? message,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) {
    return LoadingOverlay.fullScreen(
      isLoading: isLoading,
      message: message,
      fadeDuration: fadeDuration,
      child: this,
    );
  }
}
