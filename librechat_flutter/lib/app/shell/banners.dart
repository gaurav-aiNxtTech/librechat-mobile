import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/server_config.dart';
import '../../core/config/server_version.dart';
import '../../core/models/banner.dart';
import '../../core/network/api_client.dart';
import '../../core/network/connectivity.dart';
import '../../core/storage/settings_store.dart';
import '../routes.dart';

/// The Server's banner for the signed-in user (Req 14.4), refetched when the
/// user or the Server_URL changes. Null while signed out or when the Server
/// has none (it answers an empty body); a failed fetch is an error, which
/// shows no banner.
final bannerProvider = FutureProvider<ServerBanner?>((ref) async {
  final userId = ref.watch(
    authServiceProvider.select((a) => a.session?.user.id),
  );
  ref.watch(authServiceProvider.select((a) => a.serverUrl));
  if (userId == null) return null;
  return ref
      .read(apiClientProvider)
      .json(
        'GET',
        '/api/banner',
        (json) => json == null
            ? null
            : ServerBanner.fromJson((json as Map).cast<String, Object?>()),
      );
});

/// Whether [banner] shows (Req 14.4–14.6): it needs an id and a non-blank
/// message, and a dismissed id stays hidden unless the banner is
/// `persistable`, which can't be dismissed.
bool shouldShowBanner(ServerBanner? banner, List<String> dismissed) {
  final id = banner?.bannerId;
  if (banner == null || id == null) return false;
  if ((banner.message?.trim() ?? '').isEmpty) return false;
  return banner.persistable == true || !dismissed.contains(id);
}

/// Whether the version banner shows for the Server_Version [server]
/// (Req 6.8–6.10): only for a known version outside the Target_Version's
/// release line that the user neither dismissed this launch nor chose
/// "Don't show again" for ([stored]).
bool showVersionBanner(
  Version? server, {
  String? stored,
  String? dismissedThisLaunch,
}) {
  if (server == null || server.sameRelease(targetVersion)) return false;
  final version = server.toString();
  return version != stored && version != dismissedThisLaunch;
}

/// The Server_Version whose banner the user dismissed this launch (Req 6.9).
/// Kept in memory only, so the banner returns on the next launch.
class VersionBannerDismissal extends Notifier<String?> {
  @override
  String? build() => null;

  void dismiss(String version) => state = version;
}

final versionBannerDismissalProvider =
    NotifierProvider<VersionBannerDismissal, String?>(
      VersionBannerDismissal.new,
    );

/// Whether the signed-in user still has to accept the terms (Req 11.8):
/// only asked when Server_Config sets `termsOfService.modalAcceptance`. A
/// failed check counts as accepted, because the Server still enforces the
/// terms and a failed check must not trap the user on `/terms`.
class TermsCheck extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final userId = ref.watch(
      authServiceProvider.select((a) => a.session?.user.id),
    );
    final required = ref.watch(
      serverConfigProvider.select(
        (s) =>
            s.value?.config.interfaceConfig.termsOfService?.modalAcceptance ==
            true,
      ),
    );
    if (userId == null || !required) return false;
    try {
      return !(await ref.read(authServiceProvider).api.termsAccepted());
    } catch (_) {
      return false;
    }
  }

  /// Called by the Terms_Screen after the acceptance is recorded.
  void accepted() => state = const AsyncData(false);
}

final termsCheckProvider = AsyncNotifierProvider<TermsCheck, bool>(
  TermsCheck.new,
);

/// Stacks the offline, server and version banners above [child]
/// (Req 6.8–6.10, 14.4–14.6, 14.8). Each banner is a polite live region.
/// With no banner, [child] is returned as is.
class BannerStack extends ConsumerWidget {
  const BannerStack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(onlineProvider).value == false;
    final banner = ref.watch(bannerProvider).value;
    final settings = ref.watch(settingsProvider);
    final server = ref.watch(
      serverConfigProvider.select((s) => s.value?.version),
    );
    final dismissedThisLaunch = ref.watch(versionBannerDismissalProvider);

    final showServer = shouldShowBanner(banner, settings.dismissedBannerIds);
    final showVersion = showVersionBanner(
      server,
      stored: settings.dismissedVersionBanner,
      dismissedThisLaunch: dismissedThisLaunch,
    );

    void save(AppSettings Function(AppSettings current) change) {
      final store = ref.read(settingsProvider.notifier);
      store.save(change(ref.read(settingsProvider)));
    }

    final cards = [
      if (offline)
        const _BannerCard(
          message: 'No internet connection', // KMP app no_connection
        ),
      if (showServer)
        _BannerCard(
          message: banner!.message!.trim(),
          onDismiss: banner.persistable == true
              ? null
              : () => save(
                  (s) => s.copyWith(
                    dismissedBannerIds: [
                      ...s.dismissedBannerIds,
                      banner.bannerId!,
                    ],
                  ),
                ),
        ),
      if (showVersion)
        _BannerCard(
          // KMP shared version_mismatch_message
          message:
              'This app was built for LibreChat v$targetVersion, but your '
              'server is running v$server. Some features may not work '
              'correctly.',
          actions: [
            TextButton(
              onPressed: () => ref
                  .read(versionBannerDismissalProvider.notifier)
                  .dismiss(server.toString()),
              child: const Text('Dismiss'), // KMP shared dismiss
            ),
            TextButton(
              onPressed: () => save(
                (s) => s.copyWith(dismissedVersionBanner: server.toString()),
              ),
              child: const Text("Don't show again"), // Req 6.9 label
            ),
          ],
        ),
    ];
    if (cards.isEmpty) return child;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: cards),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// One banner, styled like KMP `BannerDisplay.kt`. [onDismiss] adds the
/// close button; [actions] go below the message.
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.message,
    this.onDismiss,
    this.actions = const [],
  });

  final String message;
  final VoidCallback? onDismiss;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onSecondaryContainer;
    final dismiss = onDismiss;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            dismiss == null ? 12 : 4,
            dismiss == null ? 16 : 4,
            actions.isEmpty ? 12 : 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Decorative: the message carries the content.
                  Icon(Icons.info, color: onContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: actions.isEmpty ? 0 : 8),
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onContainer,
                        ),
                      ),
                    ),
                  ),
                  if (dismiss != null)
                    IconButton(
                      onPressed: dismiss,
                      tooltip: 'Dismiss banner', // KMP core/ui banner_dismiss
                      icon: Icon(Icons.close, color: onContainer),
                    ),
                ],
              ),
              if (actions.isNotEmpty)
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: actions,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-wide reactions inside the AppShell: the session-expired dialog
/// (Req 14.7) and the post-sign-in terms check that opens `/terms`
/// (Req 11.8).
class ShellListeners extends ConsumerStatefulWidget {
  const ShellListeners({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShellListeners> createState() => _ShellListenersState();
}

class _ShellListenersState extends ConsumerState<ShellListeners> {
  bool _expiryShown = false;

  @override
  void initState() {
    super.initState();
    // `session == null` keeps a later sign-in from showing the dialog when an
    // expiry was never acknowledged (e.g. it happened on /terms).
    ref.listenManual(
      authServiceProvider.select((a) => a.expired && a.session == null),
      (_, expired) {
        if (expired) _afterFrame(_showExpiry);
      },
      fireImmediately: true,
    );
    ref.listenManual(termsCheckProvider, (_, next) {
      if (next case AsyncData(value: true)) {
        _afterFrame(() => context.go(Routes.terms));
      }
    }, fireImmediately: true);
  }

  void _afterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  Future<void> _showExpiry() async {
    if (_expiryShown) return;
    _expiryShown = true;
    final auth = ref.read(authServiceProvider);
    void close(BuildContext dialogContext) {
      Navigator.of(dialogContext).pop();
      auth.acknowledgeExpiry();
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close(dialogContext);
        },
        child: AlertDialog(
          title: const Text('Signed out'), // KMP shared session_expired_title
          // KMP shared session_expired_message
          content: const Text(
            'Your session has expired. Sign in again to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => close(dialogContext),
              child: const Text('Dismiss'), // KMP shared dismiss
            ),
          ],
        ),
      ),
    );
    if (mounted) _expiryShown = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
