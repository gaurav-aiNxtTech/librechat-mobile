// parseDeepLink valid and malformed cases (Task 33.4).
import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/features/integrations/deep_link.dart';

DeepLinkTarget parse(String link) => parseDeepLink(Uri.parse(link));

void main() {
  group('valid', () {
    test('a conversation', () {
      expect(
        parse('librechat://conversation/abc'),
        const ConversationLink('abc'),
      );
    });

    test('scheme and host in any case, with a trailing slash', () {
      expect(
        parse('LIBRECHAT://Conversation/abc/'),
        const ConversationLink('abc'),
      );
    });

    test('a percent-encoded id is decoded', () {
      expect(
        parse('librechat://conversation/a%2Fb'),
        const ConversationLink('a/b'),
      );
    });

    test('a model', () {
      expect(
        parse('librechat://model?endpoint=openAI&model=gpt-4o'),
        const ModelLink('openAI', 'gpt-4o'),
      );
    });

    test('a model with an encoded value', () {
      expect(
        parse('librechat://model?endpoint=openAI&model=gpt%2D4o'),
        const ModelLink('openAI', 'gpt-4o'),
      );
    });

    test('an OAuth return, with or without a query', () {
      expect(parse('librechat://oauth'), const OAuthReturn());
      expect(parse('librechat://oauth?code=1'), const OAuthReturn());
    });
  });

  group('malformed links are InvalidLink', () {
    for (final link in [
      'https://conversation/abc',
      'librechat://conversation',
      'librechat://conversation/',
      'librechat://conversation/a/b',
      'librechat://conversation/%20',
      'librechat:conversation/abc',
      'librechat:///abc',
      'librechat://model?endpoint=openAI',
      'librechat://model?model=gpt-4o',
      'librechat://model?endpoint=%20&model=x',
      'librechat://artifact/abc',
      'librechat://unknown',
    ]) {
      test(link, () => expect(parse(link), const InvalidLink()));
    }
  });
}
