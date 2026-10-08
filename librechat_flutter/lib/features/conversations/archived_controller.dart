import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/auth/auth_service.dart';
import '../../core/models/conversation.dart';
import 'conversations_repository.dart';

part 'archived_controller.freezed.dart';

/// What the Archived_Screen shows: the archived conversations paged so far
/// (never cached), the next page's [nextCursor], and the page-1 [error] or
/// the failed next page's [pageError].
@freezed
abstract class ArchivedState with _$ArchivedState {
  const factory ArchivedState({
    @Default(<Conversation>[]) List<Conversation> items,
    String? nextCursor,
    @Default(true) bool loading,
    @Default(false) bool loadingMore,
    Object? error,
    Object? pageError,
  }) = _ArchivedState;
}

final archivedControllerProvider =
    NotifierProvider.autoDispose<ArchivedController, ArchivedState>(
      ArchivedController.new,
    );

/// Drives the Archived_Screen (Req 16): pages
/// `GET /api/convos?isArchived=true`, unarchives and deletes.
class ArchivedController extends Notifier<ArchivedState> {
  /// Bumped by each refresh, so a page from before it is dropped.
  int _generation = 0;

  late ConversationsRepository _repository;

  @override
  ArchivedState build() {
    ref.watch(authServiceProvider.select((a) => a.session?.user.id));
    _repository = ref.watch(conversationsRepositoryProvider);
    Future.microtask(() async {
      if (ref.mounted) await refresh();
    });
    return const ArchivedState();
  }

  /// Page 1 again. A failure keeps the rows on screen and sets [error].
  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(
      loading: true,
      error: null,
      loadingMore: false,
      pageError: null,
    );
    try {
      final page = await _repository.api.list(isArchived: true);
      if (!_current(generation)) return;
      state = state.copyWith(
        loading: false,
        items: page.conversations,
        nextCursor: page.nextCursor,
      );
    } catch (e) {
      if (!_current(generation)) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// The next page. Does nothing while a page loads, after the last page,
  /// or while a failed page waits for [retryPage].
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null ||
        state.loading ||
        state.loadingMore ||
        state.pageError != null) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repository.api.list(cursor: cursor, isArchived: true);
      if (!_current(generation)) return;
      state = state.copyWith(
        loadingMore: false,
        items: [...state.items, ...page.conversations],
        nextCursor: page.nextCursor,
      );
    } catch (e) {
      if (!_current(generation)) return;
      state = state.copyWith(loadingMore: false, pageError: e);
    }
  }

  Future<void> retryPage() {
    state = state.copyWith(pageError: null);
    return loadMore();
  }

  /// `POST /api/convos/archive` with false; the row leaves this list and
  /// returns to the Conversation_List. Throws on failure.
  Future<void> unarchive(Conversation conversation) async {
    await _repository.setArchived(conversation, false);
    _remove(conversation.conversationId);
  }

  /// `DELETE /api/convos`; the row leaves this list. Throws on failure.
  Future<void> delete(String id) async {
    await _repository.delete(id);
    _remove(id);
  }

  void _remove(String? id) {
    if (!ref.mounted) return;
    state = state.copyWith(
      items: [
        for (final c in state.items)
          if (c.conversationId != id) c,
      ],
    );
  }

  bool _current(int generation) => ref.mounted && generation == _generation;
}
