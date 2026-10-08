import 'package:freezed_annotation/freezed_annotation.dart';

import 'json_converters.dart';

part 'banner.freezed.dart';
part 'banner.g.dart';

/// `GET /api/banner`: the Server's current banner (Req 14.4–14.6). The
/// Server answers one object, or an empty body when there is no banner.
/// Named `ServerBanner` so it does not collide with Flutter's `Banner`
/// widget.
@freezed
abstract class ServerBanner with _$ServerBanner {
  const factory ServerBanner({
    String? bannerId,
    String? message,
    String? type,
    bool? persistable,
    @UtcDateTimeConverter() DateTime? displayFrom,
    @UtcDateTimeConverter() DateTime? displayTo,
  }) = _ServerBanner;

  factory ServerBanner.fromJson(Map<String, Object?> json) =>
      _$ServerBannerFromJson(json);
}
