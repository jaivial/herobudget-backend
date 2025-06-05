import 'package:flutter/material.dart';
import 'language_selector_button.dart';

class LocalizedScreenWrapper extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool showLanguageSelector;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? persistentFooterButtons;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;

  const LocalizedScreenWrapper({
    Key? key,
    required this.child,
    this.appBar,
    this.showLanguageSelector = true,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.persistentFooterButtons,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If there's a custom AppBar, modify it to include the language selector
    final updatedAppBar =
        appBar != null
            ? _addLanguageSelectorToAppBar(appBar!)
            : _createDefaultAppBar(context);

    return Scaffold(
      appBar: updatedAppBar,
      body: child,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      persistentFooterButtons: persistentFooterButtons,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }

  PreferredSizeWidget _addLanguageSelectorToAppBar(
    PreferredSizeWidget originalAppBar,
  ) {
    // If the original AppBar is not an AppBar instance, we can't modify it easily
    if (originalAppBar is! AppBar) return originalAppBar;

    return AppBar(
      leading: originalAppBar.leading,
      automaticallyImplyLeading: originalAppBar.automaticallyImplyLeading,
      title: originalAppBar.title,
      actions: [
        ...(originalAppBar.actions ?? []),
        if (showLanguageSelector)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: LanguageSelectorButton()),
          ),
      ],
      flexibleSpace: originalAppBar.flexibleSpace,
      bottom: originalAppBar.bottom,
      elevation: originalAppBar.elevation,
      scrolledUnderElevation: originalAppBar.scrolledUnderElevation,
      shadowColor: originalAppBar.shadowColor,
      surfaceTintColor: originalAppBar.surfaceTintColor,
      backgroundColor: originalAppBar.backgroundColor,
      foregroundColor: originalAppBar.foregroundColor,
      iconTheme: originalAppBar.iconTheme,
      actionsIconTheme: originalAppBar.actionsIconTheme,
      primary: originalAppBar.primary,
      centerTitle: originalAppBar.centerTitle,
      excludeHeaderSemantics: originalAppBar.excludeHeaderSemantics,
      titleSpacing: originalAppBar.titleSpacing,
      toolbarOpacity: originalAppBar.toolbarOpacity,
      bottomOpacity: originalAppBar.bottomOpacity,
      toolbarHeight: originalAppBar.toolbarHeight,
      leadingWidth: originalAppBar.leadingWidth,
      toolbarTextStyle: originalAppBar.toolbarTextStyle,
      titleTextStyle: originalAppBar.titleTextStyle,
      systemOverlayStyle: originalAppBar.systemOverlayStyle,
    );
  }

  PreferredSizeWidget _createDefaultAppBar(BuildContext context) {
    if (!showLanguageSelector) return AppBar(toolbarHeight: 0);

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(child: LanguageSelectorButton()),
        ),
      ],
    );
  }
}
