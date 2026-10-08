import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_config.freezed.dart';
part 'file_config.g.dart';

/// `GET /api/files/config`: upload limits per endpoint, with `default` for
/// endpoints that have no entry (Req 26.2). Sizes are bytes.
@freezed
abstract class FileConfig with _$FileConfig {
  const factory FileConfig({
    @Default(<String, EndpointFileConfig>{})
    Map<String, EndpointFileConfig> endpoints,
    int? serverFileSizeLimit,
  }) = _FileConfig;

  factory FileConfig.fromJson(Map<String, Object?> json) =>
      _$FileConfigFromJson(json);
}

/// One endpoint's upload limits. A null limit does not restrict, and
/// `supportedMimeTypes` holds regex sources.
@freezed
abstract class EndpointFileConfig with _$EndpointFileConfig {
  const factory EndpointFileConfig({
    int? fileLimit,
    int? fileSizeLimit,
    int? totalSizeLimit,
    @Default(<String>[]) List<String> supportedMimeTypes,
    @Default(false) bool disabled,
  }) = _EndpointFileConfig;

  factory EndpointFileConfig.fromJson(Map<String, Object?> json) =>
      _$EndpointFileConfigFromJson(json);
}
