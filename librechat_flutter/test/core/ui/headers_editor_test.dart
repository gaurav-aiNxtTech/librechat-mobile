import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/network/custom_headers.dart';
import 'package:librechat_flutter/core/ui/headers_editor.dart';

/// A parent that owns the rows and validates on "Save", as the
/// Server_URL_Screen and the "Server connection" dialog do.
class _Host extends StatefulWidget {
  const _Host(this.initial, {this.enabled = true, this.width});

  final List<HeaderRow> initial;
  final bool enabled;

  /// The editor's width, when the test needs the narrow layout.
  final double? width;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<HeaderRow> rows = widget.initial;
  Map<int, HeaderProblem> errors = const {};

  /// What "Save" stored, once no row was rejected.
  Map<String, String>? saved;

  /// Replaces the rows from outside, as a reload of the stored headers does.
  void replace(List<HeaderRow> next) => setState(() {
    rows = next;
    errors = const {};
  });

  void _save() => setState(() {
    errors = headerRowProblems(rows);
    if (errors.isEmpty) saved = buildCustomHeaders(rows);
  });

  @override
  Widget build(BuildContext context) {
    Widget editor = HeadersEditor(
      rows: rows,
      errors: errors,
      enabled: widget.enabled,
      onChanged: (next) => setState(() {
        rows = next;
        errors = const {};
      }),
    );
    final width = widget.width;
    if (width != null) {
      editor = Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(width: width, child: editor),
      );
    }
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            editor,
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

_HostState _host(WidgetTester tester) =>
    tester.state<_HostState>(find.byType(_Host));

List<HeaderRow> _rows(WidgetTester tester) => _host(tester).rows;

/// Every text the fields show, in order: name, value, name, value, ...
List<String> _fieldTexts(WidgetTester tester) => [
  for (final field in tester.widgetList<TextField>(find.byType(TextField)))
    field.controller!.text,
];

/// Row [i]'s name field.
Finder _nameField(int i) => find.byType(TextField).at(2 * i);

/// A view tall enough that many rows and the Save button fit on screen.
void _useTallView(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1400);
  addTearDown(tester.view.reset);
}

/// The value fields, in row order (each row's second TextField).
List<TextField> _valueFields(WidgetTester tester) => [
  for (final (i, field)
      in tester.widgetList<TextField>(find.byType(TextField)).indexed)
    if (i.isOdd) field,
];

void main() {
  testWidgets('shows the KMP title and description', (tester) async {
    await tester.pumpWidget(const _Host([]));
    expect(find.text('Custom request headers'), findsOneWidget);
    expect(
      find.text(
        'Sent with every request to this server. Needed for access gateways '
        'such as Cloudflare Access.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('masks each value until its own toggle is tapped', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host([('A', 'one'), ('B', 'two')]));
    expect(_valueFields(tester).map((f) => f.obscureText), [true, true]);
    expect(find.byTooltip('Show value'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Show value').first);
    await tester.pump();
    expect(_valueFields(tester).map((f) => f.obscureText), [false, true]);
    expect(find.byTooltip('Hide value'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide value'));
    await tester.pump();
    expect(_valueFields(tester).map((f) => f.obscureText), [true, true]);
  });

  testWidgets('adds an empty row and removes the tapped row', (tester) async {
    await tester.pumpWidget(const _Host([('A', 'one')]));

    await tester.tap(find.text('Add header'));
    await tester.pump();
    expect(_rows(tester), [('A', 'one'), ('', '')]);

    await tester.enterText(find.byType(TextField).at(2), 'B');
    expect(_rows(tester), [('A', 'one'), ('B', '')]);

    await tester.tap(find.byTooltip('Remove header').first);
    await tester.pump();
    expect(_rows(tester), [('B', '')]);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets(
    'shows the rejection under the rejected row and keeps every row',
    (tester) async {
      const typed = [('X-Ok', 'v'), ('Host', 'h'), ('', ''), ('X-Last', 'w')];
      await tester.pumpWidget(const _Host(typed));

      await tester.tap(find.text('Save'));
      await tester.pump();

      final message = find.text(HeaderProblem.reserved.message);
      expect(message, findsOneWidget);
      expect(_rows(tester), typed);
      final top = tester.getRect(message).top;
      expect(top, greaterThan(tester.getRect(find.text('Host')).bottom));
      expect(top, lessThan(tester.getRect(find.text('X-Last')).top));
    },
  );

  testWidgets('icon controls have at least 48 dp tap targets', (tester) async {
    await tester.pumpWidget(const _Host([('A', 'one')]));
    for (final tooltip in ['Show value', 'Remove header']) {
      final size = tester.getSize(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(48), reason: tooltip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tooltip);
    }
  });

  test('headerRowProblems skips blank rows and indexes the rest', () {
    expect(
      headerRowProblems([
        ('  ', ' '),
        ('Host', 'h'),
        ('X-Ok', 'v'),
        ('', 'v'),
        ('X-Bad', 'é'),
      ]),
      {
        1: HeaderProblem.reserved,
        3: HeaderProblem.name,
        4: HeaderProblem.value,
      },
    );
  });

  group('masking', () {
    testWidgets('masks every value again after the parent replaces the rows', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host([('A', 'one')]));
      await tester.tap(find.byTooltip('Show value'));
      await tester.pump();
      expect(_valueFields(tester).map((f) => f.obscureText), [false]);

      _host(tester).replace([('A', 'one'), ('B', 'two')]);
      await tester.pump();

      expect(_valueFields(tester).map((f) => f.obscureText), [true, true]);
      expect(find.byTooltip('Hide value'), findsNothing);
      expect(_fieldTexts(tester), ['A', 'one', 'B', 'two']);
    });

    testWidgets('keeps a reveal on its header when an earlier row is removed', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _Host([('A', 'one'), ('B', 'two'), ('C', 'three')]),
      );
      await tester.tap(find.byTooltip('Show value').at(1));
      await tester.pump();
      expect(_valueFields(tester).map((f) => f.obscureText), [
        true,
        false,
        true,
      ]);

      await tester.tap(find.byTooltip('Remove header').first);
      await tester.pump();

      expect(_rows(tester), [('B', 'two'), ('C', 'three')]);
      expect(_fieldTexts(tester), ['B', 'two', 'C', 'three']);
      // B, now at index 0, is still revealed; C, now at index 1, is not.
      expect(_valueFields(tester).map((f) => f.obscureText), [false, true]);
    });
  });

  group('rejected rows (Req 5.3)', () {
    const typed = [
      ('Bad Name', 'v'),
      ('', ''),
      ('Authorization', 't'),
      ('X-Ok', 'ok'),
      ('X-Val', 'é'),
      (' ', ' '),
    ];

    testWidgets('shows each reason under its own row and keeps every row', (
      tester,
    ) async {
      _useTallView(tester);
      await tester.pumpWidget(const _Host(typed));

      await tester.tap(find.text('Save'));
      await tester.pump();

      for (final (row, problem) in [
        (0, HeaderProblem.name),
        (2, HeaderProblem.reserved),
        (4, HeaderProblem.value),
      ]) {
        final message = find.text(problem.message);
        expect(message, findsOneWidget, reason: problem.name);
        final top = tester.getRect(message).top;
        expect(
          top,
          greaterThan(tester.getRect(_nameField(row)).bottom),
          reason: problem.name,
        );
        expect(
          top,
          lessThan(tester.getRect(_nameField(row + 1)).top),
          reason: problem.name,
        );
      }
      // Every typed row, the blank ones included, is still in the editor.
      expect(_rows(tester), typed);
      expect(_fieldTexts(tester), [
        for (final (name, value) in typed) ...[name, value],
      ]);
      expect(_host(tester).saved, isNull);
    });

    testWidgets('reports an edit made after a rejection', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(const _Host(typed));
      await tester.tap(find.text('Save'));
      await tester.pump();

      await tester.enterText(_nameField(2), 'X-Auth');
      await tester.pump();

      final edited = [...typed]..[2] = ('X-Auth', 't');
      expect(_rows(tester), edited);

      // The reported rows are what the next Save validates.
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text(HeaderProblem.reserved.message), findsNothing);
      expect(find.text(HeaderProblem.name.message), findsOneWidget);
      expect(find.text(HeaderProblem.value.message), findsOneWidget);
    });
  });

  group('blank rows (Req 5.4)', () {
    testWidgets('saves the headers built from the rows, without blank rows', (
      tester,
    ) async {
      await tester.pumpWidget(const _Host([(' X-A ', ' one ')]));
      await tester.tap(find.text('Add header'));
      await tester.pump();
      await tester.tap(find.text('Add header'));
      await tester.pump();
      await tester.enterText(_nameField(2), 'X-B');
      await tester.enterText(find.byType(TextField).at(5), 'two');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(_rows(tester), [(' X-A ', ' one '), ('', ''), ('X-B', 'two')]);
      expect(_host(tester).errors, isEmpty);
      expect(_host(tester).saved, {'X-A': 'one', 'X-B': 'two'});
    });

    testWidgets('a blank-only editor saves no headers and rejects nothing', (
      tester,
    ) async {
      const blank = [('', ''), ('  ', '\t ')];
      await tester.pumpWidget(const _Host(blank));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(_host(tester).errors, isEmpty);
      for (final problem in HeaderProblem.values) {
        expect(find.text(problem.message), findsNothing);
      }
      expect(_host(tester).saved, <String, String>{});
      expect(_rows(tester), blank);
    });

    testWidgets('keeps the last value of a name repeated in another case', (
      tester,
    ) async {
      await tester.pumpWidget(
        const _Host([('X-Token', 'old'), ('x-token', 'new')]),
      );

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(_host(tester).errors, isEmpty);
      expect(_host(tester).saved, {'x-token': 'new'});
    });
  });

  testWidgets('a disabled editor disables its fields and buttons', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host([('A', 'one')], enabled: false));

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(2));
    expect(fields.map((f) => f.enabled), everyElement(isFalse));
    final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
    expect(iconButtons, hasLength(2)); // Show value, Remove header.
    expect(iconButtons.map((b) => b.onPressed), everyElement(isNull));
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Add header'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Add header'), warnIfMissed: false);
    await tester.pump();
    expect(_rows(tester), [('A', 'one')]);
  });

  testWidgets('below 420 dp, "Remove header" is a text button that removes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Host([('A', 'one'), ('B', 'two')], width: 360),
    );

    final remove = find.widgetWithText(TextButton, 'Remove header');
    expect(remove, findsNWidgets(2));
    expect(find.byTooltip('Remove header'), findsNothing);

    await tester.tap(remove.first);
    await tester.pump();

    expect(_rows(tester), [('B', 'two')]);
    expect(_fieldTexts(tester), ['B', 'two']);
  });
}
