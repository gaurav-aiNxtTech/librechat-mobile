/// The Prompt_Variable_Parser (Req 27.5–27.9), ported from the KMP
/// `feature/chat/.../prompts/PromptInsertion.kt`.
///
/// A placeholder is `{{name}}`, where the name holds no brace and is trimmed,
/// so spaces, `-` and `.` are allowed as on the web client.
library;

final _placeholder = RegExp(r'\{\{([^{}]+?)\}\}');

/// Names the Server fills per request. They are never fillable and stay in
/// the text (Req 27.8).
const _serverFilled = {
  'current_date',
  'current_user',
  'iso_datetime',
  'current_datetime',
};

bool _isServerFilled(String name) =>
    _serverFilled.contains(name.trim().toLowerCase());

/// The fillable variable names in [template], trimmed, in first-appearance
/// order. Names repeat case-insensitively only once, keeping the first
/// spelling, because [fillVariables] matches them case-insensitively.
List<String> extractVariables(String template) {
  final seen = <String>{};
  final names = <String>[];
  for (final match in _placeholder.allMatches(template)) {
    final name = match[1]!.trim();
    if (name.isEmpty || _isServerFilled(name)) continue;
    if (seen.add(name.toLowerCase())) names.add(name);
  }
  return names;
}

/// Replaces each fillable placeholder in [template] whose trimmed name
/// matches a key of [values] case-insensitively (keys trimmed too) with a
/// non-blank value, inserted as literal text. A missing or blank value
/// leaves the placeholder, and so does a Server-filled name (Req 27.9).
String fillVariables(String template, Map<String, String> values) {
  final lookup = <String, String>{
    for (final MapEntry(:key, :value) in values.entries)
      if (value.trim().isNotEmpty) key.trim().toLowerCase(): value,
  };
  if (lookup.isEmpty) return template;
  return template.replaceAllMapped(_placeholder, (match) {
    final name = match[1]!.trim();
    if (name.isEmpty || _isServerFilled(name)) return match[0]!;
    return lookup[name.toLowerCase()] ?? match[0]!;
  });
}
