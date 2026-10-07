import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/ui/headers_editor.dart';
import 'qr_scan_screen.dart';
import 'server_url_controller.dart';

/// The Server_URL_Screen (Req 5.1, 5.3, 5.7, 7, 8.5). Copy follows the KMP
/// feature/auth `strings.xml`. It opens with the stored Server_URL and
/// Custom_Headers, which is also how "Change server" shows them (Req 7.8).
class ServerUrlScreen extends ConsumerStatefulWidget {
  const ServerUrlScreen({super.key});

  @override
  ConsumerState<ServerUrlScreen> createState() => _ServerUrlScreenState();
}

class _ServerUrlScreenState extends ConsumerState<ServerUrlScreen> {
  late final _url = TextEditingController(
    text: ref.read(serverUrlControllerProvider).url,
  );

  ServerUrlController get _controller =>
      ref.read(serverUrlControllerProvider.notifier);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _submit() => unawaited(_controller.submit());

  Future<void> _scan() async {
    final result = await showQrScanner(context);
    if (result == null || !mounted) return;
    final (:url, :problem) = result;
    if (url != null) _controller.scanned(url);
    if (problem != null) _controller.scanFailed(problem);
  }

  Future<void> _confirmInsecure() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _InsecureConnectionDialog(),
    );
    if (!mounted) return;
    if (confirmed ?? false) {
      unawaited(_controller.confirmInsecure());
    } else {
      _controller.cancelInsecure();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(serverUrlControllerProvider, (previous, next) {
      // A scan changes the URL from outside the field.
      if (next.url != _url.text) {
        _url.value = TextEditingValue(
          text: next.url,
          selection: TextSelection.collapsed(offset: next.url.length),
        );
      }
      if (previous?.insecureUrl == null && next.insecureUrl != null) {
        unawaited(_confirmInsecure());
      }
      if (!(previous?.connected ?? false) && next.connected) {
        context.go(Routes.login);
      }
    });
    final state = ref.watch(serverUrlControllerProvider);
    final theme = Theme.of(context);
    final enabled = !state.probing;
    final error = state.urlProblem?.message ?? state.failure;

    return Scaffold(
      appBar: context.canPop() ? AppBar() : null,
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
                      'Connect to LibreChat',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your server URL to get started',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _url,
                    enabled: enabled,
                    onChanged: _controller.setUrl,
                    onSubmitted: (_) => _submit(),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://your-server.com',
                      border: const OutlineInputBorder(),
                      errorText: error,
                      errorMaxLines: 4,
                      helperText: state.scanProblem?.message,
                      helperMaxLines: 4,
                      suffixIcon: IconButton(
                        onPressed: enabled ? _scan : null,
                        tooltip: 'Scan QR code',
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _controller.toggleAdvanced,
                      icon: Icon(
                        state.advancedOpen
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                      label: Semantics(
                        expanded: state.advancedOpen,
                        child: const Text('Advanced'),
                      ),
                    ),
                  ),
                  if (state.advancedOpen)
                    HeadersEditor(
                      rows: state.rows,
                      onChanged: _controller.setRows,
                      errors: state.rowProblems,
                      enabled: enabled,
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: enabled ? _submit : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: state.probing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              semanticsLabel: 'Connecting',
                            ),
                          )
                        : const Text('Connect'),
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

/// The KMP cleartext warning (Req 7.4). Pops true for "Connect anyway".
class _InsecureConnectionDialog extends StatelessWidget {
  const _InsecureConnectionDialog();

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: const Text('Insecure connection'),
      content: const Text(
        'You are connecting over HTTP. Your login credentials and messages '
        'will be sent unencrypted and could be intercepted by others on the '
        'network.\n\nOnly use HTTP for local development servers.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Connect anyway', style: TextStyle(color: error)),
        ),
      ],
    );
  }
}
