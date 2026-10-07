import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:librechat_flutter/core/models/attachment.dart';
import 'package:librechat_flutter/core/models/content_part.dart';
import 'package:librechat_flutter/core/models/conversation.dart';
import 'package:librechat_flutter/core/models/interface_config.dart';
import 'package:librechat_flutter/core/models/message.dart';
import 'package:librechat_flutter/core/models/startup_config.dart';

import '../../support/property.dart';

// Generators for Property 1. Property 6 (conversation export) reuses the
// Conversation and Message generators, so they are public and ready to move
// into `test/support/property.dart`.
//
// What the generators leave out on purpose, because the wire normalizes it:
// - ContentPart `text` is always a plain string. FlexibleTextConverter reads
//   the `{value, annotations}` object form but always writes a string, so an
//   object can't come back as itself (models_test.dart covers that read).
// - Every DateTime is UTC. UtcDateTimeConverter decodes to UTC, so a local
//   time would come back as the same instant with `isUtc` flipped, which
//   DateTime `==` treats as different.
// - FeedbackRating.unknown is the decode fallback for a rating the App
//   doesn't know, not a value it sends, so it is never generated.
// - Doubles are finite: jsonEncode rejects NaN and the infinities.
// - Typed `double?` fields only get doubles and typed `int?` fields only get
//   ints. Inside `Object?` and raw maps and lists, ints stay ints and doubles
//   stay doubles, because the VM's jsonEncode writes a double with a `.` or an
//   exponent, so jsonDecode reads it back as a double.

/// Short identifier-like strings, never empty.
final Gen<String> idGen = stringOf('$alphanumeric-_', min: 1, max: 24);

/// Unicode text: plain words, printable ASCII, whitespace, quotes, escapes,
/// non-Latin letters, an emoji outside the BMP and a zero-width joiner.
final Gen<String> textGen = frequency([
  (2, stringOf('$alphanumeric ', max: 16)),
  (3, stringOf('$asciiPrintable$tricky', max: 24)),
  (1, constant('')),
]);

/// Ints across the range a JSON number carries exactly in JavaScript too.
final Gen<int> intGen = oneOf([
  intRange(-1000, 1000),
  intRange(0, 1 << 31),
  intRange(-(1 << 53), 1 << 53),
]);

/// A finite double from a random bit pattern, subnormals included.
final Gen<double> _bitsDouble = Gen((r) {
  final bytes = ByteData(8)
    ..setUint32(0, r.nextInt(1 << 32))
    ..setUint32(4, r.nextInt(1 << 32));
  return bytes.getFloat64(0);
}).where((d) => d.isFinite);

/// Finite doubles: fractions, integral values, edge values and random bits.
final Gen<double> doubleGen = oneOf([
  Gen((r) => r.nextDouble()),
  Gen((r) => (r.nextDouble() - 0.5) * 4000),
  intRange(-1000, 1000).map((n) => n.toDouble()),
  elementOf(const [
    0.0,
    -0.0,
    0.1,
    1e21,
    1e-7,
    double.minPositive,
    double.maxFinite,
    -double.maxFinite,
  ]),
  _bitsDouble,
]);

/// A UTC time at millisecond precision, from year 1 to year 9999.
final Gen<DateTime> utcTimeGen = intRange(
  DateTime.utc(1).millisecondsSinceEpoch,
  DateTime.utc(9999, 12, 31, 23, 59, 59, 999).millisecondsSinceEpoch,
).map((ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));

/// A JSON scalar: null, a bool, an int, a double or a string.
final Gen<Object?> jsonScalarGen = oneOf<Object?>([
  constant(null),
  boolean,
  intGen,
  doubleGen,
  textGen,
]);

/// A raw JSON value nested up to [depth] levels of lists and maps.
Gen<Object?> jsonValueGen(int depth) => depth <= 0
    ? jsonScalarGen
    : frequency<Object?>([
        (3, jsonScalarGen),
        (1, jsonListGen(depth - 1)),
        (1, jsonMapGen(depth - 1)),
      ]);

/// A raw JSON list whose items nest up to [depth] more levels.
Gen<List<Object?>> jsonListGen(int depth) =>
    listOf(jsonValueGen(depth), max: 4);

/// A raw JSON object whose values nest up to [depth] more levels.
Gen<Map<String, Object?>> jsonMapGen(int depth) => listOf(
  zip2(textGen, jsonValueGen(depth)),
  max: 4,
).map((entries) => {for (final (key, value) in entries) key: value});

/// Raw pass-through fields: objects and values nested up to 3 deep.
final Gen<Map<String, Object?>> rawMapGen = jsonMapGen(2);
final Gen<Object?> rawValueGen = jsonValueGen(3);

final Gen<List<String>> stringListGen = listOf(textGen, max: 4);

/// Each optional field is null about half the time.
Gen<T?> opt<T>(Gen<T> gen) => nullable(gen, oneIn: 2);

/// Every known ContentPart type, plus unknown ones that must still decode.
final Gen<String> partTypeGen = frequency([
  (
    6,
    elementOf(const [
      ContentPartType.text,
      ContentPartType.textDelta,
      ContentPartType.think,
      ContentPartType.toolCall,
      ContentPartType.imageUrl,
      ContentPartType.imageFile,
      ContentPartType.videoUrl,
      ContentPartType.inputAudio,
      ContentPartType.error,
      ContentPartType.agentUpdate,
      ContentPartType.summary,
      ContentPartType.steer,
      ContentPartType.activityLabel,
    ]),
  ),
  (1, stringOf('${lowercase}_', min: 1, max: 14)),
]);

/// `args` is a map mid-stream, a JSON string once saved, or anything else.
final Gen<Object?> toolArgsGen = oneOf<Object?>([
  rawMapGen,
  rawMapGen.map(jsonEncode),
  rawValueGen,
]);

final Gen<ToolCall> toolCallGen = Gen(
  (r) => ToolCall(
    id: opt(idGen)(r),
    name: opt(idGen)(r),
    type: opt(elementOf(const ['tool_call', 'function', 'code_interpreter']))(
      r,
    ),
    args: opt(toolArgsGen)(r),
    output: opt(textGen)(r),
    progress: opt(doubleGen)(r),
  ),
);

/// A part of any type with every optional field independently set or null.
/// A `tool_call` part always carries its tool call.
final Gen<ContentPart> contentPartGen = Gen((r) {
  final type = partTypeGen(r);
  return ContentPart(
    type: type,
    text: opt(textGen)(r),
    think: opt(textGen)(r),
    toolCallIds: opt(listOf(idGen, max: 3))(r),
    toolCall: type == ContentPartType.toolCall
        ? toolCallGen(r)
        : opt(toolCallGen)(r),
    imageUrl: opt(oneOf<Object?>([textGen, rawMapGen]))(r),
    imageFile: opt(rawMapGen)(r),
    videoUrl: opt(oneOf<Object?>([textGen, rawMapGen]))(r),
    inputAudio: opt(rawMapGen)(r),
    error: opt(textGen)(r),
    agentUpdate: opt(rawMapGen)(r),
    steer: opt(rawMapGen)(r),
    activityLabel: opt(textGen)(r),
    activityLabelType: opt(idGen)(r),
    activityEndIndex: opt(intGen)(r),
    status: opt(elementOf(const ['failed', 'partial']))(r),
    content: opt(rawValueGen)(r),
    agentId: opt(idGen)(r),
    groupId: opt(intGen)(r),
    stepIndex: opt(intGen)(r),
  );
});

final Gen<Attachment> attachmentGen = Gen(
  (r) => Attachment(
    fileId: opt(idGen)(r),
    filename: opt(textGen)(r),
    filepath: opt(textGen)(r),
    type: opt(elementOf(const ['image/png', 'application/pdf', 'text/plain']))(
      r,
    ),
    bytes: opt(intGen)(r),
    width: opt(intGen)(r),
    height: opt(intGen)(r),
    messageId: opt(idGen)(r),
    toolCallId: opt(idGen)(r),
    status: opt(idGen)(r),
    previewError: opt(textGen)(r),
    webSearch: opt(rawMapGen)(r),
    fileSearch: opt(rawMapGen)(r),
    memory: opt(rawMapGen)(r),
  ),
);

final Gen<MessageFeedback> feedbackGen = Gen(
  (r) => MessageFeedback(
    rating: opt(
      elementOf(const [FeedbackRating.thumbsUp, FeedbackRating.thumbsDown]),
    )(r),
    tag: opt(rawValueGen)(r),
    text: opt(textGen)(r),
  ),
);

/// A Message with 0–6 ContentParts.
final Gen<Message> messageGen = Gen(
  (r) => Message(
    messageId: idGen(r),
    conversationId: idGen(r),
    parentMessageId: opt(idGen)(r),
    sender: opt(textGen)(r),
    text: textGen(r),
    isCreatedByUser: boolean(r),
    endpoint: opt(idGen)(r),
    model: opt(idGen)(r),
    error: boolean(r),
    unfinished: boolean(r),
    content: opt(listOf(contentPartGen, max: 6))(r),
    files: opt(listOf(attachmentGen, max: 3))(r),
    attachments: opt(listOf(attachmentGen, max: 3))(r),
    feedback: opt(feedbackGen)(r),
    quotes: opt(stringListGen)(r),
    createdAt: opt(utcTimeGen)(r),
    updatedAt: opt(utcTimeGen)(r),
  ),
);

final Gen<Conversation> conversationGen = Gen(
  (r) => Conversation(
    conversationId: opt(idGen)(r),
    title: opt(textGen)(r),
    endpoint: opt(idGen)(r),
    endpointType: opt(idGen)(r),
    model: opt(idGen)(r),
    agentId: opt(idGen)(r),
    spec: opt(idGen)(r),
    iconURL: opt(textGen)(r),
    tags: opt(stringListGen)(r),
    isArchived: boolean(r),
    pinned: opt(boolean)(r),
    chatProjectId: opt(idGen)(r),
    isTemporary: opt(boolean)(r),
    temperature: opt(doubleGen)(r),
    topP: opt(doubleGen)(r),
    topK: opt(intGen)(r),
    frequencyPenalty: opt(doubleGen)(r),
    presencePenalty: opt(doubleGen)(r),
    maxOutputTokens: opt(intGen)(r),
    maxContextTokens: opt(intGen)(r),
    maxTokens: opt(intGen)(r),
    system: opt(textGen)(r),
    promptPrefix: opt(textGen)(r),
    modelLabel: opt(textGen)(r),
    reasoningEffort: opt(idGen)(r),
    reasoningMode: opt(idGen)(r),
    reasoningContext: opt(idGen)(r),
    effort: opt(idGen)(r),
    thinkingLevel: opt(idGen)(r),
    thinkingDisplay: opt(idGen)(r),
    stop: opt(stringListGen)(r),
    webSearch: opt(boolean)(r),
    urlContext: opt(boolean)(r),
    promptCacheTtl: opt(idGen)(r),
    createdAt: opt(utcTimeGen)(r),
    updatedAt: opt(utcTimeGen)(r),
  ),
);

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
