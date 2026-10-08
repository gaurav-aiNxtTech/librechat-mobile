import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shell_drawer.dart';
import 'shell_menu_button.dart';

/// Window width from which the drawer becomes a persistent sidebar
/// (Req 14.1–14.2).
const shellBreakpoint = 600.0;

/// Width of the persistent sidebar (Req 14.2).
const sidebarWidth = 320.0;

/// The signed-in frame around every shell route (Req 14.1–14.3). Below
/// [shellBreakpoint] the [ShellDrawer] is a modal drawer that screens open
/// with [ShellMenuButton]; from it, the drawer is a [sidebarWidth] sidebar
/// beside the screen. Resizing across the breakpoint keeps the location.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  /// The screen of the current shell route.
  final Widget child;

  /// Finds the persistent sidebar in tests.
  static const sidebarKey = ValueKey('shell-sidebar');

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= shellBreakpoint;
    // Banners (Req 14.4) wrap the screen, and the session-expired and terms
    // listeners (Req 11.8, 14.7) wrap the Scaffold, in both layouts.
    return ShellScope(
      scaffoldKey: _scaffoldKey,
      modalDrawer: !wide,
      child: wide
          ? Scaffold(
              key: _scaffoldKey,
              body: Row(
                children: [
                  const SizedBox(
                    key: AppShell.sidebarKey,
                    width: sidebarWidth,
                    child: ShellDrawer(modal: false),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: widget.child),
                ],
              ),
            )
          : Scaffold(
              key: _scaffoldKey,
              drawer: const Drawer(child: ShellDrawer(modal: true)),
              body: widget.child,
            ),
    );
  }
}
