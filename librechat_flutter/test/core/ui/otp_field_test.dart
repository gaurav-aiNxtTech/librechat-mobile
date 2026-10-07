import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/ui/otp_field.dart';

void main() {
  group('sanitizeOtp', () {
    test('keeps digits only, normalized to ASCII', () {
      expect(sanitizeOtp('', 'Code: 123 456'), '123456');
      expect(sanitizeOtp('', '١٢٣'), '123');
      expect(sanitizeOtp('12', '12x'), '12');
    });

    test('rejects a 7th digit but takes a full code pasted over', () {
      expect(sanitizeOtp('123456', '1234567'), isNull);
      expect(sanitizeOtp('12', '12654321'), '654321');
      expect(sanitizeOtp('12', '1265432'), isNull);
    });
  });

  testWidgets('filters non-digits and fires onCompleted at 6 digits', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final completed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpField(controller: controller, onCompleted: completed.add),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12a3');
    expect(controller.text, '123');
    expect(completed, isEmpty);

    await tester.enterText(find.byType(TextField), '123 4-56');
    expect(controller.text, '123456');
    expect(completed, ['123456']);

    await tester.enterText(find.byType(TextField), '1234567');
    expect(controller.text, '123456');
    expect(completed, ['123456']);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofillHints, [AutofillHints.oneTimeCode]);
  });
}
