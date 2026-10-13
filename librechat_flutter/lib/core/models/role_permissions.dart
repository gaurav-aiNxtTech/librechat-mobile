import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_permissions.freezed.dart';
part 'role_permissions.g.dart';

/// `GET /api/roles/{role}`. `permissions` maps a type to its bits, such as `AGENTS` → `CREATE`.
@freezed
abstract class RolePermissions with _$RolePermissions {
  const factory RolePermissions({
    required String name,
    Map<String, Map<String, bool>>? permissions,
  }) = _RolePermissions;

  factory RolePermissions.fromJson(Map<String, Object?> json) =>
      _$RolePermissionsFromJson(json);
}
