import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/shell/banners.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/server_config.dart';
import '../../core/models/interface_config.dart';
import 'auth_form.dart';

/// KMP `terms_title`.
const _defaultTermsTitle = 'Terms of Service';

/// The terms text from Server_Config `modalContent`, which LibreChat allows
/// as one string or a list of lines. Empty when there is none.
String termsText(TermsOfServiceConfig? terms) => switch (terms?.modalContent) {
  final String text => text.trim(),
  final List<Object?> lines => lines.whereType<String>().join('\n').trim(),
  _ => '',
};

/// The Terms_Screen (Req 11.9–11.10), on the root navigator outside the
/// AppShell. Accept records the acceptance and opens `/chat`; Decline signs
/// out, and the router's redirect then opens `/login`.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _accepting = false;
  bool _declining = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).api.acceptTerms();
      if (!mounted) return;
      // Without this the remounted AppShell would send the user back to
      // /terms (Req 11.8).
      ref.read(termsCheckProvider.notifier).accepted();
      context.go(Routes.newChat);
    } catch (_) {
      // KMP TermsViewModel.
      if (mounted) {
        setState(() => _error = 'Could not accept terms. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _declining = true);
    try {
      // Clears the session whatever the logout call returns (Req 12.10).
      await ref.read(authServiceProvider).signOut();
    } finally {
      if (mounted) setState(() => _declining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final terms = ref.watch(
      serverConfigProvider.select(
        (s) => s.value?.config.interfaceConfig.termsOfService,
      ),
    );
    final title = terms?.modalTitle?.trim();
    final text = termsText(terms);
    final busy = _accepting || _declining;
    final error = _error;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: AuthHeading(
                    title == null || title.isEmpty ? _defaultTermsTitle : title,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SelectableText(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (error != null) ...[
                        AuthMessage(error),
                        const SizedBox(height: 8),
                      ],
                      AuthSubmitButton(
                        label: 'I Accept',
                        busy: _accepting,
                        onPressed: busy ? null : _accept,
                      ),
                      const SizedBox(height: 8),
                      AuthLinkButton(
                        label: 'Decline', // New copy.
                        onPressed: busy ? null : _decline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
