import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../app/shell/shell_menu_button.dart';
import '../../core/config/server_config.dart';
import '../../core/images/app_image.dart';
import '../../core/models/message.dart';
import '../../core/network/app_exception.dart';
import '../../core/storage/settings_store.dart';
import '../../core/ui/error_view.dart';
import '../conversations/conversations_repository.dart';
import 'artifacts/artifact_parser.dart';
import 'composer/composer_bar.dart';
import 'composer/composer_controller.dart';
import 'composer/model_selector.dart';
import 'composer/quotes.dart';
import 'data/conversation_messages.dart';
import 'render/endpoint_icon.dart';
import 'render/find_matches.dart';
import 'render/live_reply_view.dart';
import 'render/message_actions.dart';
import 'render/message_view.dart';
import 'run/run_service.dart';
import 'tree/message_tree.dart';

/// The landing greeting for the local time [now] (KMP LandingContent.kt
/// `getTimeBasedGreeting`).
String timeGreeting(DateTime now) {
  final hour = now.hour;
  final weekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  if (weekend) {
    if (hour < 5) return 'Happy late night';
    if (hour < 12) return 'Happy weekend morning';
    if (hour < 17) return 'Happy weekend afternoon';
    return 'Happy weekend evening';
  }
  if (hour < 5) return 'Happy late night';
  if (hour < 9) return 'Good early morning';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// What the landing state shows for the selected model or agent (Req 17.8):
/// its [endpoint], the endpoint's or agent's [iconUrl], its [label] and the
/// agent's conversation [starters].
@immutable
class LandingSelection {
  const LandingSelection({
    this.endpoint,
    this.iconUrl,
    this.label,
    this.starters = const [],
  });

  final String? endpoint;
  final String? iconUrl;
  final String? label;
  final List<String> starters;

  @override
  bool operator ==(Object other) =>
      other is LandingSelection &&
      other.endpoint == endpoint &&
      other.iconUrl == iconUrl &&
      other.label == label &&
      _sameList(other.starters, starters);

  @override
  int get hashCode => Object.hash(endpoint, iconUrl, label, starters.length);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The landing state's selection, from the Composer's (Req 21.1): its
/// endpoint, the agent's avatar or the spec's or endpoint's icon, its label
/// and the agent's conversation starters.
final landingSelectionProvider = Provider.autoDispose<LandingSelection>((ref) {
  final selection = ref.watch(composerSelectionProvider(newChatKey));
  if (selection == null) return const LandingSelection();
  final data = ref.watch(selectorDataProvider);
  return LandingSelection(
    endpoint: selection.endpoint,
    iconUrl: selectionIconUrl(selection, data),
    label: selectionLabel(selection, data),
    starters: data.agent(selection.agentId)?.conversationStarters ?? const [],
  );
});

/// The Chat_Screen for `/chat` (the landing state) and
/// `/chat/c/:conversationId` (a conversation), each with the Composer.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = conversationId;
    if (id == null) return const _LandingScreen();
    return _ConversationScreen(conversationId: id);
  }
}

/// The landing state: the selected model's or agent's icon, the time-based
/// greeting, the Server's custom welcome and the agent's starters
/// (Req 17.8), above the Composer.
///
/// Each visit mints one Run key. Once a send starts, the Optimistic_Message
/// and the live reply replace the greeting (Req 18.1, 18.9), and when the
/// Run moves to its new conversation the screen goes to the conversation's
/// route, where the same Run keeps rendering (Req 18.10).
class _LandingScreen extends ConsumerStatefulWidget {
  const _LandingScreen();

  @override
  ConsumerState<_LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<_LandingScreen> {
  final _runKey = newChatRunKey();

  @override
  Widget build(BuildContext context) {
    ref.listen(runServiceProvider.select((s) => s.movedTo[_runKey]), (_, id) {
      if (id != null) context.go(Routes.chat(id));
    });
    final run = ref.watch(
      runServiceProvider.select(
        (s) => s.runs.containsKey(_runKey)
            ? (optimistic: s.runs[_runKey]!.optimistic)
            : null,
      ),
    );
    return Scaffold(
      appBar: AppBar(leading: ShellMenuButton.leading(context)),
      body: Column(
        children: [
          Expanded(
            child: run == null
                ? _LandingContent(
                    onStarter: (starter) => ref
                        .read(composerProvider(newChatKey).notifier)
                        .submitText(_runKey, starter),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (run.optimistic case final message?)
                        MessageView(message),
                      LiveReplyView(runKey: _runKey),
                    ],
                  ),
          ),
          ComposerBar(chatKey: newChatKey, runKey: _runKey),
        ],
      ),
    );
  }
}

class _LandingContent extends ConsumerWidget {
  const _LandingContent({required this.onStarter});

  final ValueChanged<String> onStarter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final welcome = ref
        .watch(
          serverConfigProvider.select(
            (s) => s.value?.config.interfaceConfig.customWelcome,
          ),
        )
        ?.trim();
    final selection = ref.watch(landingSelectionProvider);
    final label = selection.label?.trim();
    // Centered when it fits; scrolls when banners or a landscape phone
    // leave too little height.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LandingIcon(selection: selection),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      timeGreeting(DateTime.now()),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    welcome == null || welcome.isEmpty
                        ? 'How can I help you today?' // KMP how_can_i_help
                        : welcome,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (label != null && label.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                  if (selection.starters.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final starter in selection.starters)
                          ActionChip(
                            label: Text(starter),
                            onPressed: () => onStarter(starter),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected endpoint's or agent's icon: its `iconURL` through
/// [AppImage], else the bundled brand glyph, else the App's chat icon.
class _LandingIcon extends StatelessWidget {
  const _LandingIcon({required this.selection});

  final LandingSelection selection;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fallback = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: colors.primaryContainer,
        child: SizedBox.square(
          dimension: _size,
          child: Icon(
            Icons.chat_bubble_outline,
            size: 32,
            color: colors.onPrimaryContainer,
            semanticLabel: 'Switchboard', // KMP feature/chat cd_librechat
          ),
        ),
      ),
    );
    final label = selection.label ?? selection.endpoint;
    final asset = endpointIconAsset(selection.endpoint);
    final glyph = asset == null
        ? fallback
        : SvgPicture.asset(
            asset,
            width: _size,
            height: _size,
            semanticsLabel: label,
            colorFilter: isMonochromeEndpointIcon(selection.endpoint)
                ? ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn)
                : null,
          );
    final url = selection.iconUrl;
    if (url == null) return glyph;
    return ClipOval(
      child: AppImage(
        url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        semanticLabel: label,
        // Like KMP, a failed load falls back to the glyph silently.
        error: glyph,
      ),
    );
  }
}

/// One conversation: the Active_Path with SiblingNavigators, pinned
/// auto-scroll and a scroll-to-bottom button (Req 17.1, 17.2, 17.6, 17.7,
/// 17.10, 17.11).
class _ConversationScreen extends ConsumerWidget {
  const _ConversationScreen({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref
        .watch(conversationRowProvider(conversationId))
        .value
        ?.title
        ?.trim();
    // While a search runs, the field takes the app bar's title and Close
    // replaces the menu (Req 25.11).
    final searching = ref.watch(
      chatSearchProvider(conversationId).select((s) => s.active),
    );
    final search = ref.read(chatSearchProvider(conversationId).notifier);
    return Scaffold(
      appBar: AppBar(
        leading: searching ? null : ShellMenuButton.leading(context),
        titleSpacing: searching ? 8 : null,
        title: searching
            ? ChatSearchField(conversationId: conversationId)
            : Text(
                // KMP new_chat
                title == null || title.isEmpty ? 'New Chat' : title,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (searching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close search', // KMP cd_close_search
              onPressed: search.close,
            )
          else
            _ConversationMenu(
              conversationId: conversationId,
              onSearch: search.open,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ConversationView(conversationId: conversationId)),
          PendingQuoteChips(chatKey: conversationId),
          ComposerBar(chatKey: conversationId, runKey: conversationId),
        ],
      ),
    );
  }
}

/// The conversation app bar's menu. Search and media land here first; the
/// compact and trace entries join with their own tasks.
class _ConversationMenu extends StatelessWidget {
  const _ConversationMenu({
    required this.conversationId,
    required this.onSearch,
  });

  final String conversationId;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    icon: const Icon(Icons.more_vert),
    tooltip: 'More options', // KMP cd_more_options
    onSelected: (action) => action(),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: onSearch,
        child: const ListTile(
          leading: Icon(Icons.search),
          // KMP cd_search_in_conversation
          title: Text('Search in conversation'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      PopupMenuItem(
        value: () => context.go(Routes.conversationMedia(conversationId)),
        child: const ListTile(
          leading: Icon(Icons.perm_media_outlined),
          title: Text('Show all media'), // KMP action_show_all_media
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  );
}

/// Distance from the end, in logical pixels, inside which the list counts
/// as showing the newest content (Req 17.10, 17.11).
const pinnedThreshold = 48.0;

/// The body of an open conversation. See [_ConversationScreen].
///
/// The list follows the newest content while AppSettings `autoScroll` is on
/// and the user has not scrolled more than [pinnedThreshold] away from the
/// end: on open and after each change of the messages, a post-frame
/// callback jumps to `maxScrollExtent`, repeating until `extentAfter` is 0
/// so lazily built items settle. A scroll-to-bottom button shows while the
/// end is more than [pinnedThreshold] away.
///
/// While a search runs, each message carries the [ChatSearchScope] its
/// content parts highlight from, and the current match's message is
/// revealed (Req 25.11).
class ConversationView extends ConsumerStatefulWidget {
  const ConversationView({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<ConversationView> {
  final _scroll = ScrollController();

  /// Whether the user stays at the newest content. Only scrolls change it,
  /// so content growing below a pinned list does not unpin it.
  bool _pinned = true;

  /// Whether the scroll-to-bottom button shows. Kept out of `setState`, so
  /// scrolling never rebuilds the list.
  final _awayFromEnd = ValueNotifier(false);

  /// Bumped by each follow request, so only the newest one keeps jumping.
  int _follow = 0;

  /// One key per built message, which the search's reveal scrolls to
  /// (Req 25.11). A message the list has dropped keeps its key, so the key
  /// is live again as soon as the message is built.
  final _messageKeys = <String, GlobalKey>{};

  /// The Active_Path the last build rendered, which tells the reveal which
  /// way to scroll.
  List<Message> _path = const [];

  AsyncNotifierProvider<ConversationMessagesNotifier, ConversationMessages>
  get _provider => conversationMessagesProvider(widget.conversationId);

  /// Checks the conversation's Run when the App returns to the foreground
  /// (Req 19.8).
  late final AppLifecycleListener _lifecycle;

  /// The conversation's Run, without its parts: what places the
  /// Optimistic_Message and the live reply in the list. The parts are
  /// [LiveReplyView]'s alone, so a streamed event never rebuilds the list
  /// (Req 18.8).
  late final _run = runServiceProvider
      .select<({Message? optimistic, String? anchorId})?>((s) {
        final run = s.runs[widget.conversationId];
        return run == null
            ? null
            : (optimistic: run.optimistic, anchorId: run.anchorId);
      });

  @override
  void initState() {
    super.initState();
    ref.listenManual(_provider, (previous, next) {
      if (next.hasValue && previous?.value != next.value) _followEnd();
    }, fireImmediately: true);
    // A streaming reply grows the list too.
    ref.listenManual(
      runServiceProvider.select((s) => s.runs[widget.conversationId]),
      (previous, next) {
        if (next != null && previous != next) _followEnd();
      },
    );
    // Each new current match brings its message into view (Req 25.11).
    ref.listenManual(chatMatchesProvider(widget.conversationId), (
      previous,
      next,
    ) {
      final hit = next.hits.isEmpty ? null : next.hits[next.index];
      final before = previous == null || previous.hits.isEmpty
          ? null
          : previous.hits[previous.index];
      if (hit != null && hit != before) unawaited(_reveal(hit.messageId));
    });
    // Attaches to a Run the Server has for this conversation (Req 19.9).
    _checkRun();
    _lifecycle = AppLifecycleListener(onResume: _checkRun);
  }

  void _checkRun() => unawaited(
    ref.read(runServiceProvider.notifier).onOpen(widget.conversationId),
  );

  @override
  void dispose() {
    _lifecycle.dispose();
    _scroll.dispose();
    _awayFromEnd.dispose();
    super.dispose();
  }

  /// Keeps the newest content in view after this frame while auto-scroll
  /// is on and the list is pinned (Req 17.10).
  void _followEnd() {
    if (!ref.read(settingsProvider).autoScroll || !_pinned) return;
    final generation = ++_follow;
    WidgetsBinding.instance.addPostFrameCallback((_) => _jump(generation, 20));
  }

  void _jump(int generation, int attemptsLeft) {
    if (!mounted || generation != _follow || !_pinned) return;
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.extentAfter <= 0) return;
    _scroll.jumpTo(position.maxScrollExtent);
    if (attemptsLeft > 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _jump(generation, attemptsLeft - 1),
      );
    }
  }

  void _scrollToBottom() {
    _pinned = true;
    final generation = ++_follow;
    _jump(generation, 20);
  }

  /// Brings the message with [messageId] into view (Req 25.11).
  ///
  /// The list is lazy, so a message outside the built range has no context
  /// to scroll to yet. The list jumps one viewport at a time toward the
  /// message's share of the path until its key is live, then hands over to
  /// [Scrollable.ensureVisible].
  Future<void> _reveal(String messageId) async {
    // Stops a pending auto-scroll from pulling the list back to the end.
    final generation = ++_follow;
    _pinned = false;
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted || generation != _follow) return;
      // The key's own context, read fresh each pass: it is live only while
      // the list holds the message built.
      final target = _messageKeys[messageId]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: 0.2,
          duration: const Duration(milliseconds: 120),
        );
        return;
      }
      if (!_scroll.hasClients) return;
      final index = _path.indexWhere((m) => m.messageId == messageId);
      if (index < 0) return;
      final position = _scroll.position;
      final span = position.maxScrollExtent - position.minScrollExtent;
      // Where the message sits in the path against where the list is now,
      // which is all the direction the jump needs.
      final here = span <= 0
          ? 0.0
          : (position.pixels - position.minScrollExtent) / span;
      final want = _path.length <= 1 ? 0.0 : index / (_path.length - 1);
      final step = want > here
          ? position.viewportDimension
          : -position.viewportDimension;
      final next = (position.pixels + step).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next == position.pixels) return;
      _scroll.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final after = notification.metrics.extentAfter;
    // Scroll updates come from the user or from a follow jump; a list that
    // grows only changes its metrics.
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      _pinned = after < pinnedThreshold;
    }
    _awayFromEnd.value = after > pinnedThreshold;
    return false;
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth != 0) return false;
    _awayFromEnd.value = notification.metrics.extentAfter > pinnedThreshold;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final run = ref.watch(_run);
    return switch (state) {
      AsyncValue(:final value?) => _messages(value, run),
      // A just-created chat keeps its Run on screen while its messages
      // load (Req 18.10).
      _ when run != null => _messages(const ConversationMessages(), run),
      AsyncError(:final error) => ErrorView(
        title: 'Could not load messages', // New copy: the KMP_App has none
        message: userMessage(error),
        onRetry: () => unawaited(ref.read(_provider.notifier).reload()),
      ),
      _ => Center(
        child: Semantics(
          liveRegion: true,
          child: const CircularProgressIndicator(
            semanticsLabel: 'Loading messages', // New copy
          ),
        ),
      ),
    };
  }

  /// The Active_Path, plus a [run]'s Optimistic_Message and live reply. A
  /// Run's path ends at its anchor and the live reply follows; an attached
  /// Run has no anchor, so its reply follows the path's leaf.
  Widget _messages(
    ConversationMessages data,
    ({Message? optimistic, String? anchorId})? run,
  ) {
    var messages = data.messages;
    var path = data.path;
    if (run != null) {
      final optimistic = run.optimistic;
      if (optimistic != null &&
          !messages.any((m) => m.messageId == optimistic.messageId)) {
        messages = [...messages, optimistic];
      }
      path = activePath(messages, data.selection, anchorId: run.anchorId);
    }
    _path = path;
    final levels = pathSiblings(messages, path);
    // The identifier's versions, for the Artifact_Viewer's pager
    // (Req 24.12). One pass over the path serves every artifact in it.
    final versions = artifactVersions(path);
    // The in-conversation search's query and current match (Req 25.11).
    final matches = ref.watch(chatMatchesProvider(widget.conversationId));
    final current = matches.hits.isEmpty ? null : matches.hits[matches.index];
    final notifier = ref.read(_provider.notifier);
    final refreshError = data.refreshError;
    return Column(
      children: [
        if (refreshError != null)
          _RefreshErrorBanner(
            message: userMessage(refreshError),
            onRetry: () => unawaited(notifier.reload()),
          ),
        Expanded(
          child: Stack(
            children: [
              NotificationListener<ScrollMetricsNotification>(
                onNotification: _onMetrics,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: path.length + (run == null ? 0 : 1),
                    itemBuilder: (context, i) => i == path.length
                        ? LiveReplyView(
                            key: const ValueKey('live-reply'),
                            runKey: widget.conversationId,
                          )
                        : _item(
                            path,
                            levels,
                            i,
                            versions: versions,
                            justSettledId: data.justSettledId,
                            query: matches.query,
                            current: current,
                            onSelect: (siblingId) => notifier.select(
                              selectSibling(path, i, siblingId),
                            ),
                          ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 16,
                bottom: 16,
                child: ValueListenableBuilder(
                  valueListenable: _awayFromEnd,
                  builder: (context, away, _) => away
                      ? FloatingActionButton.small(
                          heroTag: null,
                          onPressed: _scrollToBottom,
                          tooltip:
                              'Scroll to bottom', // KMP cd_scroll_to_bottom
                          child: const Icon(Icons.arrow_downward),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// One path message with its actions (Req 25). [MessageActions] reads
  /// the `run != null` flag itself, so the list never passes it down and a
  /// Run starting does not rebuild every item (Req 18.8, 25.14).
  ///
  /// The message's [ChatSearchScope] carries the active [query] and, for
  /// the message that holds it, the [current] match, so its content parts
  /// highlight their text and a collapsed block that holds the match opens
  /// (Req 25.11).
  Widget _item(
    List<Message> path,
    List<List<Message>> levels,
    int i, {
    required Map<String, List<Artifact>> versions,
    required String? justSettledId,
    required String query,
    required SearchHit? current,
    required ValueChanged<String> onSelect,
  }) {
    final message = path[i];
    // The reply's parent user message, which regenerate, continue and an
    // assistant edit resubmit.
    final parent = i > 0 && path[i - 1].messageId == message.parentMessageId
        ? path[i - 1]
        : null;
    final id = message.messageId;
    return KeyedSubtree(
      key: _messageKeys.putIfAbsent(id, GlobalKey.new),
      child: ChatSearchScope(
        query: query,
        current: current?.messageId == id ? current : null,
        child: MessageActions(
          key: ValueKey(id),
          conversationId: widget.conversationId,
          message: message,
          parent: parent,
          siblings: levels[i],
          latestMessageId: path.last.messageId,
          artifactVersions: versions,
          justSettled: id == justSettledId,
          onSelectSibling: onSelect,
        ),
      ),
    );
  }
}

/// A failed refresh over shown messages (Req 45.3), with Retry.
class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: colors.errorContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'), // KMP retry
              ),
            ],
          ),
        ),
      ),
    );
  }
}
