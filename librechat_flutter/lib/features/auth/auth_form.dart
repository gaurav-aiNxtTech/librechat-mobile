import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/config/server_config.dart';
import '../../core/network/app_exception.dart';

/// KMP RegisterViewModel's minimum when Server_Config has no
/// `minPasswordLength`.
const defaultMinPasswordLength = 8;

/// Server_Config `minPasswordLength`, or [defaultMinPasswordLength] while
/// none is loaded or set. Call from `build`, so the config stays loaded and a
/// later value rebuilds the screen.
int watchMinPasswordLength(WidgetRef ref) =>
    ref.watch(
      serverConfigProvider.select((s) => s.value?.config.minPasswordLength),
    ) ??
    defaultMinPasswordLength;

/// The password field's error before sending, or null (Req 11.2). Copy from
/// KMP RegisterViewModel.
String? passwordLengthError(String password, int minLength) =>
    password.length < minLength
    ? 'Password must be at least $minLength characters'
    : null;

/// The confirmation field's error before sending, or null (Req 11.2). Copy
/// from KMP RegisterViewModel.
String? confirmPasswordError(String password, String confirm) =>
    password == confirm ? null : 'Passwords do not match';

/// The Server's success [message] when it reads as a sentence for a person,
/// otherwise [fallback].
String serverText(String? message, String fallback) =>
    message != null && looksLikeUserMessage(message)
    ? message.trim()
    : fallback;

/// The scrolling, width-capped column every account screen sits in. With a
/// [title], an app bar with Back leads to the previous screen, or to
/// `/login` when there is none.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              leading: BackButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(Routes.login),
              ),
              title: Text(title),
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A centered heading, announced as one.
class AuthHeading extends StatelessWidget {
  const AuthHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}

/// Secondary explanatory text under a heading.
class AuthBodyText extends StatelessWidget {
  const AuthBodyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// A form-level message, read out when it appears. Error colored unless
/// [error] is false.
class AuthMessage extends StatelessWidget {
  const AuthMessage(this.text, {super.key, this.error = true});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: error ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// The full-width primary action. While [busy], it shows a spinner in place
/// of [label] and ignores taps.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    child: busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Loading', // New copy.
            ),
          )
        : Text(label),
  );
}

/// A centered text link with a 48 dp target.
class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

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

/// An outlined text field for the account forms.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.enabled,
    this.errorText,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? errorText;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: obscure,
    keyboardType: obscure ? TextInputType.visiblePassword : keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    autocorrect: false,
    enableSuggestions: !obscure && keyboardType != TextInputType.emailAddress,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: label,
      errorText: errorText,
      border: const OutlineInputBorder(),
    ),
  );
}
