// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_permissions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RolePermissions _$RolePermissionsFromJson(Map<String, dynamic> json) =>
    _RolePermissions(
      name: json['name'] as String,
      permissions: (json['permissions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, Map<String, bool>.from(e as Map)),
      ),
    );

Map<String, dynamic> _$RolePermissionsToJson(_RolePermissions instance) =>
    <String, dynamic>{
      'name': instance.name,
      'permissions': ?instance.permissions,
    };
