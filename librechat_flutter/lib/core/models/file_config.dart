import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_config.freezed.dart';
part 'file_config.g.dart';

/// `GET /api/files/config`: upload limits per endpoint, with `default` for
/// endpoints that have no entry (Req 26.2).
///
/// Sizes are bytes here. The Server serves the administrator's
/// `librechat.yaml` block as it is, where they are megabytes, so
/// `mergeFileConfig` converts them and fills in the Server's built-in
/// defaults before anything reads them.
@freezed
abstract class FileConfig with _$FileConfig {
  const factory FileConfig({
    @Default(<String, EndpointFileConfig>{})
    Map<String, EndpointFileConfig> endpoints,
    int? serverFileSizeLimit,

    /// The types the Server can extract to text, which decides whether a
    /// file may be delivered as text (Req 26.5).
    MimeTypesConfig? text,
  }) = _FileConfig;

  factory FileConfig.fromJson(Map<String, Object?> json) =>
      _$FileConfigFromJson(json);
}

/// A `supportedMimeTypes` list on its own, as `text`, `ocr` and `stt`
/// carry it. The entries are regex sources.
@freezed
abstract class MimeTypesConfig with _$MimeTypesConfig {
  const factory MimeTypesConfig({
    @Default(<String>[]) List<String> supportedMimeTypes,
  }) = _MimeTypesConfig;

  factory MimeTypesConfig.fromJson(Map<String, Object?> json) =>
      _$MimeTypesConfigFromJson(json);
}

/// One endpoint's upload limits. `supportedMimeTypes` holds regex sources.
/// A null field (or an empty pattern list) is unset, so the `default` entry's
/// value applies; `checkAttachments` resolves them field by field.
@freezed
abstract class EndpointFileConfig with _$EndpointFileConfig {
  const factory EndpointFileConfig({
    int? fileLimit,
    int? fileSizeLimit,
    int? totalSizeLimit,
    @Default(<String>[]) List<String> supportedMimeTypes,
    bool? disabled,
  }) = _EndpointFileConfig;

  factory EndpointFileConfig.fromJson(Map<String, Object?> json) =>
      _$EndpointFileConfigFromJson(json);
}
