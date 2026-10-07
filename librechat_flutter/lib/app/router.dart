import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/server_url_screen.dart';
import '../features/auth/two_factor_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/settings/general_settings_screen.dart';
import 'routes.dart';

/// The routes a signed-out user may stay on (Req 7.2). With a session, each
/// of them goes to `/chat` (Req 9.5, 12.2).
const authRoutes = {
  Routes.serverUrl,
  Routes.login,
  Routes.register,
  Routes.forgotPassword,
  Routes.resetPassword,
  Routes.twoFactor,
  Routes.verifyEmail,
  Routes.ssoLogin,
};

/// Signed-in routes that sit on the root navigator instead of the AppShell.
const _outsideShell = {Routes.terms, Routes.artifactFullscreen};

bool _isUnder(String path, Set<String> roots) =>
    roots.any((root) => path == root || path.startsWith('$root/'));

/// Whether [path] renders inside the AppShell: every signed-in route except
/// `/terms` and `/artifact`.
bool isShellPath(String path) =>
    !_isUnder(path, authRoutes) && !_isUnder(path, _outsideShell);

/// The three redirect rules from the design's Navigation section, as a pure
/// function of the auth state and the [path] being opened. Returns the
/// location to go to instead, or null to stay.
///
/// 1. No stored Server_URL: `/server-url` (Req 7.1).
/// 2. No session: the auth routes stay, and everything else goes to `/login`
///    (Req 7.2). While [expired] is set, a shell route stays so the AppShell
///    can show the session-expired dialog (Req 14.7).
/// 3. Session: an auth route goes to `/chat` (Req 9.5, 12.2).
String? authRedirect({
  required bool hasServerUrl,
  required bool signedIn,
  required bool expired,
  required String path,
}) {
  if (!hasServerUrl) return path == Routes.serverUrl ? null : Routes.serverUrl;
  final onAuthRoute = _isUnder(path, authRoutes);
  if (!signedIn) {
    if (onAuthRoute) return null;
    if (expired && isShellPath(path)) return null;
    return Routes.login;
  }
  return onAuthRoute ? Routes.newChat : null;
}

// FALLBACK, remove with Task 5.6 (`/sso`) and Task 7.4 (`/chat`): those
// routes aren't declared yet, so a location that resolves to one of them goes
// to a declared stand-in. Delete each entry when its route lands, and the
// whole map, plus its use in [routerRedirect], once it is empty.
const _undeclaredStandIns = {
  Routes.ssoLogin: Routes.login,
  Routes.newChat: Routes.settingsGeneral,
};

/// [authRedirect], then the temporary stand-ins for undeclared routes.
String? routerRedirect({
  required bool hasServerUrl,
  required bool signedIn,
  required bool expired,
  required String path,
}) {
  final target = authRedirect(
    hasServerUrl: hasServerUrl,
    signedIn: signedIn,
    expired: expired,
    path: path,
  );
  final standIn = _undeclaredStandIns[target ?? path];
  return standIn == null || standIn == path ? target : standIn;
}

/// App navigation. Each route is declared when its screen lands (Req 1.9).
/// The redirect runs on every navigation and on every AuthService change.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authServiceProvider);
  final router = GoRouter(
    // Never a destination itself: the redirect sends it to the right first
    // screen for the stored state (Req 7.1, 7.2, 12.2).
    initialLocation: Routes.newChat,
    refreshListenable: auth,
    redirect: (context, state) => routerRedirect(
      hasServerUrl: auth.serverUrl != null,
      signedIn: auth.session != null,
      expired: auth.expired,
      path: state.uri.path,
    ),
    routes: [
      GoRoute(
        path: Routes.serverUrl,
        builder: (context, state) => const ServerUrlScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.twoFactor,
        // The tempToken only travels in `extra`, so a restored or typed
        // location without it starts over at `/login`.
        redirect: (context, state) =>
            state.extra is String ? null : Routes.login,
        builder: (context, state) =>
            TwoFactorScreen(tempToken: state.extra! as String),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
          userId: state.uri.queryParameters['userId'],
        ),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        builder: (context, state) =>
            VerifyEmailScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: Routes.settingsGeneral,
        builder: (context, state) => const GeneralSettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
