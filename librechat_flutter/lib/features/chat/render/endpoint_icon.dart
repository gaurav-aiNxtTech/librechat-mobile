import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/images/app_image.dart';

/// The bundled brand icon of [endpoint] under `assets/icons/providers/`, or
/// null for a custom endpoint (KMP EndpointIcons.kt `endpointIconPainter`).
String? endpointIconAsset(String? endpoint) {
  final name = switch (endpoint) {
    'openAI' || 'assistants' => 'openai',
    'azureOpenAI' || 'azureAssistants' => 'azure',
    'google' => 'google',
    'anthropic' => 'anthropic',
    'bedrock' => 'bedrock',
    'agents' => 'agents',
    _ => null,
  };
  return name == null ? null : 'assets/icons/providers/$name.svg';
}

/// Whether [endpoint]'s bundled icon is a monochrome glyph tinted with the
/// theme (KMP `isMonochromeEndpointIcon`); brand-colored ones keep their
/// colors.
bool isMonochromeEndpointIcon(String? endpoint) =>
    endpoint == 'openAI' || endpoint == 'assistants' || endpoint == 'agents';

/// A small decorative icon for an endpoint, agent or model spec: [url]
/// through [AppImage], else [endpoint]'s bundled glyph, else [fallback].
class EndpointIcon extends StatelessWidget {
  const EndpointIcon({
    super.key,
    this.endpoint,
    this.url,
    this.size = 20,
    this.fallback = Icons.smart_toy_outlined,
  });

  final String? endpoint;
  final String? url;
  final double size;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asset = endpointIconAsset(endpoint);
    final glyph = asset == null
        ? Icon(fallback, size: size, color: colors.onSurfaceVariant)
        : SvgPicture.asset(
            asset,
            width: size,
            height: size,
            colorFilter: isMonochromeEndpointIcon(endpoint)
                ? ColorFilter.mode(colors.onSurface, BlendMode.srcIn)
                : null,
          );
    final image = url;
    return ExcludeSemantics(
      child: image == null
          ? glyph
          : ClipOval(
              child: AppImage(
                image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                error: glyph,
              ),
            ),
    );
  }
}
