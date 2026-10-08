/// Where a `librechat://` link points (Req 44.2–44.6).
sealed class DeepLinkTarget {
  const DeepLinkTarget();
}

/// `librechat://conversation/{id}`.
final class ConversationLink extends DeepLinkTarget {
  const ConversationLink(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is ConversationLink && other.id == id;

  @override
  int get hashCode => Object.hash(ConversationLink, id);

  @override
  String toString() => 'ConversationLink($id)';
}

/// `librechat://model?endpoint=…&model=…`.
final class ModelLink extends DeepLinkTarget {
  const ModelLink(this.endpoint, this.model);

  final String endpoint;
  final String model;

  @override
  bool operator ==(Object other) =>
      other is ModelLink && other.endpoint == endpoint && other.model == model;

  @override
  int get hashCode => Object.hash(ModelLink, endpoint, model);

  @override
  String toString() => 'ModelLink($endpoint, $model)';
}

/// `librechat://oauth`: the return from a browser sign-in.
final class OAuthReturn extends DeepLinkTarget {
  const OAuthReturn();

  @override
  bool operator ==(Object other) => other is OAuthReturn;

  @override
  int get hashCode => (OAuthReturn).hashCode;

  @override
  String toString() => 'OAuthReturn()';
}

/// Any link the App doesn't handle.
final class InvalidLink extends DeepLinkTarget {
  const InvalidLink();

  @override
  bool operator ==(Object other) => other is InvalidLink;

  @override
  int get hashCode => (InvalidLink).hashCode;

  @override
  String toString() => 'InvalidLink()';
}

/// Resolves [uri] to its target, ported from the KMP `DeepLinks.resolve`
/// (`shared/.../navigation/DeepLinks.kt`) with the design's rules.
///
/// - `librechat://conversation/{id}`: exactly one non-empty path segment,
///   which must not be blank. Any id is accepted, not only UUIDs.
/// - `librechat://model?endpoint=…&model=…`: both values non-blank. The path
///   is ignored.
/// - `librechat://oauth`, whatever its path or query.
///
/// Anything else, including another scheme, an empty host or an unknown
/// host, is [InvalidLink]. Scheme and host compare case-insensitively.
DeepLinkTarget parseDeepLink(Uri uri) {
  if (uri.scheme.toLowerCase() != 'librechat') return const InvalidLink();
  switch (uri.host.toLowerCase()) {
    case 'conversation':
      final segments = [
        for (final s in uri.pathSegments)
          if (s.isNotEmpty) s,
      ];
      if (segments.length != 1 || segments.single.trim().isEmpty) {
        return const InvalidLink();
      }
      return ConversationLink(segments.single);
    case 'model':
      final endpoint = uri.queryParameters['endpoint'];
      final model = uri.queryParameters['model'];
      if (endpoint == null ||
          model == null ||
          endpoint.trim().isEmpty ||
          model.trim().isEmpty) {
        return const InvalidLink();
      }
      return ModelLink(endpoint, model);
    case 'oauth':
      return const OAuthReturn();
    default:
      return const InvalidLink();
  }
}
