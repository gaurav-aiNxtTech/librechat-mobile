import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// `GET /api/user` and the login response's `user`.
@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(name: '_id', readValue: _readId) required String id,
    String? name,
    String? username,
    String? email,
    String? avatar,
    String? role,
    String? provider,
    @Default(false) bool twoFactorEnabled,
    @Default(false) bool termsAccepted,
    UserPersonalization? personalization,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}

/// The Server sends `_id`, and most user routes also send it as `id`.
Object? _readId(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['id'];

@freezed
abstract class UserPersonalization with _$UserPersonalization {
  const factory UserPersonalization({bool? memories}) = _UserPersonalization;

  factory UserPersonalization.fromJson(Map<String, Object?> json) =>
      _$UserPersonalizationFromJson(json);
}
