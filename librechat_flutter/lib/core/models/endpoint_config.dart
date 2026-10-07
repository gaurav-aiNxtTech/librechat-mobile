import 'package:freezed_annotation/freezed_annotation.dart';

part 'endpoint_config.freezed.dart';
part 'endpoint_config.g.dart';

/// One value of the `GET /api/endpoints` map, keyed by endpoint name.
@freezed
abstract class EndpointConfig with _$EndpointConfig {
  const factory EndpointConfig({
    String? type,
    int? order,
    String? iconURL,
    String? modelDisplayLabel,
    bool? userProvide,
    bool? userProvideURL,
    List<String>? capabilities,
  }) = _EndpointConfig;

  factory EndpointConfig.fromJson(Map<String, Object?> json) => _$EndpointConfigFromJson(json);
}
