# Implementation Plan

## Overview

The plan builds the Flutter app in `librechat_flutter/` in 18 phases, in Dart 3.12.2 on Flutter 3.44.4 with Riverpod, go_router, freezed, json_serializable and drift. It runs from the foundation and network core through auth, the shell, conversations and chat, then the feature areas, settings, Android integrations and release, with a checkpoint after each phase.

## Tasks

- [x] 1. Trim the foundation and bootstrap the app
  - [x] 1.1 Trim the pre-spec foundation
    - `pubspec.yaml` keeps only what Task 1 imports, pinned exactly: flutter_riverpod, go_router, freezed_annotation, drift 2.34.4, drift_flutter, shared_preferences, flutter_secure_storage, path_provider, path, dynamic_color; dev: flutter_lints, build_runner, freezed 3.2.5, drift_dev 2.34.0
    - Delete `linux/`, `macos/`, `web/`, `windows/`, `lib/app/router.g.dart`, the placeholder screen and `Routes.splash`; move `lib/core/theme/` to `lib/core/ui/theme/`; `analysis_options.yaml` becomes flutter_lints plus `unawaited_futures` with the generated-file excludes and `invalid_annotation_target: ignore`; `ios/` and the `android/` config stay as they are
    - _Requirements: 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.11, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_
  - [x] 1.2 Create the test support
    - `test/support/property.dart` (`forAll(gen, body, runs: 100, seed:)` seeded from `PROPERTY_SEED`, printing the seed and failing case without shrinking, plus generator combinators), `test/support/fakes.dart` (hand-written `implements` fakes) and `test/support/test_server.dart` (dart:io HttpServer on 127.0.0.1, port 0, scripted responses, recorded requests)
    - Replace `test/widget_test.dart`; `scripts/ci.sh` passes `--dart-define=PROPERTY_SEED=20260101` to `flutter test`
    - _Requirements: 1.4, 1.6_
  - [x] 1.3 Implement DiagnosticLog
    - `lib/core/log/diagnostic_log.dart`: `open()`, `info`, `error`, `file()`, `redact()` on every attribute, ordered appends, rewrite to the newest 768 KB past 1 MB
    - _Requirements: 41.5, 46.3, 46.4_
  - [x] 1.4 Implement SettingsStore and AppSettings
    - `lib/core/storage/settings_store.dart`: freezed `AppSettings` with the design's keys and defaults; `settingsProvider` over `SharedPreferencesWithCache`, defaults for missing or unknown values, `save(next)`
    - _Requirements: 3.2, 3.6, 3.9, 40.4, 40.5_
  - [x] 1.5 Implement SecureStore
    - `lib/core/storage/secure_store.dart`: `server_url`, `custom_headers`, `session`; one `readAll()` in `load()`; memory changes only after a successful write; unreadable storage starts empty and logs `secure_store_unreadable`
    - _Requirements: 1.3, 5.6, 5.10, 46.1_
  - [x] 1.6 Implement CacheDb
    - `lib/core/storage/cache_db.dart`: `conversations`, `messages`, `drafts`, `cache_entries`; `schemaVersion` 1 with `onUpgrade` recreating all but `drafts`; `clearAll()` and `clearServerData()`
    - _Requirements: 12.11, 41.4, 45.1, 45.4_
  - [x] 1.7 Build the theme, bootstrap and router skeleton
    - `lib/core/ui/theme/accent_colors.dart`, `app_theme.dart` with `wallpaperSchemesProvider`, and `lib/app/app.dart` building both themes from `settingsProvider`; `lib/main.dart` runs startup steps 1–4 and `getCorePalette()` before `runApp(ProviderScope(retry: (_, __) => null, …))`
    - `lib/app/router.dart`: plain `Provider<GoRouter>` declaring only `/settings/general`, served by `lib/features/settings/general_settings_screen.dart` (theme modes, presets disabled under dynamic color, "Use wallpaper colors" only with a palette)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 40.2_
  - [ ] 1.8 Unit tests for storage and logging
    - SettingsStore defaults and persistence; failed SecureStore write keeps the old value; CacheDb on `NativeDatabase.memory()` (clearing keeps drafts, schema bump rebuilds); redaction and the 1 MB cap
    - _Requirements: 5.6, 40.5, 41.4, 45.4, 46.3, 46.4_
  - [ ] 1.9 Widget tests for theming
    - First frame uses the stored theme; mode, accent and dynamic color changes recolor in place; no palette hides the wallpaper switch
    - _Requirements: 3.4, 3.5, 3.8, 3.9_
  - [x] 1.10 Seed the Parity_Checklist
    - `librechat_flutter/PARITY.md`: one table per KMP area (`KMP screen or feature | KMP source | Status | Note`), each row `todo`, `deferred: …` or `dropped: …`, and an empty "Release checks" section
    - _Requirements: 48.8_

- [x] 2. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 3. Build the network core
  - [x] 3.1 Implement the Server URL rules
    - `lib/core/network/server_url.dart`: `normalizeServerUrl` (hand split, Req 8.4 order, reason copy), `isServerAuthority`, `serverUri`
    - _Requirements: 4.1, 4.3, 8.1, 8.2, 8.3, 8.4, 8.6_
  - [x] 3.2 Write property test for Server URL normalization
    - **Property 4: Server URL normalization is idempotent**
    - **Validates: Requirements 8.6**
  - [x] 3.3 Implement the Custom_Headers rules
    - `lib/core/network/custom_headers.dart`: `validateHeader` with KMP copy, `buildCustomHeaders`, `mergeCookieHeader`
    - _Requirements: 5.2, 5.4, 5.8_
  - [x] 3.4 Write property test for header validation
    - **Property 2: Header validation matches its model**
    - **Validates: Requirements 5.2**
  - [x] 3.5 Write property test for the Cookie merge
    - **Property 3: The Cookie merge keeps exactly one refreshToken**
    - **Validates: Requirements 5.8**
  - [x] 3.6 Create the core data models
    - `lib/core/models/` (add json_annotation, json_serializable): StartupConfig, InterfaceConfig, EndpointConfig, RolePermissions, User, Conversation, Message, ContentPart, ToolCall, Attachment; enums with `unknown`, no non-null `@Default` on nullable fields
    - _Requirements: 2.6, 4.6, 4.7_
  - [x] 3.7 Write property test for model JSON
    - **Property 1: Model JSON round trip**
    - **Validates: Requirements 4.8**
  - [x] 3.8 Write fixture round-trip tests
    - `test/core/models/model_fixtures_test.dart` with fixtures in `test/core/models/fixtures/` carrying an unknown field and enum value; later test sub-tasks add their models' fixtures
    - _Requirements: 4.7_
  - [x] 3.9 Implement AppException and userMessage
    - `lib/core/network/app_exception.dart`: `FailureKind`, `AppException`, `userMessage` with the `looksLikeUserMessage` test and KMP copy
    - _Requirements: 4.11, 5.9, 6.7_
  - [x] 3.10 Implement the session holder and ApiClient
    - `lib/core/auth/auth_service.dart`: `Session` and a ChangeNotifier `AuthService` with `serverUrl`, `session`, `load()`, `saveServer()` (a new URL clears session and Cache); `authServiceProvider` from `flutter_riverpod/legacy.dart`
    - `lib/core/network/api_client.dart` (add dio): `send`, `json`, `headersFor` with Arg_Envelope, per-hop headers, 30 s timer, gateway check, 5-hop redirects, status mapping and log line, wired into `main.dart`; the 401 step lands in Task 5
    - _Requirements: 1.2, 1.3, 4.1, 4.2, 4.3, 4.4, 4.5, 4.9, 4.10, 5.7, 5.9, 5.10, 6.7, 7.9, 46.2_
  - [x] 3.11 Implement ImageLoader and AppImage
    - `lib/core/images/image_loader.dart` (add crypto) and `app_image.dart` (add flutter_svg): memory LRU, SHA-256 disk files, shared Futures, `data:` URIs, SVG sniffing, `clear()`; built in `main.dart`
    - _Requirements: 4.2, 4.3, 4.4, 41.4_
  - [x] 3.12 HTTP tests for ApiClient and ImageLoader
    - User-Agent, auth per redirect hop, Custom_Headers and Cookie merge, `/images/` cookie, Arg_Envelope, omitted nulls, timeouts, gateway on a 3xx, 404 marking `missingFeatures`, one image request per URL; `userMessage` cases
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 4.9, 4.10, 4.11, 5.7, 5.9, 5.10, 6.7_
  - [x] 3.13 Implement HeadersEditor
    - `lib/core/ui/headers_editor.dart`: masked rows with "Show value"/"Hide value", "Remove header", "Add header", per-row rejection text
    - _Requirements: 5.1, 5.3_
  - [x] 3.14 Widget tests for HeadersEditor
    - Masking toggles; a rejected row keeps every typed row; blank rows are skipped
    - _Requirements: 5.1, 5.3, 5.4_

- [x] 4. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 5. Implement authentication
  - [x] 5.1 Implement AuthApi and the auth flows
    - `lib/core/auth/auth_api.dart` for every auth route; AuthService `login`, `verifyTwoFactor`, `exchangeSsoToken`, single-flight `refresh` with a pure `classifyRefresh`, `signOut`, `acknowledgeExpiry`, clearing through `CacheDb.clearAll()`
    - ApiClient step 7 (one refresh and retry on 401 outside the auth routes); `main.dart` sets `auth.api` and awaits `auth.load()`
    - _Requirements: 1.1, 1.2, 9.3, 9.4, 9.6, 9.7, 9.8, 10.1, 10.2, 10.3, 12.1, 12.3, 12.4, 12.5, 12.6, 12.7, 12.8, 12.9, 12.10, 12.11, 13.6_
  - [x] 5.2 Implement ConfigRepository and serverConfigProvider
    - `lib/core/config/server_config.dart`: cache entries, `probe(url, headers)`, `serverConfigProvider` showing the cache, then fetching per user with `refreshError` on failure; signed out it loads only `/api/config`
    - _Requirements: 6.1, 6.2, 45.2, 45.3_
  - [x] 5.3 Tests for AuthService and server config
    - `classifyRefresh` table; concurrent 401s share one refresh; second 401 keeps the session; rotated cookie; sign-out clears on failure; cached config survives a failed fetch
    - _Requirements: 6.2, 12.3, 12.4, 12.6, 12.7, 12.8, 12.9, 12.10, 45.3_
  - [x] 5.4 Implement the redirect rules and Server_URL_Screen
    - `lib/app/router.dart`: `refreshListenable: AuthService` and the three redirect rules; declare `/server-url`
    - `lib/features/auth/server_url_screen.dart` and controller: normalize, validate rows, "Insecure connection" dialog, probe, `auth.saveServer`, Advanced HeadersEditor, QR scan (add mobile_scanner) with camera-denied copy, prefilled "Change server"
    - _Requirements: 5.1, 5.3, 5.7, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8.5, 12.2, 44.10, 44.11_
  - [x] 5.5 Implement the sign-in screens
    - `lib/features/auth/` login, register, forgot, reset, verify-email and two-factor screens with controllers and routes, plus `lib/core/ui/otp_field.dart`; LDAP label, social buttons with AppImage, `openidAutoRedirect` once, gated links, KMP copy
    - _Requirements: 2.8, 9.1, 9.2, 9.5, 9.6, 9.7, 9.8, 9.9, 9.10, 9.11, 9.12, 10.1, 10.2, 10.4, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_
  - [x] 5.6 Implement Terms_Screen and SSO_Screen
    - `terms_screen.dart` (root navigator; decline signs out) and `sso_screen.dart` (add webview_flutter): SSO user agent, cookie clearing, callback gate, cookie-jar check, one finish into `exchangeSsoToken`, Retry, first-use dialog
    - _Requirements: 2.7, 11.9, 11.10, 13.1, 13.2, 13.3, 13.4, 13.5, 13.7, 13.8_
  - [x] 5.7 Widget tests for the auth screens
    - Redirect rules; URL reasons send nothing; http dialog; rejected headers block the probe; 2FA failure stays; register field errors; resend countdown; SSO gate and failure cases
    - _Requirements: 5.3, 7.1, 7.2, 7.4, 7.5, 8.5, 9.6, 9.7, 10.4, 11.2, 11.7, 13.4, 13.7_

- [x] 6. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 7. Add feature gating and the App_Shell
  - [x] 7.1 Implement the Server_Version
    - `lib/core/config/server_version.dart`: `Version.parse` and ordering, `targetVersion`, `releaseCommits` generated once with the design's `gh api` command, commit-prefix matching; `ServerInfo` gains the version
    - _Requirements: 6.4, 6.6_
  - [x] 7.2 Implement FeatureGates
    - `lib/core/config/feature_gate.dart`: `Feature`, `FeatureGates.has`, `featureGatesProvider` from config, endpoints, Role_Permissions, minimum versions and `missingFeatures`
    - _Requirements: 6.3, 6.5, 6.6, 6.7_
  - [x] 7.3 Unit tests for versions and gates
    - `rc9 < rc10`; `targetVersion` matches `UPSTREAM_VERSION`; absent and object flags; USE before roles load; each minimum version; the 404 rule
    - _Requirements: 6.3, 6.4, 6.5, 6.6, 6.7_
  - [x] 7.4 Implement the AppShell layout
    - `lib/app/shell/app_shell.dart`, `shell_drawer.dart`, `shell_menu_button.dart`: drawer below 600 dp, 320 dp sidebar above; one `ShellRoute` with `/chat` (`lib/features/chat/chat_screen.dart` landing greeting and welcome) and the moved `/settings/general`; each entry lands with its screen
    - Deferred from Task 5.4–5.6: with `/chat` declared, delete `_undeclaredStandIns` and the `routerRedirect` wrapper in `lib/app/router.dart` so the router uses `authRedirect` directly; update `test/app/router_test.dart` and `test/app/router_integration_test.dart`, which still expect sign-in and Terms "I Accept" to land on `/settings/general`
    - _Requirements: 9.5, 12.2, 14.1, 14.2, 14.3_
  - [x] 7.5 Implement banners and global dialogs
    - `lib/core/network/connectivity.dart` (add connectivity_plus) and `lib/app/shell/banners.dart`: offline, server and version banners in a polite live region; session-expired dialog; terms check sending to `/terms`
    - Deferred from Task 5.6: the post-sign-in terms check (Req 11.8) runs here and opens the existing `/terms` route; the session-expired dialog clears `AuthService.expired` through `acknowledgeExpiry()`
    - _Requirements: 6.8, 6.9, 6.10, 11.8, 14.4, 14.5, 14.6, 14.7, 14.8_
  - [x] 7.6 Widget tests for the shell
    - Layouts at 599 and 600 dp; banner dismiss and persistable; version banner rules; expiry dialog leads to `/login`
    - _Requirements: 6.8, 6.9, 6.10, 14.1, 14.2, 14.5, 14.6, 14.7_

- [x] 8. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 9. Implement the Conversation_List and conversation management
  - [x] 9.1 Implement ConversationsApi and ConversationsRepository
    - `lib/features/conversations/conversations_api.dart` and `conversations_repository.dart` with the Tag model: `watchList`, `refresh`, `loadMore`, Cache writes after each successful mutation
    - _Requirements: 4.5, 15.1, 15.5, 15.6, 15.10, 45.1, 45.2, 45.3_
  - [x] 9.2 Implement date grouping
    - `conversation_grouping.dart` (add intl): `groupConversations(conversations, now)` by calendar-day distance, month labels past 30 days
    - _Requirements: 15.2, 15.3_
  - [x] 9.3 Write property test for date groups
    - **Property 5: Date groups partition the list, newest first**
    - **Validates: Requirements 15.3**
  - [x] 9.4 Implement the list in the drawer
    - `conversation_list_controller.dart` and `conversation_list_screen.dart` in `ShellDrawer`: paging, Pinned section, 500 ms search, tag chips, pull to refresh
    - _Requirements: 15.1, 15.2, 15.4, 15.6, 15.7, 15.8, 15.9, 15.10_
  - [x] 9.5 Implement row actions and the Archived_Screen
    - Rename, delete, archive, pin, tags, duplicate, share link (add share_plus); taps go to `Routes.chat(id)`, declared in Task 11; `archived_screen.dart` at `/conversations/archived` with its drawer entry
    - _Requirements: 14.3, 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7, 16.8, 16.9_
  - [x] 9.6 Implement export and import
    - `conversation_export.dart`: `exportConversationJson`, `parseConversationExport`, KMP Markdown format; `saveFile` export and size-checked import (add file_picker)
    - _Requirements: 16.10, 16.11, 16.12, 16.13_
  - [x] 9.7 Write property test for conversation export
    - **Property 6: Conversation export round trip**
    - **Validates: Requirements 16.11**
  - [x] 9.8 Tests for conversations
    - Group labels at boundaries; Markdown export; route and body shapes; repository replace and append; list loading, error and debounce states
    - _Requirements: 15.2, 15.5, 15.7, 16.1, 16.2, 16.3, 16.5, 16.10_

- [x] 10. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 11. Implement reading a conversation
  - [x] 11.1 Implement the Message_Tree
    - `lib/features/chat/tree/message_tree.dart`: `activePath` (roots, newest-sibling default, anchor, visited set), `siblingsOf`, `selectSibling`
    - _Requirements: 17.3, 17.4, 17.5, 17.7_
  - [ ] 11.2 Write property test for the Active_Path
    - **Property 7: The Active_Path is a chain from a root**
    - **Validates: Requirements 17.5**
  - [x] 11.3 Implement MessagesRepository and conversationMessagesProvider
    - `data/messages_api.dart`, `data/messages_repository.dart` (watch, fetch, upsert, drafts) and `data/conversation_messages.dart` (cache first, `localIds`, `applyFinal`, `addLocal`, `select`, `reload`)
    - _Requirements: 17.1, 17.2, 45.1, 45.2, 45.3_
  - [x] 11.4 Implement the ChatScreen conversation view
    - Declare `/chat/c/:conversationId`; `chat_screen.dart` lists the Active_Path with SiblingNavigator, pinned auto-scroll and scroll-to-bottom, and the landing model icon and starters; `render/message_view.dart` and `render/markdown_text.dart` (add gpt_markdown, url_launcher)
    - _Requirements: 17.1, 17.2, 17.6, 17.7, 17.8, 17.10, 17.11, 22.1, 22.7, 22.9_
    - Deferred from Task 9.5: replace the `/chat/c/:conversationId` redirect stand-in in `lib/app/router.dart` with the ChatScreen builder. Rows, duplicates and archived rows already go to `Routes.chat(id)`, and deleting the open conversation (path `Routes.chat(id)`) already goes to `Routes.newChat`; both become live once the route exists
    - 11.3 extends `lib/features/chat/data/messages_api.dart` (created in 9.6) instead of creating it, and writes conversation rows through `ConversationsRepository.upsert`
  - [ ] 11.5 Tests for reading
    - Newest-sibling and `selectSibling` examples; repository transaction; provider cache-first; navigator and scroll behavior
    - _Requirements: 17.1, 17.2, 17.4, 17.6, 17.7, 17.10, 17.11_

- [x] 12. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 13. Implement streaming
  - [x] 13.1 Implement SseParser and the SSE_Formatter
    - `lib/core/stream/sse_parser.dart` (chunked UTF-8, BOM, CR/LF/CRLF with a pending CR, comments, dispatch rules) and `test/support/sse_formatter.dart`
    - _Requirements: 18.4_
  - [x] 13.2 Write property test for SSE
    - **Property 8: SSE format, chunk and parse round trip**
    - **Validates: Requirements 18.5**
  - [x] 13.3 Implement StreamEvent and EventMapper
    - `lib/core/stream/stream_events.dart` and `event_mapper.dart`: dispatch order, LangGraph table, step attribution, bad frames skipped; PendingAction, PendingSteer, TokenUsage and ContextUsage models
    - _Requirements: 18.6_
  - [x] 13.4 Implement StreamClient
    - `lib/core/stream/stream_client.dart`: `open(streamId, mapper, resume:)`, one refresh on 401, `StreamExpired` on 404, the 1, 2, 4, 8, 8 s ladder with an injectable `backoff`; built in `main.dart`
    - _Requirements: 5.9, 18.3, 19.1, 19.2, 19.3, 19.5_
  - [x] 13.5 Tests for EventMapper and StreamClient
    - Each mapper row and ignored name; attribution across interleaved steps; reconnect with `resume=true`, backoff order, attempt reset, 404, gateway without retry
    - _Requirements: 5.9, 18.6, 19.1, 19.2, 19.3, 19.5_

- [x] 14. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 15. Implement sending and stopping
  - [x] 15.1 Implement the payload builder
    - `send/chat_turn.dart` (ChatTurn, ChatSelection) and `send/payload_builder.dart`: base and optional fields, changed params, the per-kind table, `timezone`
    - _Requirements: 18.2, 21.6, 25.1, 25.2, 25.3, 25.4, 25.5, 27.2, 27.3, 30.2, 31.2_
  - [x] 15.2 Implement RunState, the reducer and the final merge
    - `run/run_state.dart`, `run/run_reducer.dart`, `run/final_merge.dart`: part rules, Sync_Frame replace, abort contract, optimistic matching
    - _Requirements: 18.7, 18.11, 18.12, 19.4, 20.5, 20.6_
  - [ ] 15.3 Unit tests for payloads, reducer and final merge
    - Each kind's fields and omissions; delta merging per agent; tool upserts; each abort-contract drop case; match by id, then parent and text
    - _Requirements: 18.2, 18.7, 18.12, 19.4, 20.6, 25.1, 25.2, 25.5_
  - [x] 15.4 Implement RunService start, events and finals
    - `data/chat_api.dart` and `run/run_service.dart` (add uuid, flutter_timezone): start, 50 ms flush, re-keying via `movedTo`, synchronous final handling, `_end` with epochs, titles, temporary chats
    - _Requirements: 18.1, 18.2, 18.3, 18.8, 18.9, 18.10, 18.11, 18.13, 18.14, 21.6, 21.9, 21.10, 21.11_
  - [x] 15.5 Implement stop and recovery
    - `stop` with the abort body and 15 s watchdog; status after exhaustion, `detached`, `onOpen`, app resume and network return
    - _Requirements: 19.4, 19.5, 19.6, 19.7, 19.8, 19.9, 20.1, 20.2, 20.3, 20.4, 20.7, 20.8_
  - [ ] 15.6 Tests for RunService
    - Fakes and fake time: one-frame swap, error keeps the partial, watchdog fallback, earlyAbort restores text, recovery transitions, title only after a first non-aborted Run
    - _Requirements: 18.11, 18.14, 19.6, 19.7, 20.4, 20.5, 21.10_
  - [x] 15.7 Implement the Composer and Model_Selector
    - `composer/composer_controller.dart`, `composer/composer_bar.dart` (Stop, temporary toggle), `render/live_reply_view.dart` (cursor, waiting indicator) and `composer/model_selector.dart` with a pure `filterSelector`
    - _Requirements: 17.9, 18.8, 18.9, 20.1, 20.8, 21.1, 21.2, 21.3, 21.4, 21.5, 21.6, 21.7, 21.8, 21.9, 22.8, 40.6_
  - [x] 15.8 Tests for the Composer
    - `filterSelector` cases; draft save and restore; empty send ignored; Stop disabled while pending; keyboard dismissal
    - _Requirements: 20.8, 21.3, 21.4, 21.7, 21.8, 40.6_

- [x] 16. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 17. Implement rich rendering
  - [x] 17.1 Implement activity grouping
    - `render/activity_groups.dart`: pure `groupParts(parts, grouping:)` with labels, phase skipping, the legacy rule and collapse defaults
    - _Requirements: 23.10, 23.11, 23.12_
  - [x] 17.2 Implement the content part views
    - `render/content_part_view.dart`, `tool_call_card.dart`, `thinking_block.dart`: the part table, intent titles, tool variants, answered questions, unknown types skipped; MessageView applies `groupParts`
    - _Requirements: 23.1, 23.2, 23.3, 23.9, 23.13, 23.14_
  - [x] 17.3 Implement code, math and citations
    - `render/code_block.dart` (add re_highlight) with a 64-entry memo and copy, `render/math.dart` `prepareMath` with `Math.tex` (add flutter_math_fork 0.7.4), citation links and source sheet in `markdown_text.dart`
    - _Requirements: 22.2, 22.3, 22.4, 22.5, 22.6, 22.8_
    - Partial (pure helpers): `render/math.dart` `prepareMath` landed; the `Math.tex` builder (flutter_math_fork), `code_block.dart` and the citation links and source sheet are still to do
  - [x] 17.4 Implement images, attachments and media
    - `render/image_viewer.dart`, `render/attachment_card.dart` (add open_filex) with office previews, `render/media_player.dart` (add just_audio, video_player)
    - _Requirements: 23.4, 23.5, 23.6, 23.7, 23.8_
  - [x] 17.5 Tests for rendering
    - `groupParts` label cases; `prepareMath` money and escape cases; tool card titles; office preview states
    - _Requirements: 22.3, 22.4, 23.2, 23.7, 23.10, 23.11, 23.12_

- [x] 18. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [x] 19. Implement Artifacts and Mermaid
  - [x] 19.1 Implement the Artifact_Parser
    - `artifacts/artifact_parser.dart`: line scanner with attribute forms, fenced and unfenced content, `complete`, `formatArtifact`, `artifactVersions`
    - _Requirements: 24.1, 24.2, 24.3_
  - [x] 19.2 Write property test for artifacts
    - **Property 9: Artifact write and parse round trip**
    - **Validates: Requirements 24.2**
  - [x] 19.3 Copy the web assets
    - Byte copies of mermaid, react, react-dom, babel and tailwind with licenses in `assets/web/`, each directory listed in `pubspec.yaml`
    - _Requirements: 24.8, 48.3_
  - [x] 19.4 Implement the WebView_Host
    - `artifacts/web_host.dart`: `buildMermaidHtml`, `buildArtifactHtml` with CSPs and the React import map, and `WebContentView` with the `Host` channel and navigation blocking
    - _Requirements: 2.7, 24.6, 24.8, 24.9, 24.10, 24.11, 24.15_
  - [x] 19.5 Implement the Artifact_Viewer
    - `artifacts/artifact_button.dart`, inline artifacts, `artifacts/artifact_viewer.dart` (versions, toggle, copy, share), `/artifact` on the root navigator, inline `mermaid` fences
    - _Requirements: 22.2, 24.4, 24.5, 24.7, 24.12, 24.13, 24.14_
  - [x] 19.6 Tests for artifacts
    - CSP and script paths per type; every referenced asset exists; viewer versions and the "View code" error action
    - _Requirements: 24.6, 24.8, 24.12, 24.14_
    - Partial: the parser, CSP, script-path and asset tests landed with 19.1-19.4; the viewer versions and "View code" tests, a WebContentView fake-platform test, the untapped-launch gesture gate (http, https, mailto, tel) and {height} clamping come with 19.5

- [x] 20. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 21. Add message actions and Composer extras
  - [x] 21.1 Implement message actions
    - `render/message_actions.dart`: edit, regenerate, continue, edit AI save and submit, feedback, copy, fork, timestamp toggle, disabled during a Run
    - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5, 25.6, 25.7, 25.8, 25.9, 25.13, 25.14_
  - [x] 21.2 Implement quotes, search and the Media_Screen
    - "Add to chat" quote chips, `render/find_matches.dart` with app-bar navigation and highlights, `media_screen.dart` at `/chat/c/:conversationId/media`
    - _Requirements: 25.10, 25.11, 25.12_
  - [ ] 21.3 Tests for message actions
    - `findMatches` cases; feedback, fork and edit request shapes; actions disabled during a Run
    - _Requirements: 25.3, 25.6, 25.7, 25.9, 25.11, 25.14_
  - [x] 21.4 Implement attachments and uploads
    - `composer/attachments.dart` (add image_picker, mime) and `lib/features/files/files_api.dart` `upload` with FileObject and FileConfig: `fileConfigProvider`, pure `checkAttachments`, delivery choice, chips with progress, cancel and retry
    - _Requirements: 26.1, 26.2, 26.3, 26.5, 26.6, 26.7, 26.8, 44.10, 44.11_
    - Partial (pure helpers): the FileConfig model (`core/models/file_config.dart`) and pure `checkAttachments` with `FileInfo.detect` (mime added) landed. Limits resolve field by field like the Server's `getEndpointFileConfig`/`mergeWithDefault`; a `fileLimit` or `totalSizeLimit` of 0 is unrestricted, a `fileSizeLimit` of 0 restricts. A document-supported provider's entry with no patterns skips the client mime check instead of inheriting `default`'s patterns (the Server substitutes its built-in list). `fileConfigProvider`, `files_api.dart` `upload`, image_picker, delivery choice and the chips are still to do
    - When 21.4 wires the check: confirm against a live `/api/files/config` response whether sizes arrive in MB or bytes (the web client runs `mergeFileConfig`, MB→bytes, client-side); seed upstream's built-in `agents`/`assistants`/`azureAssistants`/`anthropic` entries (`file-config.ts` `mergeFileConfig`) or document the divergence; check text-delivered (`context`) files against `fileConfig.text`, not the provider allowlist; an explicit `supportedMimeTypes: []` currently reads as unset
  - [x] 21.5 Write property test for attachments
    - **Property 10: Attachment acceptance matches its model**
    - **Validates: Requirements 26.4**
  - [ ] 21.6 Implement tools, parameters and presets
    - `composer/tools_sheet.dart`, `composer/parameters_sheet.dart`, `composer/presets_sheet.dart` with the Preset model
    - _Requirements: 27.1, 27.2, 27.3, 27.4_
  - [ ] 21.7 Implement `/` prompt commands
    - `composer/prompt_variables.dart` (`extractVariables`, `fillVariables`), the `/` match list and the variable dialog, off with `slashCommands`
    - _Requirements: 27.5, 27.6, 27.7, 27.8, 40.7_
    - Partial (pure helpers): `composer/prompt_variables.dart` `extractVariables` and `fillVariables` landed; the `/` match list, the variable dialog and the `slashCommands` gate are still to do
  - [x] 21.8 Write property test for prompt variables
    - **Property 11: Prompt variable filling matches its model**
    - **Validates: Requirements 27.9**
  - [x] 21.9 Implement favorites in the Model_Selector
    - Row stars, favorites first, the full list posted to `/api/user/settings/favorites`
    - _Requirements: 27.10_
  - [ ] 21.10 Widget tests for Composer extras
    - Upload blocks send; rejection names the first limit; gated tool toggles; `/` list and variable dialog
    - _Requirements: 26.3, 26.7, 27.1, 27.5, 27.7_

- [ ] 22. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 23. Implement advanced runs
  - [ ] 23.1 Implement human-in-the-loop pauses
    - `render/pending_action_card.dart` and `RunService.resolveAction`: approvals, questions, Skip, resume body, `actionError` with kept input
    - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5, 28.6, 28.7, 28.8_
  - [ ] 23.2 Implement steering and Queued_Turns
    - `run/turn_queue.dart` `applyQueueEvent`; RunService `sendDuringRun`, steer, cancel, server queue, drain and attach; steer and queue chips
    - _Requirements: 20.7, 29.1, 29.2, 29.3, 29.4, 29.5, 29.6, 29.7, 29.8, 29.9, 29.10, 29.11, 29.13_
  - [ ] 23.3 Write property test for steering and queueing
    - **Property 12: Steered and queued texts reach the Run exactly once**
    - **Validates: Requirements 29.12**
  - [ ] 23.4 Implement Comparison
    - `comparison/panes.dart` `splitPanes`, "Add model", two panes without grouping, continue through `MessagesApi.branch`, reopen from the secondary id
    - _Requirements: 30.1, 30.2, 30.3, 30.4, 30.5, 30.6, 30.7_
    - Partial (pure helpers): `comparison/panes.dart` `splitPanes` and the comparison id parsing (`isSecondaryAgentId`, `stripPaneSuffix`, `secondaryAgentId`, `parsePaneAgentId`) landed; "Add model", the two-pane UI, continue through `MessagesApi.branch` and reopen are still to do
  - [ ] 23.5 Implement context usage, compaction, subagents and traces
    - `render/context_gauge.dart` with `tokenConfigProvider`, the compact action, subagent cards and sheet, `render/trace_sheet.dart`
    - _Requirements: 31.1, 31.2, 31.3, 31.4, 31.5_
  - [ ] 23.6 Tests for advanced runs
    - Resume body fields; `splitPanes` and id parsing; gauge math; trace entry gated by availability
    - _Requirements: 28.4, 28.8, 30.4, 30.7, 31.1, 31.5_
    - Partial (pure helpers): the `splitPanes` and pane id parsing tests landed; resume body, gauge math and trace gating tests come with 23.1 and 23.5

- [ ] 24. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 25. Implement voice
  - [ ] 25.1 Implement VoiceService
    - `voice/voice_service.dart` (add speech_to_text, record, flutter_tts): Server defaults, device and Server STT and TTS, mic button, stop control, auto read-aloud after non-aborted Finals, microphone-denied copy
    - _Requirements: 20.7, 32.1, 32.2, 32.3, 32.4, 32.5, 32.6, 32.7, 44.10, 44.11_
  - [ ] 25.2 Tests for voice
    - STT and TTS request shapes; markdown stripped from spoken text; no read-aloud after Stop
    - _Requirements: 20.7, 32.3, 32.4, 32.6_

- [ ] 26. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 27. Implement agents
  - [ ] 27.1 Implement Agent_Marketplace and Agent_Detail_Screen
    - `lib/features/agents/agents_api.dart` with the Agent model, marketplace and detail screens, routes and drawer entry; actions gated by permission bits
    - _Requirements: 14.3, 33.1, 33.2, 33.3, 33.4, 33.5, 33.6, 33.7, 33.8_
  - [x] 27.2 Implement the OpenAPI_Parser
    - `lib/features/agents/openapi_parser.dart` (add yaml): `parseOpenApiSpec` with error cases, domain and derived functions
    - _Requirements: 34.9, 34.10_
  - [x] 27.3 Write property test for the OpenAPI_Parser
    - **Property 13: The OpenAPI_Parser reads YAML and JSON alike**
    - **Validates: Requirements 34.11**
  - [ ] 27.4 Implement SharingSheet
    - `lib/features/agents/permissions_api.dart` and `sharing_sheet.dart`: principals, roles, 500 ms search, public access, save
    - _Requirements: 34.15, 35.6_
  - [ ] 27.5 Implement the Agent_Editor
    - `agent_editor_screen.dart` and controller at `/agents/new` and `/agents/a/:agentId/edit`: basics, avatar, capabilities, tools with auth, tool favorites, actions, files, skills, subagents, edges, versions, dirty-draft `PopScope`
    - _Requirements: 34.1, 34.2, 34.3, 34.4, 34.5, 34.6, 34.7, 34.8, 34.12, 34.13, 34.14, 34.16_
    - Before the editor parses specs: `openapi_parser.dart`'s `_maxNodes = 100000` counts every converted value, so large real specs (GitHub, Stripe) fail. Count only YAML alias re-expansions against the budget, or raise the cap after measuring a known large spec
  - [ ] 27.6 Tests for agents
    - OpenAPI error cases; marketplace paging and debounce; actions hidden by bits; dirty-draft prompt
    - _Requirements: 33.3, 33.5, 34.10, 34.16_
    - Partial: the OpenAPI error-case tests landed with 27.2

- [ ] 28. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 29. Implement Prompts, Projects, Files, Skills and Schedules
  - [ ] 29.1 Implement the Prompts_Library
    - `lib/features/prompts/`: API, library, detail and editor screens with Prompt and PromptGroup, production check, versions, Use, `/` list invalidation
    - _Requirements: 35.1, 35.2, 35.3, 35.4, 35.5, 35.6, 35.7, 35.8_
  - [ ] 29.2 Implement the Projects_Screen
    - `lib/features/projects/`: API, list, project chats, the Chats | Projects switch, move and remove, assignment after `created`
    - _Requirements: 36.1, 36.2, 36.3, 36.4_
  - [ ] 29.3 Implement the Files_Manager
    - `lib/features/files/files_screen.dart` and controller (add pdfx): sort, filter, views, upload, download, previews, multi-select delete, picker mode for the Composer
    - _Requirements: 26.1, 37.1, 37.2, 37.3, 37.4, 37.5, 37.6, 37.7, 37.8_
  - [ ] 29.4 Implement the Skills_Screen
    - `lib/features/skills/`: API, list with active toggles, detail, editor with the 409 rule, files, import errors, delete
    - _Requirements: 38.1, 38.2, 38.3, 38.4, 38.5, 38.6_
  - [ ] 29.5 Implement the Schedules_Screen
    - `lib/features/schedules/`: API, list, editor with limits and the flutter_timezone default, `schedule_cadence.dart` `cadenceIntervalMinutes`, Run now
    - _Requirements: 39.1, 39.2, 39.3, 39.4, 39.5, 39.6, 39.7_
    - Partial (pure helpers): the ScheduleCadence model (`core/models/schedule.dart`) and `schedule_cadence.dart` `cadenceIntervalMinutes` landed, with upstream's 120-minute DST allowance on daily-and-longer cadences; cron returns null and is left to the Server. The API, list, editor and Run now are still to do
  - [ ] 29.6 Tests for these areas
    - `cadenceIntervalMinutes` cases; prompt create and production calls; picker mode returns files; skill 409 keeps text; gated entries
    - _Requirements: 35.3, 35.4, 37.8, 38.5, 39.5, 39.6_
    - Partial (pure helpers): the `cadenceIntervalMinutes` cases landed (hourly, daily, weekdays, weekly gaps, the `minIntervalMinutes` floor boundaries, cron as null); the prompt, picker, skill and gate tests are still to do

- [ ] 30. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 31. Implement the Settings_Screen
  - [ ] 31.1 Implement the settings root, Chat and About
    - `lib/features/settings/settings_screen.dart` and `chat_settings_screen.dart` (add package_info_plus): sections, gated entries, Chat settings, memory personalization with revert, About
    - _Requirements: 40.1, 40.3, 40.4, 40.8, 40.9_
  - [ ] 31.2 Implement Data settings
    - `data_settings_screen.dart` and `shared_links_screen.dart`: archive all, delete all, revoke keys, clear cache, export logs, shared links
    - _Requirements: 41.1, 41.2, 41.3, 41.4, 41.5, 41.6_
  - [ ] 31.3 Implement Account settings
    - `account_settings_screen.dart`, `two_factor_dialogs.dart` (add qr_flutter), `server_connection_dialog.dart` with HeadersEditor: profile, avatar, balance, 2FA, backup codes, delete account, sign out
    - _Requirements: 5.1, 5.5, 5.6, 42.1, 42.2, 42.3, 42.4, 42.5, 42.6, 42.7, 42.8_
  - [ ] 31.4 Implement keys, favorites, MCP, memories, presets and role skills
    - Screens in `lib/features/settings/` with McpServer, Memory, ApiKey, SharedLink and Balance models, `memoryById` routing and the MCP OAuth consent
    - _Requirements: 43.1, 43.2, 43.3, 43.4, 43.5, 43.6, 43.7, 43.8, 43.9, 43.10, 43.11, 43.12_
  - [ ] 31.5 Tests for settings
    - Changes reach open screens; Clear cache keeps drafts; header dialog storage failure; 2FA confirm; memory route by gate
    - _Requirements: 5.5, 5.6, 40.4, 41.4, 42.4, 43.10_

- [ ] 32. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 33. Add Android integrations
  - [ ] 33.1 Implement deep links
    - `lib/features/integrations/deep_link.dart` `parseDeepLink` and `deep_link_controller.dart` (add app_links): targets held while signed out, invalid-link notice
    - _Requirements: 44.2, 44.3, 44.4, 44.5, 44.6_
    - Partial (pure helpers): `deep_link.dart` `parseDeepLink` landed; `deep_link_controller.dart` (app_links), held targets and the invalid-link notice are still to do. The controller must keep `Uri.encodeComponent` on the conversation id at every API path use, since `parseDeepLink` returns it decoded
  - [ ] 33.2 Implement shares
    - `share_controller.dart` (add receive_sharing_intent): text into the Composer, images and files attached, held until sign-in
    - _Requirements: 44.7, 44.8_
  - [ ] 33.3 Update the Android manifest
    - `android/app/src/main/AndroidManifest.xml`: permissions, optional camera, `librechat` VIEW and SEND filters, `flutter_deeplinking_enabled` false
    - _Requirements: 44.1, 44.9_
  - [ ] 33.4 Tests for integrations
    - `parseDeepLink` valid and malformed cases; a link or share received while signed out opens after sign-in
    - _Requirements: 44.2, 44.3, 44.5, 44.6, 44.8_
    - Partial (pure helpers): the `parseDeepLink` valid and malformed cases landed; the signed-out link and share test comes with the controller

- [ ] 34. Checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

- [ ] 35. Prepare the release
  - [ ] 35.1 Finish the release build
    - `scripts/ci.sh`: `cmp` web-asset check against the KMP folder first, release APK last; R8, resource shrinking and debug-key signing stay in `android/app/build.gradle.kts`
    - _Requirements: 48.1, 48.2, 48.5, 48.6_
  - [ ] 35.2 Do the accessibility and copy pass
    - Tooltips on icon-only controls, 48 dp tap targets, `onSurface` body text, no fixed `textScaler`; UI text checked against KMP `strings.xml`
    - _Requirements: 2.8, 47.1, 47.2, 47.3, 47.4_
  - [ ] 35.3 Accessibility tests
    - Tap-target, label and contrast guidelines on the main screens; 4.5:1 for every preset in both brightnesses
    - _Requirements: 47.1, 47.2, 47.3_
  - [ ] 35.4 Add the CI_Workflow
    - `.github/workflows/flutter-android.yml`: push and pull_request on the design's `paths`, Temurin 17, Flutter 3.44.4, then `librechat_flutter/scripts/ci.sh`
    - _Requirements: 2.5, 48.4, 48.5, 48.6_
  - [ ] 35.5 Finalize the Parity_Checklist
    - `PARITY.md` has no `todo` rows; "Release checks" documents the smoke flow and its record format
    - Deferred from Task 5.6, device checks to record under "Release checks": a GET-callback provider (Google or GitHub) completes SSO although webview_flutter re-loads allowed navigations; Apple or SAML completes through the cookie check; the `refreshToken` cookie is gone after capture; a cancelled provider login shows the failure and Retry works; Close and system Back return to `/login`
    - _Requirements: 48.7, 48.8, 48.9_

- [ ] 36. Final checkpoint: run `scripts/ci.sh --skip-build`, make sure all tests pass, and ask the user if questions arise.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3", "1.4", "1.6", "1.10"] },
    { "id": 2, "tasks": ["1.5"] },
    { "id": 3, "tasks": ["1.7"] },
    { "id": 4, "tasks": ["1.8", "1.9"] },
    { "id": 5, "tasks": ["3.1", "3.3", "3.9"] },
    { "id": 6, "tasks": ["3.2", "3.6"] },
    { "id": 7, "tasks": ["3.4", "3.10"] },
    { "id": 8, "tasks": ["3.5", "3.11", "3.13"] },
    { "id": 9, "tasks": ["3.7", "3.12", "3.14"] },
    { "id": 10, "tasks": ["3.8"] },
    { "id": 11, "tasks": ["5.1", "5.2"] },
    { "id": 12, "tasks": ["5.3", "5.4"] },
    { "id": 13, "tasks": ["5.5"] },
    { "id": 14, "tasks": ["5.6"] },
    { "id": 15, "tasks": ["5.7"] },
    { "id": 16, "tasks": ["7.1"] },
    { "id": 17, "tasks": ["7.2"] },
    { "id": 18, "tasks": ["7.3", "7.4"] },
    { "id": 19, "tasks": ["7.5"] },
    { "id": 20, "tasks": ["7.6"] },
    { "id": 21, "tasks": ["9.1", "9.2"] },
    { "id": 22, "tasks": ["9.3", "9.4"] },
    { "id": 23, "tasks": ["9.5"] },
    { "id": 24, "tasks": ["9.6"] },
    { "id": 25, "tasks": ["9.7", "9.8"] },
    { "id": 26, "tasks": ["11.1", "11.3"] },
    { "id": 27, "tasks": ["11.2", "11.4"] },
    { "id": 28, "tasks": ["11.5"] },
    { "id": 29, "tasks": ["13.1", "13.3"] },
    { "id": 30, "tasks": ["13.2", "13.4"] },
    { "id": 31, "tasks": ["13.5"] },
    { "id": 32, "tasks": ["15.1", "15.2"] },
    { "id": 33, "tasks": ["15.3", "15.4"] },
    { "id": 34, "tasks": ["15.5"] },
    { "id": 35, "tasks": ["15.6", "15.7"] },
    { "id": 36, "tasks": ["15.8"] },
    { "id": 37, "tasks": ["17.1", "17.3"] },
    { "id": 38, "tasks": ["17.2"] },
    { "id": 39, "tasks": ["17.4"] },
    { "id": 40, "tasks": ["17.5"] },
    { "id": 41, "tasks": ["19.1", "19.3"] },
    { "id": 42, "tasks": ["19.2", "19.4"] },
    { "id": 43, "tasks": ["19.5"] },
    { "id": 44, "tasks": ["19.6"] },
    { "id": 45, "tasks": ["21.1", "21.7"] },
    { "id": 46, "tasks": ["21.2", "21.8", "21.9"] },
    { "id": 47, "tasks": ["21.3", "21.4"] },
    { "id": 48, "tasks": ["21.5", "21.6"] },
    { "id": 49, "tasks": ["21.10"] },
    { "id": 50, "tasks": ["23.1"] },
    { "id": 51, "tasks": ["23.2"] },
    { "id": 52, "tasks": ["23.3", "23.4"] },
    { "id": 53, "tasks": ["23.5"] },
    { "id": 54, "tasks": ["23.6"] },
    { "id": 55, "tasks": ["25.1"] },
    { "id": 56, "tasks": ["25.2"] },
    { "id": 57, "tasks": ["27.1", "27.2"] },
    { "id": 58, "tasks": ["27.3", "27.4"] },
    { "id": 59, "tasks": ["27.5"] },
    { "id": 60, "tasks": ["27.6"] },
    { "id": 61, "tasks": ["29.1"] },
    { "id": 62, "tasks": ["29.2"] },
    { "id": 63, "tasks": ["29.3"] },
    { "id": 64, "tasks": ["29.4"] },
    { "id": 65, "tasks": ["29.5"] },
    { "id": 66, "tasks": ["29.6"] },
    { "id": 67, "tasks": ["31.1"] },
    { "id": 68, "tasks": ["31.2"] },
    { "id": 69, "tasks": ["31.3"] },
    { "id": 70, "tasks": ["31.4"] },
    { "id": 71, "tasks": ["31.5"] },
    { "id": 72, "tasks": ["33.1", "33.3"] },
    { "id": 73, "tasks": ["33.2"] },
    { "id": 74, "tasks": ["33.4"] },
    { "id": 75, "tasks": ["35.1", "35.2"] },
    { "id": 76, "tasks": ["35.3", "35.4"] },
    { "id": 77, "tasks": ["35.5"] }
  ]
}
```

## Notes

- Sub-tasks marked `*` are optional tests and can be skipped for a faster MVP; implementation sub-tasks are never optional.
- Scope: files change only inside `librechat_flutter/`, plus `.github/workflows/flutter-android.yml` in Task 35. The KMP code is read-only, no task touches release signing, and `ios/` stays as generated.
- Each sub-task adds its pinned packages when its code first imports them, and declares routes and drawer entries only for the screens it implements.
- Every top-level task ends with build_runner, `flutter analyze` and `flutter test` passing, and flips its delivered `PARITY.md` rows to `ported`.
- Property tests call `forAll` from `test/support/property.dart` with 100 runs, one test per property, named `Property N: <name>` with `// Feature: flutter-android-rewrite, Property N: <statement>` and `// Validates: Requirements X.Y` above it. Each property sub-task adds its generators to `property.dart`.
- HTTP tests run in plain `test()` against `test/support/test_server.dart`, never inside `testWidgets`. Fakes `implements` their class in `test/support/fakes.dart`.
- Order changes from the suggested outline, following the design: ConfigRepository moves to Task 5 because the auth screens read it; ImageLoader moves to Task 3 because the Login_Screen shows provider images; the General settings screen lands in Task 1 as the first real route; `PARITY.md` is seeded in Task 1 because the design has each task flip its rows.
