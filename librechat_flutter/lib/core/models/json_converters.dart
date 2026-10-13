import 'package:json_annotation/json_annotation.dart';

/// Reads a text field that is a string or, for a part edited through `PUT /api/messages`, the
/// `{value, annotations}` object form (KMP `FlexibleTextSerializer`). It always writes a string.
class FlexibleTextConverter implements JsonConverter<String?, Object?> {
  const FlexibleTextConverter();

  @override
  String? fromJson(Object? json) {
    final value = json is Map ? json['value'] : json;
    return value == null || value is Map || value is List ? null : '$value';
  }

  @override
  Object? toJson(String? text) => text;
}

/// Decodes an ISO-8601 timestamp to a UTC [DateTime]. An unparseable value decodes to null
/// instead of failing the whole payload (KMP `LenientInstantSerializer`).
class UtcDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const UtcDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) =>
      json is String ? DateTime.tryParse(json)?.toUtc() : null;

  @override
  Object? toJson(DateTime? time) => time?.toUtc().toIso8601String();
}
