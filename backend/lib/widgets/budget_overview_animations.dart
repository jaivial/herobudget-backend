import 'package:flutter/material.dart';

/// Mixin that provides animation functionality for budget overview widgets
mixin BudgetOverviewAnimations<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  late AnimationController slideController;
  late AnimationController fadeController;
  late Animation<Offset> slideAnimation;
  late Animation<double> fadeAnimation;

  // Direction tracking for slide animations
  bool isNavigatingForward = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    slideController.dispose();
    fadeController.dispose();
    super.dispose();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: slideController, curve: Curves.easeInOut),
    );

    fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeInOut));
  }

  /// Perform transition animation with data fetch
  Future<void> performTransition(
    VoidCallback updateState,
    Future<void> Function() fetchData,
  ) async {
    // Configure slide direction
    slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isNavigatingForward ? 1.0 : -1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: slideController, curve: Curves.easeInOut),
    );

    // Start slide out animation
    await slideController.forward();

    // Update state
    updateState();

    // Fetch new data
    await fetchData();

    // Configure slide in from opposite direction
    slideAnimation = Tween<Offset>(
      begin: Offset(isNavigatingForward ? -1.0 : 1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: slideController, curve: Curves.easeInOut),
    );

    // Reset and slide in
    slideController.reset();
    slideController.forward();
  }

  /// Perform fade transition for data refresh
  Future<void> performFadeTransition(Future<void> Function() fetchData) async {
    // Start fade out animation
    await fadeController.forward();

    // Fetch new data
    await fetchData();

    // Fade back in with new data
    fadeController.reset();
  }

  /// Set navigation direction for slide animations
  void setNavigationDirection(bool forward) {
    isNavigatingForward = forward;
  }

  /// Reset all animations to initial state
  void resetAnimations() {
    slideController.reset();
    fadeController.reset();
  }
}

/// Widget that wraps content with slide and fade animations
class AnimatedBudgetContent extends StatelessWidget {
  final Widget child;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const AnimatedBudgetContent({
    super.key,
    required this.child,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(opacity: fadeAnimation, child: child),
    );
  }
}

/// Utility class for animation configurations
class BudgetAnimationConfig {
  static const Duration slideTransitionDuration = Duration(milliseconds: 400);
  static const Duration fadeTransitionDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  /// Creates a slide animation from one side to another
  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    required bool isForward,
    Curve curve = defaultCurve,
  }) {
    return Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isForward ? 1.0 : -1.0, 0.0),
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// Creates a fade animation
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }
}

/// Extension methods for animation controllers
extension AnimationControllerExtensions on AnimationController {
  /// Forward animation and return a future that completes when done
  Future<void> forwardAndWait() async {
    await forward();
  }

  /// Reverse animation and return a future that completes when done
  Future<void> reverseAndWait() async {
    await reverse();
  }

  /// Reset and forward animation
  Future<void> resetAndForward() async {
    reset();
    await forward();
  }
}
