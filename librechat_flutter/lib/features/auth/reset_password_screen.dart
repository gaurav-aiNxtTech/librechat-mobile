import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/app_exception.dart';
import 'auth_form.dart';

/// The Reset_Password_Screen (Req 11.6), opened at
/// `/reset-password?token=&userId=`. Copy follows the KMP feature/auth
/// `strings.xml` and ResetPasswordViewModel. Passwords are checked as on the
/// Register_Screen. Success shows the Server's message and opens `/login`.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token, this.userId});

  final String? token;
  final String? userId;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _validLink =>
      (widget.token?.isNotEmpty ?? false) &&
      (widget.userId?.isNotEmpty ?? false);

  /// Set in [build].
  int _minLength = defaultMinPasswordLength;

  void _clearPasswordErrors() {
    if (_passwordError == null && _confirmError == null) return;
    setState(() {
      _passwordError = null;
      _confirmError = null;
    });
  }

  /// Checks the passwords, then sends the reset (Req 11.6). Does nothing
  /// while a reset runs.
  Future<void> _submit() async {
    if (_submitting) return;
    final password = _password.text;
    final confirm = _confirm.text;
    setState(() {
      _error = null;
      _passwordError = password.isEmpty
          ? 'Please enter a new password'
          : passwordLengthError(password, _minLength);
      _confirmError = confirmPasswordError(password, confirm);
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(authServiceProvider)
          .api
          .resetPassword(
            userId: widget.userId!,
            token: widget.token!,
            password: password,
            confirmPassword: confirm,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serverText(
              message,
              'Your password has been updated. You can now sign in with your '
              'new password.',
            ),
          ),
        ),
      );
      context.go(Routes.login);
    } catch (e) {
      if (mounted) setState(() => _error = userMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _minLength = watchMinPasswordLength(ref);
    return AuthPage(
      title: 'Reset Password',
      children: _validLink ? _form() : _invalidLink(),
    );
  }

  List<Widget> _invalidLink() => [
    const AuthMessage('Invalid reset link. Please request a new one.'),
    const SizedBox(height: 16),
    AuthLinkButton(
      label: 'Forgot password?',
      onPressed: () => context.go(Routes.forgotPassword),
    ),
  ];

  List<Widget> _form() {
    final enabled = !_submitting;
    final error = _error;
    return [
      const AuthHeading('Set new password'),
      const SizedBox(height: 8),
      const AuthBodyText('Enter your new password below'),
      const SizedBox(height: 32),
      AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _password,
              label: 'New password',
              enabled: enabled,
              obscure: true,
              errorText: _passwordError,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => _clearPasswordErrors(),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirm,
              label: 'Confirm new password',
              enabled: enabled,
              obscure: true,
              errorText: _confirmError,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.go,
              onChanged: (_) => _clearPasswordErrors(),
              onSubmitted: (_) => unawaited(_submit()),
            ),
          ],
        ),
      ),
      if (error != null) ...[const SizedBox(height: 12), AuthMessage(error)],
      const SizedBox(height: 24),
      AuthSubmitButton(
        label: 'Reset password',
        busy: _submitting,
        onPressed: () => unawaited(_submit()),
      ),
      const SizedBox(height: 16),
      AuthLinkButton(
        label: 'Back to sign in',
        onPressed: enabled ? () => context.go(Routes.login) : null,
      ),
    ];
  }
}
