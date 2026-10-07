import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The length of a TOTP code.
const otpLength = 6;

/// Maps a raw edit of the OTP field to the text to accept, or null to keep
/// [old], after KMP `sanitizeOtpInput`.
///
/// Decimal digits from common non-Latin keypads become ASCII and everything
/// else is dropped, so a pasted `"Code: 123 456"` lands as `123456`. An edit
/// past [length] is rejected, unless the text appended to [old] is itself one
/// full code, which replaces the entry. Truncating instead would submit a
/// guess and spend a rate-limited attempt.
String? sanitizeOtp(String old, String next, {int length = otpLength}) {
  final digits = _asciiDigits(next);
  if (digits.length <= length) return digits;
  if (!next.startsWith(old)) return null;
  final appended = _asciiDigits(next.substring(old.length));
  return appended.length == length ? appended : null;
}

// The zero of each Unicode digit block a phone keypad may type: ASCII,
// Arabic-Indic, Extended Arabic-Indic, Devanagari, Bengali and fullwidth.
const _digitZeros = [0x30, 0x660, 0x6F0, 0x966, 0x9E6, 0xFF10];

String _asciiDigits(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    for (final zero in _digitZeros) {
      if (rune >= zero && rune < zero + 10) {
        out.writeCharCode(0x30 + rune - zero);
        break;
      }
    }
  }
  return out.toString();
}

class _OtpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final accepted = sanitizeOtp(oldValue.text, newValue.text);
    if (accepted == null) return oldValue;
    if (accepted == newValue.text) return newValue;
    return TextEditingValue(
      text: accepted,
      selection: TextSelection.collapsed(offset: accepted.length),
    );
  }
}

/// A 6-digit code field: one [TextField], so the whole code pastes in one
/// action and SMS or password-manager autofill can fill it.
///
/// [onCompleted] fires each time the text becomes a full code. Callers must
/// still guard against a second submit while one is running.
class OtpField extends StatelessWidget {
  const OtpField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.label = 'Verification code', // New copy: the KMP field has no label.
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: (value) {
        onChanged?.call(value);
        if (value.length == otpLength) onCompleted?.call(value);
      },
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [_OtpFormatter()],
      autocorrect: false,
      enableSuggestions: false,
      textAlign: TextAlign.center,
      // Codes read left to right in every locale.
      textDirection: TextDirection.ltr,
      style: theme.textTheme.headlineSmall?.copyWith(
        letterSpacing: 12,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
