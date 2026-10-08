import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// `GET /api/tags` items: a Bookmarks tag and how many conversations carry
/// it.
@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    required String tag,
    String? description,
    @Default(0) int count,
    @Default(0) int position,
  }) = _Tag;

  factory Tag.fromJson(Map<String, Object?> json) => _$TagFromJson(json);
}
