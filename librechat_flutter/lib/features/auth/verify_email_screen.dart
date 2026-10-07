import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/app_exception.dart';
import 'auth_form.dart';

/// The Verify_Email_Screen (Req 9.7, 11.7), opened at `/verify-email?email=`.
/// Copy follows the KMP feature/auth `strings.xml` and VerifyEmailViewModel.
/// After a successful resend, resending stays disabled for [cooldown] with a
/// visible countdown.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.cooldown = const Duration(seconds: 60),
  });

  final String email;
  final Duration cooldown;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  String? _error;
  String? _sent;
  Timer? _timer;

  /// Whole seconds left before resending is allowed again.
  int _remaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _email => widget.email.trim();

  bool get _ready => !_sending && _remaining == 0 && _email.isNotEmpty;

  /// Asks the Server to send the email again (Req 11.7). Does nothing while
  /// a request or the countdown runs.
  Future<void> _resend() async {
    if (!_ready) return;
    setState(() {
      _sending = true;
      _error = null;
      _sent = null;
    });
    try {
      final message = await ref
          .read(authServiceProvider)
          .api
          .resendVerification(_email);
      if (!mounted) return;
      setState(() => _sent = serverText(message, 'Verification email sent!'));
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _error = userMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    if (widget.cooldown.inSeconds <= 0) return;
    setState(() => _remaining = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    final sent = _sent;
    return AuthPage(
      title: 'Verify Email',
      children: [
        const AuthHeading('Check your email'),
        const SizedBox(height: 16),
        const AuthBodyText("We've sent a verification link to"),
        if (_email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Click the link in the email to verify your account.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (error != null) ...[const SizedBox(height: 12), AuthMessage(error)],
        if (sent != null) ...[
          const SizedBox(height: 12),
          AuthMessage(sent, error: false),
        ],
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: _ready ? () => unawaited(_resend()) : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: _sending
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Loading', // New copy.
                  ),
                )
              : Text(
                  _remaining > 0
                      ? 'Resend in ${_remaining}s'
                      : 'Resend verification email',
                ),
        ),
        const SizedBox(height: 16),
        AuthSubmitButton(
          label: 'Back to sign in',
          busy: false,
          onPressed: () => context.go(Routes.login),
        ),
      ],
    );
  }
}
