import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/app_exception.dart';
import 'auth_form.dart';

/// The Register_Screen (Req 11.1–11.3). Copy follows the KMP feature/auth
/// `strings.xml` and RegisterViewModel. Success shows the Server's message
/// and opens `/login`; failure keeps the input.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Set in [build].
  int _minLength = defaultMinPasswordLength;

  /// Editing either password field clears both field errors.
  void _clearPasswordErrors() {
    if (_passwordError == null && _confirmError == null) return;
    setState(() {
      _passwordError = null;
      _confirmError = null;
    });
  }

  /// Checks the form (Req 11.2), then sends it (Req 11.1). Does nothing
  /// while a registration runs.
  Future<void> _submit() async {
    if (_submitting) return;
    final name = _name.text.trim();
    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    final blank =
        [name, username, email].any((v) => v.isEmpty) || password.isEmpty;
    setState(() {
      _error = blank ? 'All fields are required' : null;
      _passwordError = blank ? null : passwordLengthError(password, _minLength);
      _confirmError = blank ? null : confirmPasswordError(password, confirm);
    });
    if (blank || _passwordError != null || _confirmError != null) return;

    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(authServiceProvider)
          .api
          .register(
            name: name,
            username: username,
            email: email,
            password: password,
            confirmPassword: confirm,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // New copy as the fallback.
          content: Text(
            serverText(message, 'Account created. You can now sign in.'),
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
    final enabled = !_submitting;
    final error = _error;
    return AuthPage(
      children: [
        const AuthHeading('Create account'),
        const SizedBox(height: 32),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _name,
                label: 'Full name',
                enabled: enabled,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _username,
                label: 'Username',
                enabled: enabled,
                autofillHints: const [AutofillHints.newUsername],
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _email,
                label: 'Email',
                enabled: enabled,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _password,
                label: 'Password',
                enabled: enabled,
                obscure: true,
                errorText: _passwordError,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => _clearPasswordErrors(),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirm,
                label: 'Confirm password',
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
        if (error != null) ...[const SizedBox(height: 8), AuthMessage(error)],
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Sign up',
          busy: _submitting,
          onPressed: () => unawaited(_submit()),
        ),
        const SizedBox(height: 16),
        AuthLinkButton(
          label: 'Already have an account? Sign in',
          onPressed: enabled ? () => context.go(Routes.login) : null,
        ),
      ],
    );
  }
}
