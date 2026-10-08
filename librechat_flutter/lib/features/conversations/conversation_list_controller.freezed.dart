// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConversationListState {

 List<Conversation> get cached; bool get loading; String? get nextCursor; bool get loadingMore; Object? get pageError; Object? get error; String get query; List<Conversation>? get results; String? get resultsCursor; String get resultsQuery; List<String> get resultsTags; bool get searching; List<Tag> get tags; List<String> get selectedTags;
/// Create a copy of ConversationListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationListStateCopyWith<ConversationListState> get copyWith => _$ConversationListStateCopyWithImpl<ConversationListState>(this as ConversationListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationListState&&const DeepCollectionEquality().equals(other.cached, cached)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&const DeepCollectionEquality().equals(other.pageError, pageError)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.resultsCursor, resultsCursor) || other.resultsCursor == resultsCursor)&&(identical(other.resultsQuery, resultsQuery) || other.resultsQuery == resultsQuery)&&const DeepCollectionEquality().equals(other.resultsTags, resultsTags)&&(identical(other.searching, searching) || other.searching == searching)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.selectedTags, selectedTags));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cached),loading,nextCursor,loadingMore,const DeepCollectionEquality().hash(pageError),const DeepCollectionEquality().hash(error),query,const DeepCollectionEquality().hash(results),resultsCursor,resultsQuery,const DeepCollectionEquality().hash(resultsTags),searching,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(selectedTags));

@override
String toString() {
  return 'ConversationListState(cached: $cached, loading: $loading, nextCursor: $nextCursor, loadingMore: $loadingMore, pageError: $pageError, error: $error, query: $query, results: $results, resultsCursor: $resultsCursor, resultsQuery: $resultsQuery, resultsTags: $resultsTags, searching: $searching, tags: $tags, selectedTags: $selectedTags)';
}


}

/// @nodoc
abstract mixin class $ConversationListStateCopyWith<$Res>  {
  factory $ConversationListStateCopyWith(ConversationListState value, $Res Function(ConversationListState) _then) = _$ConversationListStateCopyWithImpl;
@useResult
$Res call({
 List<Conversation> cached, bool loading, String? nextCursor, bool loadingMore, Object? pageError, Object? error, String query, List<Conversation>? results, String? resultsCursor, String resultsQuery, List<String> resultsTags, bool searching, List<Tag> tags, List<String> selectedTags
});




}
/// @nodoc
class _$ConversationListStateCopyWithImpl<$Res>
    implements $ConversationListStateCopyWith<$Res> {
  _$ConversationListStateCopyWithImpl(this._self, this._then);

  final ConversationListState _self;
  final $Res Function(ConversationListState) _then;

/// Create a copy of ConversationListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cached = null,Object? loading = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? pageError = freezed,Object? error = freezed,Object? query = null,Object? results = freezed,Object? resultsCursor = freezed,Object? resultsQuery = null,Object? resultsTags = null,Object? searching = null,Object? tags = null,Object? selectedTags = null,}) {
  return _then(_self.copyWith(
cached: null == cached ? _self.cached : cached // ignore: cast_nullable_to_non_nullable
as List<Conversation>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,pageError: freezed == pageError ? _self.pageError : pageError ,error: freezed == error ? _self.error : error ,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: freezed == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<Conversation>?,resultsCursor: freezed == resultsCursor ? _self.resultsCursor : resultsCursor // ignore: cast_nullable_to_non_nullable
as String?,resultsQuery: null == resultsQuery ? _self.resultsQuery : resultsQuery // ignore: cast_nullable_to_non_nullable
as String,resultsTags: null == resultsTags ? _self.resultsTags : resultsTags // ignore: cast_nullable_to_non_nullable
as List<String>,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<Tag>,selectedTags: null == selectedTags ? _self.selectedTags : selectedTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationListState].
extension ConversationListStatePatterns on ConversationListState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationListState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationListState value)  $default,){
final _that = this;
switch (_that) {
case _ConversationListState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationListState value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationListState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Conversation> cached,  bool loading,  String? nextCursor,  bool loadingMore,  Object? pageError,  Object? error,  String query,  List<Conversation>? results,  String? resultsCursor,  String resultsQuery,  List<String> resultsTags,  bool searching,  List<Tag> tags,  List<String> selectedTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationListState() when $default != null:
return $default(_that.cached,_that.loading,_that.nextCursor,_that.loadingMore,_that.pageError,_that.error,_that.query,_that.results,_that.resultsCursor,_that.resultsQuery,_that.resultsTags,_that.searching,_that.tags,_that.selectedTags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Conversation> cached,  bool loading,  String? nextCursor,  bool loadingMore,  Object? pageError,  Object? error,  String query,  List<Conversation>? results,  String? resultsCursor,  String resultsQuery,  List<String> resultsTags,  bool searching,  List<Tag> tags,  List<String> selectedTags)  $default,) {final _that = this;
switch (_that) {
case _ConversationListState():
return $default(_that.cached,_that.loading,_that.nextCursor,_that.loadingMore,_that.pageError,_that.error,_that.query,_that.results,_that.resultsCursor,_that.resultsQuery,_that.resultsTags,_that.searching,_that.tags,_that.selectedTags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Conversation> cached,  bool loading,  String? nextCursor,  bool loadingMore,  Object? pageError,  Object? error,  String query,  List<Conversation>? results,  String? resultsCursor,  String resultsQuery,  List<String> resultsTags,  bool searching,  List<Tag> tags,  List<String> selectedTags)?  $default,) {final _that = this;
switch (_that) {
case _ConversationListState() when $default != null:
return $default(_that.cached,_that.loading,_that.nextCursor,_that.loadingMore,_that.pageError,_that.error,_that.query,_that.results,_that.resultsCursor,_that.resultsQuery,_that.resultsTags,_that.searching,_that.tags,_that.selectedTags);case _:
  return null;

}
}

}

/// @nodoc


class _ConversationListState implements ConversationListState {
  const _ConversationListState({final  List<Conversation> cached = const <Conversation>[], this.loading = true, this.nextCursor, this.loadingMore = false, this.pageError, this.error, this.query = '', final  List<Conversation>? results, this.resultsCursor, this.resultsQuery = '', final  List<String> resultsTags = const <String>[], this.searching = false, final  List<Tag> tags = const <Tag>[], final  List<String> selectedTags = const <String>[]}): _cached = cached,_results = results,_resultsTags = resultsTags,_tags = tags,_selectedTags = selectedTags;
  

 final  List<Conversation> _cached;
@override@JsonKey() List<Conversation> get cached {
  if (_cached is EqualUnmodifiableListView) return _cached;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cached);
}

@override@JsonKey() final  bool loading;
@override final  String? nextCursor;
@override@JsonKey() final  bool loadingMore;
@override final  Object? pageError;
@override final  Object? error;
@override@JsonKey() final  String query;
 final  List<Conversation>? _results;
@override List<Conversation>? get results {
  final value = _results;
  if (value == null) return null;
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? resultsCursor;
@override@JsonKey() final  String resultsQuery;
 final  List<String> _resultsTags;
@override@JsonKey() List<String> get resultsTags {
  if (_resultsTags is EqualUnmodifiableListView) return _resultsTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resultsTags);
}

@override@JsonKey() final  bool searching;
 final  List<Tag> _tags;
@override@JsonKey() List<Tag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<String> _selectedTags;
@override@JsonKey() List<String> get selectedTags {
  if (_selectedTags is EqualUnmodifiableListView) return _selectedTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedTags);
}


/// Create a copy of ConversationListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationListStateCopyWith<_ConversationListState> get copyWith => __$ConversationListStateCopyWithImpl<_ConversationListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationListState&&const DeepCollectionEquality().equals(other._cached, _cached)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&const DeepCollectionEquality().equals(other.pageError, pageError)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.resultsCursor, resultsCursor) || other.resultsCursor == resultsCursor)&&(identical(other.resultsQuery, resultsQuery) || other.resultsQuery == resultsQuery)&&const DeepCollectionEquality().equals(other._resultsTags, _resultsTags)&&(identical(other.searching, searching) || other.searching == searching)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._selectedTags, _selectedTags));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cached),loading,nextCursor,loadingMore,const DeepCollectionEquality().hash(pageError),const DeepCollectionEquality().hash(error),query,const DeepCollectionEquality().hash(_results),resultsCursor,resultsQuery,const DeepCollectionEquality().hash(_resultsTags),searching,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_selectedTags));

@override
String toString() {
  return 'ConversationListState(cached: $cached, loading: $loading, nextCursor: $nextCursor, loadingMore: $loadingMore, pageError: $pageError, error: $error, query: $query, results: $results, resultsCursor: $resultsCursor, resultsQuery: $resultsQuery, resultsTags: $resultsTags, searching: $searching, tags: $tags, selectedTags: $selectedTags)';
}


}

/// @nodoc
abstract mixin class _$ConversationListStateCopyWith<$Res> implements $ConversationListStateCopyWith<$Res> {
  factory _$ConversationListStateCopyWith(_ConversationListState value, $Res Function(_ConversationListState) _then) = __$ConversationListStateCopyWithImpl;
@override @useResult
$Res call({
 List<Conversation> cached, bool loading, String? nextCursor, bool loadingMore, Object? pageError, Object? error, String query, List<Conversation>? results, String? resultsCursor, String resultsQuery, List<String> resultsTags, bool searching, List<Tag> tags, List<String> selectedTags
});




}
/// @nodoc
class __$ConversationListStateCopyWithImpl<$Res>
    implements _$ConversationListStateCopyWith<$Res> {
  __$ConversationListStateCopyWithImpl(this._self, this._then);

  final _ConversationListState _self;
  final $Res Function(_ConversationListState) _then;

/// Create a copy of ConversationListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cached = null,Object? loading = null,Object? nextCursor = freezed,Object? loadingMore = null,Object? pageError = freezed,Object? error = freezed,Object? query = null,Object? results = freezed,Object? resultsCursor = freezed,Object? resultsQuery = null,Object? resultsTags = null,Object? searching = null,Object? tags = null,Object? selectedTags = null,}) {
  return _then(_ConversationListState(
cached: null == cached ? _self._cached : cached // ignore: cast_nullable_to_non_nullable
as List<Conversation>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,pageError: freezed == pageError ? _self.pageError : pageError ,error: freezed == error ? _self.error : error ,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: freezed == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<Conversation>?,resultsCursor: freezed == resultsCursor ? _self.resultsCursor : resultsCursor // ignore: cast_nullable_to_non_nullable
as String?,resultsQuery: null == resultsQuery ? _self.resultsQuery : resultsQuery // ignore: cast_nullable_to_non_nullable
as String,resultsTags: null == resultsTags ? _self._resultsTags : resultsTags // ignore: cast_nullable_to_non_nullable
as List<String>,searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<Tag>,selectedTags: null == selectedTags ? _self._selectedTags : selectedTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
