import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/content_part.dart';
import '../../../core/models/message.dart';
import '../data/conversation_messages.dart';
import 'activity_groups.dart';
import 'message_view.dart';

// ─── Pure helpers ────────────────────────────────────────────────────

/// One match of the in-conversation search (Req 25.11): the message it sits
/// in, the index of the part in that message's content, and the character
/// offset of the match in the part's searchable text.
typedef SearchHit = ({String messageId, int partIndex, int offset});

/// The character range `[start, end)` of one match.
typedef MatchRange = ({int start, int end});

/// The text of [part] the search reads, or null for a part that renders no
/// searchable text.
///
/// This is the whole searchable surface of a message (Req 25.11): the reply
/// and user text, the model's reasoning, the user's mid-run steer turns and
/// the activity labels. A tool call's arguments and output, an error, a
/// context summary and the media parts are left out, as in the KMP_App.
String? searchablePartText(ContentPart part) => switch (part.type) {
  ContentPartType.text || ContentPartType.textDelta => part.text,
  ContentPartType.think => part.think,
  // The Server sends the steered text as a string.
  ContentPartType.steer => part.steer is String ? part.steer as String : null,
  ContentPartType.activityLabel => part.activityLabel,
  _ => null,
};

/// The ranges of every case-insensitive, non-overlapping match of [query]
/// in [text], in order. A blank [query] matches nothing.
///
/// The scan runs on the original [text], so the returned offsets address
/// its characters: a lower-cased copy can change length and shift them.
List<MatchRange> matchRanges(String text, String query) {
  if (query.isEmpty || text.isEmpty) return const [];
  return [
    for (final m in RegExp(
      RegExp.escape(query),
      caseSensitive: false,
    ).allMatches(text))
      (start: m.start, end: m.end),
  ];
}

/// Every match of [query] in the Active_Path [path], in render order
/// (Req 25.11). Case-insensitive; a blank query matches nothing.
///
/// Each message is walked through [visibleParts] of its [displayParts], the
/// same list the bubble renders, so a hit's `partIndex` always names a part
/// that is on screen. A message with no `content` is searched through its
/// own `text`, as part 0.
List<SearchHit> findMatches(List<Message> path, String query) {
  final needle = query.trim();
  if (needle.isEmpty) return const [];
  final hits = <SearchHit>[];
  for (final message in path) {
    for (final entry in visibleParts(displayParts(message))) {
      final text = searchablePartText(entry.part);
      if (text == null || text.isEmpty) continue;
      for (final range in matchRanges(text, needle)) {
        hits.add((
          messageId: message.messageId,
          partIndex: entry.index,
          offset: range.start,
        ));
      }
    }
  }
  return hits;
}

// ─── State ───────────────────────────────────────────────────────────

/// What the Chat_Screen's search field holds for one conversation
/// (Req 25.11). [index] is the current match, clamped to the matches by
/// [chatMatchesProvider].
@immutable
class ChatSearch {
  const ChatSearch({this.active = false, this.query = '', this.index = 0});

  /// Whether the app bar shows the search field.
  final bool active;
  final String query;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is ChatSearch &&
      other.active == active &&
      other.query == query &&
      other.index == index;

  @override
  int get hashCode => Object.hash(active, query, index);
}

/// The in-conversation search of one conversation. See [ChatSearchController].
final chatSearchProvider = NotifierProvider.autoDispose
    .family<ChatSearchController, ChatSearch, String>(ChatSearchController.new);

/// Opens and closes the search field, holds its query and moves between the
/// matches (Req 25.11).
///
/// The matches themselves are [chatMatchesProvider]'s, so typing never
/// rebuilds this notifier and the query survives every message change.
class ChatSearchController extends Notifier<ChatSearch> {
  ChatSearchController(this.conversationId);

  final String conversationId;

  @override
  ChatSearch build() => const ChatSearch();

  void open() => state = const ChatSearch(active: true);

  void close() => state = const ChatSearch();

  /// A new query starts again at the first match.
  void setQuery(String query) => state = ChatSearch(active: true, query: query);

  /// Moves to the next match of [count], wrapping at the end.
  void next(int count) => _move(1, count);

  /// Moves to the previous match of [count], wrapping at the start.
  void previous(int count) => _move(-1, count);

  void _move(int step, int count) {
    if (count <= 0) return;
    state = ChatSearch(
      active: true,
      query: state.query,
      index: (state.index + step + count) % count,
    );
  }
}

/// The conversation's matches for its active query: the trimmed [query]
/// (empty while no search runs), the [hits] in render order and the [index]
/// of the current one.
typedef ChatMatches = ({String query, List<SearchHit> hits, int index});

/// The matches of [chatSearchProvider]'s query in the conversation's
/// Active_Path (Req 25.11).
final chatMatchesProvider = Provider.autoDispose.family<ChatMatches, String>((
  ref,
  conversationId,
) {
  const none = (query: '', hits: <SearchHit>[], index: 0);
  final search = ref.watch(chatSearchProvider(conversationId));
  final query = search.query.trim();
  if (!search.active || query.isEmpty) return none;
  final messages = ref
      .watch(conversationMessagesProvider(conversationId))
      .value;
  if (messages == null) return (query: query, hits: const [], index: 0);
  final hits = findMatches(messages.path, query);
  return (
    query: query,
    hits: hits,
    index: hits.isEmpty ? 0 : search.index.clamp(0, hits.length - 1),
  );
});

// ─── Rendering ───────────────────────────────────────────────────────

/// All matches of the query (KMP `SearchHighlightYellow`).
const _matchLight = Color(0xFFFFEB3B);
const _matchDark = Color(0xFF5C4800);

/// The current match (KMP `SearchHighlightOrange`).
const _currentLight = Color(0xFFFF9800);
const _currentDark = Color(0xFF804D00);

/// The active query and the current match, for the message below it
/// (Req 25.11).
///
/// The Chat_Screen installs one per message, so a content part can
/// highlight its text and a collapsed block can tell whether the current
/// match is inside it, without any part watching the search itself.
class ChatSearchScope extends InheritedWidget {
  const ChatSearchScope({
    super.key,
    required this.query,
    required this.current,
    required super.child,
  });

  /// The trimmed query, or `''` while no search runs.
  final String query;

  /// The current match when it is in this message, else null.
  final SearchHit? current;

  static ChatSearchScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatSearchScope>();

  /// Whether the current match sits in the part at [partIndex].
  static bool holdsCurrent(BuildContext context, int partIndex) =>
      maybeOf(context)?.current?.partIndex == partIndex;

  @override
  bool updateShouldNotify(ChatSearchScope old) =>
      old.query != query || old.current != current;
}

/// [text] as plain text with the query's matches highlighted, or null when
/// no search runs or [text] holds no match, so the caller renders the text
/// the way it normally does (Req 25.11).
///
/// [partIndex] names the part the text belongs to, so only the part that
/// holds the current match paints it in the current-match color; a text
/// without an index, such as an activity group's header, highlights its
/// matches without ever focusing one.
Widget? searchHighlight(
  BuildContext context,
  String text, {
  int? partIndex,
  TextStyle? style,
}) {
  final scope = ChatSearchScope.maybeOf(context);
  if (scope == null || scope.query.isEmpty || text.isEmpty) return null;
  final ranges = matchRanges(text, scope.query);
  if (ranges.isEmpty) return null;
  final dark = Theme.of(context).colorScheme.surface.computeLuminance() < 0.5;
  final match = dark ? _matchDark : _matchLight;
  final current = dark ? _currentDark : _currentLight;
  final focused = partIndex != null && scope.current?.partIndex == partIndex
      ? scope.current!.offset
      : null;
  final spans = <InlineSpan>[];
  var at = 0;
  for (final range in ranges) {
    if (range.start > at) {
      spans.add(TextSpan(text: text.substring(at, range.start)));
    }
    spans.add(
      TextSpan(
        text: text.substring(range.start, range.end),
        style: TextStyle(
          backgroundColor: range.start == focused ? current : match,
        ),
      ),
    );
    at = range.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return Text.rich(TextSpan(children: spans), style: style);
}

/// The Chat_Screen's search field, which takes the app bar's title while a
/// search runs (Req 25.11, KMP InConvoSearchBar.kt): the query, "n/m", and
/// previous and next, which are off without a match.
class ChatSearchField extends ConsumerStatefulWidget {
  const ChatSearchField({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatSearchField> createState() => _ChatSearchFieldState();
}

class _ChatSearchFieldState extends ConsumerState<ChatSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: ref.read(chatSearchProvider(widget.conversationId)).query,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final matches = ref.watch(chatMatchesProvider(widget.conversationId));
    final controller = ref.read(
      chatSearchProvider(widget.conversationId).notifier,
    );
    final count = matches.hits.length;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            autofocus: true,
            onChanged: controller.setQuery,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => controller.next(count),
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              border: InputBorder.none,
              // KMP hint_find_in_conversation
              hintText: 'Find in conversation…',
            ),
          ),
        ),
        if (matches.query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                count == 0 ? '0/0' : '${matches.index + 1}/$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          tooltip: 'Previous match', // KMP cd_previous_match
          onPressed: count == 0 ? null : () => controller.previous(count),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          tooltip: 'Next match', // KMP cd_next_match
          onPressed: count == 0 ? null : () => controller.next(count),
        ),
      ],
    );
  }
}
