import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/auth/auth_service.dart';
import '../../core/config/feature_gate.dart';
import '../../core/models/conversation.dart';
import '../../core/models/tag.dart';
import 'conversations_repository.dart';

part 'conversation_list_controller.freezed.dart';

/// What the Conversation_List shows (Req 15).
///
/// The grouped list is [cached], paged by [nextCursor]. A search or a tag
/// filter shows [results] instead, paged by [resultsCursor] and never
/// cached; [results] is null in grouped mode. [loading] is the grouped
/// list's page-1 fetch and [searching] the results' page-1 fetch.
/// [loadingMore] and [pageError] belong to the mode on screen. [error] is
/// the last page-1 failure; the data on screen stays.
@freezed
abstract class ConversationListState with _$ConversationListState {
  const factory ConversationListState({
    @Default(<Conversation>[]) List<Conversation> cached,
    @Default(true) bool loading,
    String? nextCursor,
    @Default(false) bool loadingMore,
    Object? pageError,
    Object? error,
    @Default('') String query,
    List<Conversation>? results,
    String? resultsCursor,
    @Default(false) bool searching,
    @Default(<Tag>[]) List<Tag> tags,
    @Default(<String>[]) List<String> selectedTags,
  }) = _ConversationListState;
}

/// How long the search waits after the last keystroke (Req 15.7).
const searchDebounce = Duration(milliseconds: 500);

final conversationListControllerProvider =
    NotifierProvider.autoDispose<
      ConversationListController,
      ConversationListState
    >(ConversationListController.new);

/// Drives the Conversation_List: the cached rows from
/// [ConversationsRepository.watchList], page 1 refreshed on open, paging,
/// the debounced search and the tag filter (Req 15, 45.1-45.3).
///
/// Each response is checked against a generation counter, so a reply for a
/// query, filter or refresh that has since been replaced is dropped.
class ConversationListController extends Notifier<ConversationListState> {
  Timer? _debounce;

  /// Bumped by each grouped refresh.
  int _listGeneration = 0;

  /// Bumped by each search, filter change and return to the grouped list.
  int _resultsGeneration = 0;

  /// Bumped whenever the paged list changes under a running page load.
  int _pageGeneration = 0;

  late ConversationsRepository _repository;

  @override
  ConversationListState build() {
    ref.watch(authServiceProvider.select((a) => a.session?.user.id));
    _repository = ref.watch(conversationsRepositoryProvider);
    final subscription = _repository.watchList().listen(
      (rows) => state = state.copyWith(cached: rows),
      // A failed Cache read leaves the rows on screen; the fetch still runs.
      onError: (Object _) {},
    );
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(subscription.cancel());
    });
    ref.listen(
      featureGatesProvider.select((g) => g.has(Feature.bookmarks)),
      (_, on) => on
          ? unawaited(reloadTags())
          : state = state.copyWith(tags: const [], selectedTags: const []),
    );
    Future.microtask(() async {
      if (!ref.mounted) return;
      await _refreshList();
    });
    if (ref.read(featureGatesProvider).has(Feature.bookmarks)) {
      Future.microtask(() async {
        if (ref.mounted) await reloadTags();
      });
    }
    return const ConversationListState();
  }

  bool get _wantsResults =>
      state.query.trim().isNotEmpty || state.selectedTags.isNotEmpty;

  /// The search field's text. The search runs [searchDebounce] after the
  /// last change; a blank field with no tag selected shows the grouped list
  /// at once (Req 15.7, 15.8).
  void setQuery(String query) {
    if (query == state.query) return;
    _debounce?.cancel();
    state = state.copyWith(query: query);
    if (!_wantsResults) {
      _showList();
      return;
    }
    _debounce = Timer(searchDebounce, () => unawaited(_search()));
  }

  /// Selects or clears [tag] in the filter and reloads at once.
  void toggleTag(String tag) {
    final selected = [...state.selectedTags];
    if (!selected.remove(tag)) selected.add(tag);
    state = state.copyWith(selectedTags: selected);
    _debounce?.cancel();
    if (_wantsResults) {
      unawaited(_search());
    } else {
      _showList();
    }
  }

  /// Pull to refresh: page 1 of the mode on screen (Req 15.10).
  Future<void> refresh() => _wantsResults ? _search() : _refreshList();

  /// `GET /api/tags` for the filter chips. A selected tag that no longer
  /// exists is dropped from the filter. A failure keeps the chips.
  Future<void> reloadTags() async {
    try {
      final tags = await _repository.api.tags();
      if (!ref.mounted) return;
      final names = {for (final t in tags) t.tag};
      final selected = [
        for (final t in state.selectedTags)
          if (names.contains(t)) t,
      ];
      final changed = selected.length != state.selectedTags.length;
      state = state.copyWith(tags: tags, selectedTags: selected);
      if (changed) unawaited(refresh());
    } catch (_) {
      // The chips stay as they were; the next open loads them again.
    }
  }

  /// Takes the cursor of a refresh that ran outside this controller (the
  /// import).
  void listRefreshed(String? cursor) {
    _listGeneration++;
    _pageGeneration++;
    state = state.copyWith(
      nextCursor: cursor,
      loading: false,
      loadingMore: state.results == null ? false : state.loadingMore,
      pageError: state.results == null ? null : state.pageError,
    );
  }

  /// Applies a row action to the uncached [results]: [updated] replaces the
  /// row with [id], or null removes it. The grouped list follows the Cache.
  void resultChanged(String id, Conversation? updated) {
    final results = state.results;
    if (results == null) return;
    state = state.copyWith(
      results: [
        for (final c in results)
          if (c.conversationId != id) c else ?updated,
      ],
    );
  }

  /// Loads the next page of the mode on screen. Does nothing while a page
  /// loads, after the last page, or while a failed page waits for
  /// [retryPage].
  Future<void> loadMore() async {
    if (state.loadingMore || state.pageError != null) return;
    final inResults = state.results != null;
    final cursor = inResults ? state.resultsCursor : state.nextCursor;
    if (cursor == null || (inResults ? state.searching : state.loading)) {
      return;
    }
    final generation = _pageGeneration;
    final query = state.query;
    final tags = state.selectedTags;
    state = state.copyWith(loadingMore: true);
    try {
      if (inResults) {
        final page = await _repository.api.list(
          cursor: cursor,
          search: query,
          tags: tags,
        );
        if (!_current(generation)) return;
        state = state.copyWith(
          loadingMore: false,
          results: [...?state.results, ...page.conversations],
          resultsCursor: page.nextCursor,
        );
      } else {
        final next = await _repository.loadMore(cursor);
        if (!_current(generation)) return;
        state = state.copyWith(loadingMore: false, nextCursor: next);
      }
    } catch (e) {
      if (!_current(generation)) return;
      state = state.copyWith(loadingMore: false, pageError: e);
    }
  }

  /// The failed page's Retry row.
  Future<void> retryPage() {
    state = state.copyWith(pageError: null);
    return loadMore();
  }

  bool _current(int pageGeneration) =>
      ref.mounted && pageGeneration == _pageGeneration;

  Future<void> _refreshList() async {
    final generation = ++_listGeneration;
    if (state.results == null) _pageGeneration++;
    state = state.copyWith(
      loading: true,
      error: null,
      loadingMore: state.results == null ? false : state.loadingMore,
      pageError: state.results == null ? null : state.pageError,
    );
    try {
      final cursor = await _repository.refresh();
      if (!ref.mounted || generation != _listGeneration) return;
      state = state.copyWith(loading: false, nextCursor: cursor);
    } catch (e) {
      if (!ref.mounted || generation != _listGeneration) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final generation = ++_resultsGeneration;
    _pageGeneration++;
    final query = state.query;
    final tags = state.selectedTags;
    state = state.copyWith(
      searching: true,
      error: null,
      loadingMore: false,
      pageError: null,
    );
    try {
      final page = await _repository.api.list(search: query, tags: tags);
      if (!ref.mounted || generation != _resultsGeneration) return;
      state = state.copyWith(
        searching: false,
        results: page.conversations,
        resultsCursor: page.nextCursor,
      );
    } catch (e) {
      if (!ref.mounted || generation != _resultsGeneration) return;
      state = state.copyWith(searching: false, error: e);
    }
  }

  /// Back to the grouped list, dropping any search still out.
  void _showList() {
    _resultsGeneration++;
    _pageGeneration++;
    state = state.copyWith(
      results: null,
      resultsCursor: null,
      searching: false,
      loadingMore: false,
      pageError: null,
      error: null,
    );
  }
}
