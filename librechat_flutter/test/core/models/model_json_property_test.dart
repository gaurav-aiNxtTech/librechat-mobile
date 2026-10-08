import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';

import '../../support/property.dart';

// Generators for Property 1. The Message, Conversation and Attachment
// generators live in `test/support/property.dart` (Model generators),
// shared with Property 6; the config generators below are Property 1's own.

/// An InterfaceConfig union: `true`, `false` or an object.
final Gen<Object?> unionGen = opt(
  oneOf<Object>([constant(true), constant(false), rawMapGen]),
);

final Gen<TermsOfServiceConfig> termsGen = Gen(
  (r) => TermsOfServiceConfig(
    modalAcceptance: opt(boolean)(r),
    modalTitle: opt(textGen)(r),
    modalContent: opt(oneOf<Object?>([textGen, stringListGen]))(r),
  ),
);

final Gen<InterfaceConfig> interfaceConfigGen = Gen(
  (r) => InterfaceConfig(
    customWelcome: opt(textGen)(r),
    termsOfService: opt(termsGen)(r),
    endpointsMenu: boolean(r),
    modelSelect: boolean(r),
    parameters: boolean(r),
    presets: boolean(r),
    bookmarks: boolean(r),
    multiConvo: boolean(r),
    temporaryChat: boolean(r),
    runCode: boolean(r),
    webSearch: boolean(r),
    fileSearch: boolean(r),
    fileCitations: boolean(r),
    memories: boolean(r),
    contextUsage: boolean(r),
    feedback: boolean(r),
    prompts: unionGen(r),
    agents: unionGen(r),
    remoteAgents: unionGen(r),
    skills: unionGen(r),
    sharedLinks: unionGen(r),
    schedules: unionGen(r),
    traceViewer: unionGen(r),
    mcpServers: unionGen(r),
    marketplace: unionGen(r),
  ),
);

final Gen<StartupConfig> startupConfigGen = Gen(
  (r) => StartupConfig(
    appTitle: textGen(r),
    emailLoginEnabled: boolean(r),
    registrationEnabled: boolean(r),
    passwordResetEnabled: boolean(r),
    socialLogins: opt(stringListGen)(r),
    googleLoginEnabled: boolean(r),
    githubLoginEnabled: boolean(r),
    discordLoginEnabled: boolean(r),
    facebookLoginEnabled: boolean(r),
    appleLoginEnabled: boolean(r),
    openidLoginEnabled: boolean(r),
    openidLabel: opt(textGen)(r),
    openidImageUrl: opt(textGen)(r),
    openidAutoRedirect: boolean(r),
    samlLoginEnabled: boolean(r),
    samlLabel: opt(textGen)(r),
    samlImageUrl: opt(textGen)(r),
    ldap: opt(
      zip2(
        boolean,
        boolean,
      ).map((b) => LdapConfig(enabled: b.$1, username: b.$2)),
    )(r),
    minPasswordLength: opt(intGen)(r),
    sharedLinksEnabled: boolean(r),
    helpAndFaqURL: opt(textGen)(r),
    allowAccountDeletion: boolean(r),
    balance: opt(boolean.map((b) => BalanceConfig(enabled: b)))(r),
    conversationImportMaxFileSize: opt(intGen)(r),
    modelSpecs: opt(rawMapGen)(r),
    version: opt(idGen)(r),
    buildInfo: opt(opt(idGen).map((c) => BuildInfo(commit: c)))(r),
    compactionEnabled: opt(boolean)(r),
    interfaceConfig: interfaceConfigGen(r),
  ),
);

/// The model decoded from the `jsonEncode`d output of its `toJson()`.
T _wireRoundTrip<T>(
  Map<String, Object?> json,
  T Function(Map<String, Object?> json) fromJson,
) => fromJson(jsonDecode(jsonEncode(json)) as Map<String, Object?>);

void main() {
  // Feature: flutter-android-rewrite, Property 1: For any generated Message
  // (with ContentParts), Conversation, Attachment or StartupConfig value,
  // decoding the jsonEncoded output of its toJson() produces an equal value.
  // Validates: Requirements 4.8
  test('Property 1: Model JSON round trip', () async {
    await forAll(
      Gen(
        (r) => (
          message: messageGen(r),
          conversation: conversationGen(r),
          attachment: attachmentGen(r),
          startupConfig: startupConfigGen(r),
        ),
      ),
      (c) {
        expect(
          _wireRoundTrip(c.message.toJson(), Message.fromJson),
          c.message,
          reason: 'Message round trip',
        );
        expect(
          _wireRoundTrip(c.conversation.toJson(), Conversation.fromJson),
          c.conversation,
          reason: 'Conversation round trip',
        );
        expect(
          _wireRoundTrip(c.attachment.toJson(), Attachment.fromJson),
          c.attachment,
          reason: 'Attachment round trip',
        );
        expect(
          _wireRoundTrip(c.startupConfig.toJson(), StartupConfig.fromJson),
          c.startupConfig,
          reason: 'StartupConfig round trip',
        );
      },
      runs: 200,
    );
  });
}
