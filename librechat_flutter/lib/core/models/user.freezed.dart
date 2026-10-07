// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

@JsonKey(name: '_id', readValue: _readId) String get id; String? get name; String? get username; String? get email; String? get avatar; String? get role; String? get provider; bool get twoFactorEnabled; bool get termsAccepted; UserPersonalization? get personalization;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.role, role) || other.role == role)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.twoFactorEnabled, twoFactorEnabled) || other.twoFactorEnabled == twoFactorEnabled)&&(identical(other.termsAccepted, termsAccepted) || other.termsAccepted == termsAccepted)&&(identical(other.personalization, personalization) || other.personalization == personalization));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,avatar,role,provider,twoFactorEnabled,termsAccepted,personalization);

@override
String toString() {
  return 'User(id: $id, name: $name, username: $username, email: $email, avatar: $avatar, role: $role, provider: $provider, twoFactorEnabled: $twoFactorEnabled, termsAccepted: $termsAccepted, personalization: $personalization)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id', readValue: _readId) String id, String? name, String? username, String? email, String? avatar, String? role, String? provider, bool twoFactorEnabled, bool termsAccepted, UserPersonalization? personalization
});


$UserPersonalizationCopyWith<$Res>? get personalization;

}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? username = freezed,Object? email = freezed,Object? avatar = freezed,Object? role = freezed,Object? provider = freezed,Object? twoFactorEnabled = null,Object? termsAccepted = null,Object? personalization = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,twoFactorEnabled: null == twoFactorEnabled ? _self.twoFactorEnabled : twoFactorEnabled // ignore: cast_nullable_to_non_nullable
as bool,termsAccepted: null == termsAccepted ? _self.termsAccepted : termsAccepted // ignore: cast_nullable_to_non_nullable
as bool,personalization: freezed == personalization ? _self.personalization : personalization // ignore: cast_nullable_to_non_nullable
as UserPersonalization?,
  ));
}
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserPersonalizationCopyWith<$Res>? get personalization {
    if (_self.personalization == null) {
    return null;
  }

  return $UserPersonalizationCopyWith<$Res>(_self.personalization!, (value) {
    return _then(_self.copyWith(personalization: value));
  });
}
}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id', readValue: _readId)  String id,  String? name,  String? username,  String? email,  String? avatar,  String? role,  String? provider,  bool twoFactorEnabled,  bool termsAccepted,  UserPersonalization? personalization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar,_that.role,_that.provider,_that.twoFactorEnabled,_that.termsAccepted,_that.personalization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id', readValue: _readId)  String id,  String? name,  String? username,  String? email,  String? avatar,  String? role,  String? provider,  bool twoFactorEnabled,  bool termsAccepted,  UserPersonalization? personalization)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar,_that.role,_that.provider,_that.twoFactorEnabled,_that.termsAccepted,_that.personalization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id', readValue: _readId)  String id,  String? name,  String? username,  String? email,  String? avatar,  String? role,  String? provider,  bool twoFactorEnabled,  bool termsAccepted,  UserPersonalization? personalization)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.avatar,_that.role,_that.provider,_that.twoFactorEnabled,_that.termsAccepted,_that.personalization);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({@JsonKey(name: '_id', readValue: _readId) required this.id, this.name, this.username, this.email, this.avatar, this.role, this.provider, this.twoFactorEnabled = false, this.termsAccepted = false, this.personalization});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override@JsonKey(name: '_id', readValue: _readId) final  String id;
@override final  String? name;
@override final  String? username;
@override final  String? email;
@override final  String? avatar;
@override final  String? role;
@override final  String? provider;
@override@JsonKey() final  bool twoFactorEnabled;
@override@JsonKey() final  bool termsAccepted;
@override final  UserPersonalization? personalization;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.role, role) || other.role == role)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.twoFactorEnabled, twoFactorEnabled) || other.twoFactorEnabled == twoFactorEnabled)&&(identical(other.termsAccepted, termsAccepted) || other.termsAccepted == termsAccepted)&&(identical(other.personalization, personalization) || other.personalization == personalization));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,avatar,role,provider,twoFactorEnabled,termsAccepted,personalization);

@override
String toString() {
  return 'User(id: $id, name: $name, username: $username, email: $email, avatar: $avatar, role: $role, provider: $provider, twoFactorEnabled: $twoFactorEnabled, termsAccepted: $termsAccepted, personalization: $personalization)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id', readValue: _readId) String id, String? name, String? username, String? email, String? avatar, String? role, String? provider, bool twoFactorEnabled, bool termsAccepted, UserPersonalization? personalization
});


@override $UserPersonalizationCopyWith<$Res>? get personalization;

}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? username = freezed,Object? email = freezed,Object? avatar = freezed,Object? role = freezed,Object? provider = freezed,Object? twoFactorEnabled = null,Object? termsAccepted = null,Object? personalization = freezed,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,provider: freezed == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String?,twoFactorEnabled: null == twoFactorEnabled ? _self.twoFactorEnabled : twoFactorEnabled // ignore: cast_nullable_to_non_nullable
as bool,termsAccepted: null == termsAccepted ? _self.termsAccepted : termsAccepted // ignore: cast_nullable_to_non_nullable
as bool,personalization: freezed == personalization ? _self.personalization : personalization // ignore: cast_nullable_to_non_nullable
as UserPersonalization?,
  ));
}

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserPersonalizationCopyWith<$Res>? get personalization {
    if (_self.personalization == null) {
    return null;
  }

  return $UserPersonalizationCopyWith<$Res>(_self.personalization!, (value) {
    return _then(_self.copyWith(personalization: value));
  });
}
}


/// @nodoc
mixin _$UserPersonalization {

 bool? get memories;
/// Create a copy of UserPersonalization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPersonalizationCopyWith<UserPersonalization> get copyWith => _$UserPersonalizationCopyWithImpl<UserPersonalization>(this as UserPersonalization, _$identity);

  /// Serializes this UserPersonalization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPersonalization&&(identical(other.memories, memories) || other.memories == memories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memories);

@override
String toString() {
  return 'UserPersonalization(memories: $memories)';
}


}

/// @nodoc
abstract mixin class $UserPersonalizationCopyWith<$Res>  {
  factory $UserPersonalizationCopyWith(UserPersonalization value, $Res Function(UserPersonalization) _then) = _$UserPersonalizationCopyWithImpl;
@useResult
$Res call({
 bool? memories
});




}
/// @nodoc
class _$UserPersonalizationCopyWithImpl<$Res>
    implements $UserPersonalizationCopyWith<$Res> {
  _$UserPersonalizationCopyWithImpl(this._self, this._then);

  final UserPersonalization _self;
  final $Res Function(UserPersonalization) _then;

/// Create a copy of UserPersonalization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memories = freezed,}) {
  return _then(_self.copyWith(
memories: freezed == memories ? _self.memories : memories // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPersonalization].
extension UserPersonalizationPatterns on UserPersonalization {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPersonalization value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPersonalization() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPersonalization value)  $default,){
final _that = this;
switch (_that) {
case _UserPersonalization():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPersonalization value)?  $default,){
final _that = this;
switch (_that) {
case _UserPersonalization() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? memories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPersonalization() when $default != null:
return $default(_that.memories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? memories)  $default,) {final _that = this;
switch (_that) {
case _UserPersonalization():
return $default(_that.memories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? memories)?  $default,) {final _that = this;
switch (_that) {
case _UserPersonalization() when $default != null:
return $default(_that.memories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPersonalization implements UserPersonalization {
  const _UserPersonalization({this.memories});
  factory _UserPersonalization.fromJson(Map<String, dynamic> json) => _$UserPersonalizationFromJson(json);

@override final  bool? memories;

/// Create a copy of UserPersonalization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPersonalizationCopyWith<_UserPersonalization> get copyWith => __$UserPersonalizationCopyWithImpl<_UserPersonalization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPersonalizationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPersonalization&&(identical(other.memories, memories) || other.memories == memories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memories);

@override
String toString() {
  return 'UserPersonalization(memories: $memories)';
}


}

/// @nodoc
abstract mixin class _$UserPersonalizationCopyWith<$Res> implements $UserPersonalizationCopyWith<$Res> {
  factory _$UserPersonalizationCopyWith(_UserPersonalization value, $Res Function(_UserPersonalization) _then) = __$UserPersonalizationCopyWithImpl;
@override @useResult
$Res call({
 bool? memories
});




}
/// @nodoc
class __$UserPersonalizationCopyWithImpl<$Res>
    implements _$UserPersonalizationCopyWith<$Res> {
  __$UserPersonalizationCopyWithImpl(this._self, this._then);

  final _UserPersonalization _self;
  final $Res Function(_UserPersonalization) _then;

/// Create a copy of UserPersonalization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memories = freezed,}) {
  return _then(_UserPersonalization(
memories: freezed == memories ? _self.memories : memories // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
