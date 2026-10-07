import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/server_config.dart';
import '../../core/images/app_image.dart';
import '../../core/models/startup_config.dart';
import '../../core/network/app_exception.dart';

/// A social sign-in button: the SSO provider [id], its button [label] and,
/// for OpenID and SAML, the Server_Config [image].
typedef SocialProvider = ({String id, String label, String? image});

// LibreChat's default `socialLogins` order, used when the config has none.
const _defaultSocialOrder = [
  'github',
  'google',
  'discord',
  'openid',
  'facebook',
  'apple',
  'saml',
];

/// The enabled providers in the Server_Config `socialLogins` order (Req 9.9).
/// OpenID and SAML take the config label and image when it has them.
List<SocialProvider> socialProviders(StartupConfig config) {
  String? text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  final seen = <String>{};
  return [
    for (final raw in config.socialLogins ?? _defaultSocialOrder)
      if (seen.add(raw.toLowerCase()))
        ?switch (raw.toLowerCase()) {
          // KMP LoginScreen.kt oAuthProviderLabel.
          'google' when config.googleLoginEnabled => (
            id: 'google',
            label: 'Continue with Google',
            image: null,
          ),
          'github' when config.githubLoginEnabled => (
            id: 'github',
            label: 'Continue with GitHub',
            image: null,
          ),
          'discord' when config.discordLoginEnabled => (
            id: 'discord',
            label: 'Continue with Discord',
            image: null,
          ),
          'facebook' when config.facebookLoginEnabled => (
            id: 'facebook',
            label: 'Continue with Facebook',
            image: null,
          ),
          'apple' when config.appleLoginEnabled => (
            id: 'apple',
            label: 'Continue with Apple',
            image: null,
          ),
          'openid' when config.openidLoginEnabled => (
            id: 'openid',
            label: text(config.openidLabel) ?? 'Continue with OpenID',
            image: text(config.openidImageUrl),
          ),
          'saml' when config.samlLoginEnabled => (
            id: 'saml',
            // New copy: KMP derives "Continue with Saml".
            label: text(config.samlLabel) ?? 'Continue with SAML',
            image: text(config.samlImageUrl),
          ),
          _ => null,
        },
  ];
}

/// The Login_Screen (Req 9, 7.8). Copy follows the KMP feature/auth
/// `strings.xml`. A successful sign-in needs no navigation here: the router's
/// redirect opens `/chat` once the session is stored (Req 9.5).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.listenManual(serverConfigProvider, (_, next) {
      if (next.value?.config case final config?) _autoRedirect(config);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Starts OpenID once per App session when the Server asks for it
  /// (Req 9.10).
  void _autoRedirect(StartupConfig config) {
    final auth = ref.read(authServiceProvider);
    if (!config.openidLoginEnabled ||
        !config.openidAutoRedirect ||
        auth.openIdAutoRedirected) {
      return;
    }
    auth.openIdAutoRedirected = true;
    // Never navigate during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSso('openid');
    });
  }

  void _openSso(String provider) => context.go(
    Uri(
      path: Routes.ssoLogin,
      queryParameters: {'provider': provider},
    ).toString(),
  );

  /// Sends the credentials (Req 9.3) and routes on the result (Req 9.6–9.8).
  /// Does nothing while a login runs.
  Future<void> _submit() async {
    if (_submitting) return;
    final identifier = _identifier.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authServiceProvider)
          .login(identifier, _password.text);
      if (!mounted) return;
      switch (result) {
        case SignedIn():
          break;
        case NeedsTwoFactor(:final tempToken):
          // Pushed, so Back returns here with the identifier kept.
          unawaited(context.push(Routes.twoFactor, extra: tempToken));
        case NeedsVerification():
          context.go(
            Uri(
              path: Routes.verifyEmail,
              queryParameters: {'email': identifier},
            ).toString(),
          );
      }
    } catch (e) {
      if (mounted) setState(() => _error = userMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(serverConfigProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: switch (info) {
                AsyncValue(value: final info?) => _form(context, info.config),
                AsyncValue(error: final error?) => _ConfigError(
                  message: userMessage(error),
                  onRetry: () => unawaited(
                    ref.read(serverConfigProvider.notifier).refresh(),
                  ),
                  onChangeServer: _changeServer,
                ),
                _ => const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading', // New copy.
                  ),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }

  void _changeServer() => unawaited(context.push(Routes.serverUrl));

  Widget _form(BuildContext context, StartupConfig config) {
    final theme = Theme.of(context);
    final enabled = !_submitting;
    final ldapUsername =
        (config.ldap?.enabled ?? false) && (config.ldap?.username ?? false);
    final providers = socialProviders(config);
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Sign in',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 32),
        // Hidden when the Server disables email login, which rejects the
        // login POST; only the social providers remain.
        if (config.emailLoginEnabled)
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _identifier,
                  enabled: enabled,
                  keyboardType: ldapUsername
                      ? TextInputType.text
                      : TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: [
                    ldapUsername ? AutofillHints.username : AutofillHints.email,
                  ],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: ldapUsername ? 'Username' : 'Email',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  enabled: enabled,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.go,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                  onSubmitted: (_) => unawaited(_submit()),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
        if (config.emailLoginEnabled) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: enabled ? () => unawaited(_submit()) : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Signing in', // New copy.
                    ),
                  )
                : const Text('Continue'),
          ),
          if (config.passwordResetEnabled) ...[
            const SizedBox(height: 8),
            _LinkButton(
              label: 'Forgot password?',
              onPressed: enabled
                  ? () => context.go(Routes.forgotPassword)
                  : null,
            ),
          ],
        ],
        if (config.registrationEnabled) ...[
          const SizedBox(height: 8),
          _LinkButton(
            label: "Don't have an account? Sign up",
            onPressed: enabled ? () => context.go(Routes.register) : null,
          ),
        ],
        if (providers.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Or continue with',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final provider in providers) ...[
            const SizedBox(height: 8),
            _SocialButton(
              provider: provider,
              onPressed: enabled ? () => _openSso(provider.id) : null,
            ),
          ],
        ],
        const SizedBox(height: 16),
        _LinkButton(
          label: 'Change server', // New copy.
          onPressed: enabled ? _changeServer : null,
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.provider, required this.onPressed});

  final SocialProvider provider;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
    );
    final label = Text(provider.label, textAlign: TextAlign.center);
    final image = provider.image;
    if (image == null) {
      return OutlinedButton(onPressed: onPressed, style: style, child: label);
    }
    // The label names the button, so the image stays decorative.
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: AppImage(image, width: 20, height: 20, fit: BoxFit.contain),
      label: label,
    );
  }
}

/// No Server_Config could load and none is cached.
class _ConfigError extends StatelessWidget {
  const _ConfigError({
    required this.message,
    required this.onRetry,
    required this.onChangeServer,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChangeServer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Retry'),
        ),
        const SizedBox(height: 8),
        _LinkButton(label: 'Change server', onPressed: onChangeServer),
      ],
    );
  }
}
