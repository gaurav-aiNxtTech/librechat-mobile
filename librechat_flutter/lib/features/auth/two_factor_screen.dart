import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/app_exception.dart';
import '../../core/ui/otp_field.dart';

/// The Two_Factor_Screen (Req 10). Copy follows the KMP feature/auth
/// `strings.xml`. The Login_Screen passes [tempToken] as the route's `extra`.
/// Success needs no navigation here: the router's redirect opens `/chat` once
/// the session is stored; failure stays here with the Server's message
/// (Req 10.4).
class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key, required this.tempToken});

  final String tempToken;

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _code = TextEditingController();
  final _backupCode = TextEditingController();
  final _codeFocus = FocusNode();
  bool _backupMode = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild the Verify button as the code changes.
    _code.addListener(_changed);
    _backupCode.addListener(_changed);
  }

  @override
  void dispose() {
    _code.dispose();
    _backupCode.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  String get _entry => _backupMode ? _backupCode.text.trim() : _code.text;

  bool get _ready =>
      !_submitting &&
      (_backupMode ? _entry.isNotEmpty : _entry.length == otpLength);

  void _toggleMode() => setState(() {
    _backupMode = !_backupMode;
    _error = null;
  });

  /// Sends the code, or the backup code in backup mode (Req 10.1–10.2).
  /// Does nothing while a verification runs.
  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .verifyTwoFactor(widget.tempToken, _entry, backupCode: _backupMode);
      // Still mounted only until the redirect runs; stays disabled.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = userMessage(e);
        // A rejected code is cleared for the next try; a network failure
        // keeps it for Verify.
        if (!_backupMode && e is AppException && e.kind == FailureKind.server) {
          _code.clear();
        }
      });
      if (!_backupMode) _codeFocus.requestFocus();
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = !_submitting;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _back),
        title: const Text('Two-Factor Authentication'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      _backupMode
                          ? 'Enter backup code'
                          : 'Enter verification code',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _backupMode
                        ? 'Enter one of your backup codes'
                        : 'Enter the 6-digit code from your authenticator app',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_backupMode)
                    TextField(
                      controller: _backupCode,
                      enabled: enabled,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => unawaited(_submit()),
                      decoration: const InputDecoration(
                        labelText: 'Backup code',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    OtpField(
                      controller: _code,
                      focusNode: _codeFocus,
                      enabled: enabled,
                      autofocus: true,
                      onCompleted: (_) => unawaited(_submit()),
                    ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  // A full code submits itself; a kept entry needs this.
                  FilledButton(
                    onPressed: _ready ? () => unawaited(_submit()) : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Verifying', // New copy.
                            ),
                          )
                        : const Text('Verify'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: enabled ? _toggleMode : null,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        _backupMode
                            ? 'Use authenticator code'
                            : 'Use backup code',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
