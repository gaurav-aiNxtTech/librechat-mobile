import 'package:flutter/material.dart';

/// What the AppShell tells the screens below it: the Scaffold that owns the
/// drawer, and whether that drawer is modal (below 600 dp, Req 14.1).
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.scaffoldKey,
    required this.modalDrawer,
    required super.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool modalDrawer;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      scaffoldKey != oldWidget.scaffoldKey ||
      modalDrawer != oldWidget.modalDrawer;
}

/// Opens the AppShell's modal drawer (Req 14.1). Screens put it in their
/// AppBar through [leading].
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  /// The button when a modal drawer is above [context], else null, so an
  /// AppBar beside the sidebar (or outside the shell) gets no leading slot.
  static Widget? leading(BuildContext context) =>
      ShellScope.maybeOf(context)?.modalDrawer == true
      ? const ShellMenuButton()
      : null;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Open navigation drawer', // KMP feature/chat cd_open_drawer
      onPressed: () =>
          ShellScope.maybeOf(context)?.scaffoldKey.currentState?.openDrawer(),
    );
  }
}
