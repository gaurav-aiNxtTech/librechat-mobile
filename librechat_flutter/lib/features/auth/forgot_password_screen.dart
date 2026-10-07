import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/app_exception.dart';
import 'auth_form.dart';

/// The `token` and `userId` query parameters of a password reset [link]
/// (Req 11.5), or null when either is missing or empty. The link's path,
/// which may sit under a subpath of the Server_URL, is not checked.
({String token, String userId})? resetParamsFromLink(String link) {
  final query = Uri.tryParse(link.trim())?.queryParameters;
  final token = query?['token'];
  final userId = query?['userId'];
  if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
    return null;
  }
  return (token: token, userId: userId);
}

/// The Forgot_Password_Screen (Req 11.4–11.5). Copy follows the KMP
/// feature/auth `strings.xml`. A reply with a `link`, which the Server sends
/// when it has no email service, opens the Reset_Password_Screen directly.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;

  /// The Server's confirmation once the request succeeded.
  String? _sent;

  @override
  void initState() {
    super.initState();
    // Rebuild the send button as the email changes.
    _email.addListener(_changed);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _ready => !_submitting && _email.text.trim().isNotEmpty;

  /// Sends the email (Req 11.4). Does nothing while a request runs.
  Future<void> _submit() async {
    if (!_ready) return;
    final email = _email.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final reply = await ref
          .read(authServiceProvider)
          .api
          .requestPasswordReset(email);
      if (!mounted) return;
      final params = reply.link == null
          ? null
          : resetParamsFromLink(reply.link!);
      if (params != null) {
        context.go(
          Uri(
            path: Routes.resetPassword,
            queryParameters: {'token': params.token, 'userId': params.userId},
          ).toString(),
        );
        return;
      }
      setState(
        () => _sent = serverText(
          reply.message,
          "We've sent a password reset link to $email",
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = userMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _signIn() => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    final error = _error;
    return AuthPage(
      title: 'Reset password',
      children: sent != null
          ? [
              const AuthHeading('Check your email'),
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: AuthBodyText(sent)),
              const SizedBox(height: 24),
              AuthSubmitButton(
                label: 'Back to sign in',
                busy: false,
                onPressed: _signIn,
              ),
            ]
          : [
              const AuthHeading('Forgot your password?'),
              const SizedBox(height: 8),
              const AuthBodyText('Enter your email to receive a reset link'),
              const SizedBox(height: 32),
              AuthTextField(
                controller: _email,
                label: 'Email',
                enabled: !_submitting,
                errorText: error,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => unawaited(_submit()),
              ),
              const SizedBox(height: 24),
              AuthSubmitButton(
                label: 'Send reset link',
                busy: _submitting,
                onPressed: _ready ? () => unawaited(_submit()) : null,
              ),
              const SizedBox(height: 16),
              AuthLinkButton(
                label: 'Back to sign in',
                onPressed: _submitting ? null : _signIn,
              ),
            ],
    );
  }
}
