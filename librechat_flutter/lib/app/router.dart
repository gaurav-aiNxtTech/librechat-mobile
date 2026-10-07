import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/settings/general_settings_screen.dart';
import 'routes.dart';

/// App navigation. Each route is declared when its screen lands (Req 1.9).
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.settingsGeneral,
    routes: [
      GoRoute(
        path: Routes.settingsGeneral,
        builder: (context, state) => const GeneralSettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
