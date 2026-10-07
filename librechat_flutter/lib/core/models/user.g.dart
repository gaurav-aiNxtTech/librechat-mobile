// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: _readId(json, '_id') as String,
  name: json['name'] as String?,
  username: json['username'] as String?,
  email: json['email'] as String?,
  avatar: json['avatar'] as String?,
  role: json['role'] as String?,
  provider: json['provider'] as String?,
  twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
  termsAccepted: json['termsAccepted'] as bool? ?? false,
  personalization: json['personalization'] == null
      ? null
      : UserPersonalization.fromJson(
          json['personalization'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  '_id': instance.id,
  'name': ?instance.name,
  'username': ?instance.username,
  'email': ?instance.email,
  'avatar': ?instance.avatar,
  'role': ?instance.role,
  'provider': ?instance.provider,
  'twoFactorEnabled': instance.twoFactorEnabled,
  'termsAccepted': instance.termsAccepted,
  'personalization': ?instance.personalization?.toJson(),
};

_UserPersonalization _$UserPersonalizationFromJson(Map<String, dynamic> json) =>
    _UserPersonalization(memories: json['memories'] as bool?);

Map<String, dynamic> _$UserPersonalizationToJson(
  _UserPersonalization instance,
) => <String, dynamic>{'memories': ?instance.memories};
