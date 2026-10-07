import 'package:flutter/material.dart';

import '../network/custom_headers.dart';

/// One editor row: `(name, value)`, the shape [buildCustomHeaders] takes.
typedef HeaderRow = (String, String);

/// The rejected rows, by index, for [HeadersEditor.errors] (Req 5.3). A row
/// whose name and value are both blank after trimming is skipped rather than
/// rejected, because [buildCustomHeaders] drops it (Req 5.4).
Map<int, HeaderProblem> headerRowProblems(List<HeaderRow> rows) => {
  for (final (i, (name, value)) in rows.indexed)
    if (name.trim().isNotEmpty || value.trim().isNotEmpty)
      i: ?validateHeader(name, value),
};

/// Below this width, name and value are stacked instead of side by side, so a
/// long name such as "CF-Access-Client-Secret" is not truncated (KMP
/// `STACK_BELOW_WIDTH`).
const double _stackBelowWidth = 420;

/// Editor for a server's Custom_Headers, shared by the Server_URL_Screen's
/// Advanced section and the "Server connection" dialog (Req 5.1). Copy follows
/// the KMP `core/ui` `server_headers_*` strings.
///
/// The parent owns the rows and the validation timing: every edit, add or
/// remove reports the new list through [onChanged], and the parent passes
/// [errors] (see [headerRowProblems]) after a submit. [errors] is indexed by
/// row, so the parent should recompute or clear it when the rows change. Only
/// which values are revealed lives here; every value starts masked.
class HeadersEditor extends StatefulWidget {
  const HeadersEditor({
    super.key,
    required this.rows,
    required this.onChanged,
    this.errors = const {},
    this.enabled = true,
    this.showTitle = true,
  });

  final List<HeaderRow> rows;
  final ValueChanged<List<HeaderRow>> onChanged;

  /// The reason each rejected row shows under itself, by row index.
  final Map<int, HeaderProblem> errors;
  final bool enabled;

  /// False where the host already names the editor, as the dialog title does.
  final bool showTitle;

  @override
  State<HeadersEditor> createState() => _HeadersEditorState();
}

class _HeadersEditorState extends State<HeadersEditor> {
  late List<_RowState> _rows = [
    for (final (name, value) in widget.rows) _RowState(name, value),
  ];

  @override
  void didUpdateWidget(HeadersEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rows = widget.rows;
    if (rows.length != _rows.length) {
      // Replaced from outside: start over, masked, so no reveal carries onto
      // another row's credential.
      for (final row in _rows) {
        row.dispose();
      }
      _rows = [for (final (name, value) in rows) _RowState(name, value)];
      return;
    }
    for (final (i, (name, value)) in rows.indexed) {
      _rows[i].name.syncText(name);
      _rows[i].value.syncText(value);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _report() => widget.onChanged([
    for (final row in _rows) (row.name.text, row.value.text),
  ]);

  void _add() {
    setState(() => _rows.add(_RowState('', '')));
    _report();
  }

  void _remove(_RowState row) {
    setState(() => _rows.remove(row));
    // Disposed after this frame, once its fields have unmounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < _stackBelowWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showTitle) ...[
              Semantics(
                header: true,
                child: Text(
                  'Custom request headers',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Sent with every request to this server. Needed for access '
              'gateways such as Cloudflare Access.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final (i, row) in _rows.indexed)
              _HeaderRowFields(
                key: ObjectKey(row),
                row: row,
                problem: widget.errors[i],
                stacked: stacked,
                enabled: widget.enabled,
                onEdited: _report,
                onToggleReveal: () =>
                    setState(() => row.revealed = !row.revealed),
                onRemove: () => _remove(row),
              ),
            TextButton(
              onPressed: widget.enabled ? _add : null,
              child: const Text('Add header'),
            ),
          ],
        );
      },
    );
  }
}

/// One row's text fields and whether its value is revealed. Identity, not
/// index, keys the row, so removing a row never moves a reveal or focus onto
/// its neighbour.
class _RowState {
  _RowState(String name, String value)
    : name = TextEditingController(text: name),
      value = TextEditingController(text: value);

  final TextEditingController name;
  final TextEditingController value;
  bool revealed = false;

  void dispose() {
    name.dispose();
    value.dispose();
  }
}

class _HeaderRowFields extends StatelessWidget {
  const _HeaderRowFields({
    super.key,
    required this.row,
    required this.problem,
    required this.stacked,
    required this.enabled,
    required this.onEdited,
    required this.onToggleReveal,
    required this.onRemove,
  });

  final _RowState row;
  final HeaderProblem? problem;
  final bool stacked;
  final bool enabled;
  final VoidCallback onEdited;
  final VoidCallback onToggleReveal;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final problem = this.problem;
    final nameRejected =
        problem == HeaderProblem.name || problem == HeaderProblem.reserved;

    final nameField = TextField(
      controller: row.name,
      enabled: enabled,
      onChanged: (_) => onEdited(),
      decoration: InputDecoration(
        labelText: 'Header name',
        border: const OutlineInputBorder(),
        // An empty error widget marks the field without repeating the reason,
        // which shows once under the row.
        error: nameRejected ? const SizedBox.shrink() : null,
      ),
    );

    final revealLabel = row.revealed ? 'Hide value' : 'Show value';
    final valueField = TextField(
      controller: row.value,
      enabled: enabled,
      onChanged: (_) => onEdited(),
      // A gateway token is a credential: masked by default, and kept out of the
      // keyboard's learning and suggestions.
      obscureText: !row.revealed,
      keyboardType: TextInputType.visiblePassword,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: 'Value',
        border: const OutlineInputBorder(),
        error: problem == HeaderProblem.value ? const SizedBox.shrink() : null,
        suffixIcon: IconButton(
          onPressed: enabled ? onToggleReveal : null,
          tooltip: revealLabel,
          icon: Icon(row.revealed ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );

    final Widget fields;
    if (stacked) {
      fields = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nameField,
          const SizedBox(height: 4),
          valueField,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: enabled ? onRemove : null,
              child: const Text('Remove header'),
            ),
          ),
        ],
      );
    } else {
      fields = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: nameField),
          const SizedBox(width: 8),
          Expanded(child: valueField),
          IconButton(
            onPressed: enabled ? onRemove : null,
            tooltip: 'Remove header',
            icon: const Icon(Icons.close),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fields,
          if (problem != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                problem.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on TextEditingController {
  /// Takes [text] from the parent unless the field already shows it, so the
  /// parent echoing an edit back leaves the cursor where it is.
  void syncText(String text) {
    if (this.text == text) return;
    value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
