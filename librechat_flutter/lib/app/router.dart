import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_service.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/server_url_screen.dart';
import '../features/auth/sso_screen.dart';
import '../features/auth/terms_screen.dart';
import '../features/auth/two_factor_screen.dart';
import '../features/auth/verify_email_screen.dart';
import '../features/chat/artifacts/artifact_viewer.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/media_screen.dart';
import '../features/conversations/archived_screen.dart';
import '../features/settings/general_settings_screen.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

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

/// App navigation. Each route is declared when its screen lands (Req 1.9).
/// The redirect runs on every navigation and on every AuthService change.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authServiceProvider);
  final router = GoRouter(
    // Never a destination itself: the redirect sends it to the right first
    // screen for the stored state (Req 7.1, 7.2, 12.2).
    initialLocation: Routes.newChat,
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
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
        path: Routes.ssoLogin,
        redirect: (context, state) =>
            (state.uri.queryParameters['provider'] ?? '').isEmpty
            ? Routes.login
            : null,
        builder: (context, state) =>
            SsoScreen(provider: state.uri.queryParameters['provider']!),
      ),
      // Root navigator, outside the AppShell (design Navigation section).
      GoRoute(
        path: Routes.terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: Routes.artifactFullscreen,
        // The artifact travels in `extra`, so a restored or typed location
        // without it goes back to the chat (Req 24.13).
        redirect: (context, state) =>
            state.extra is ArtifactArgs ? null : Routes.newChat,
        builder: (context, state) =>
            ArtifactFullscreenScreen(args: state.extra! as ArtifactArgs),
      ),
      // Every signed-in route except /terms and /artifact goes inside the
      // AppShell (Req 14.1–14.3).
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.newChat,
            builder: (context, state) => const ChatScreen(),
          ),
          // Routes.chat(id). The key gives each conversation its own
          // screen state, such as the scroll position.
          GoRoute(
            path: '/chat/c/:conversationId',
            builder: (context, state) {
              final id = state.pathParameters['conversationId']!;
              return ChatScreen(key: ValueKey(id), conversationId: id);
            },
            routes: [
              // Routes.conversationMedia(id) (Req 25.12).
              GoRoute(
                path: 'media',
                builder: (context, state) => MediaScreen(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.archivedConversations,
            builder: (context, state) => const ArchivedScreen(),
          ),
          GoRoute(
            path: Routes.settingsGeneral,
            builder: (context, state) => const GeneralSettingsScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
