# Requirements Document

## Introduction

Switchboard is a native Android client for self-hosted LibreChat servers. This feature rewrites the existing Kotlin Multiplatform / Compose Multiplatform client (the KMP_App, about 206k lines of Kotlin) as a Flutter app in `librechat_flutter/`, at full Android feature parity. The App connects to an unmodified LibreChat server whose URL the user enters during onboarding. It targets LibreChat v0.8.8-rc4, and older servers degrade through `/api/config` gating and a version banner.

Simplicity governs every requirement (Requirement 1). The App reproduces what users see, plus the server protocol rules needed to work correctly against the server, and nothing else. The KMP_App is the reference for behavior and UI copy, not for structure. Mechanisms it carries only for multi-account, iOS or rare race conditions are deliberately not ported.

Out of scope (deferred): iOS; multi-account and the account switcher; localization (English only); background prefetch and the Prefetch Activity screen; home-screen model and artifact shortcuts, the Artifact Shortcuts screen, "add to home screen" and the `librechat://artifact/{id}` deep link that opens those shortcuts; the custom accent color picker (the 11 accent presets remain); release signing with a release keystore (release builds use the debug key).

Starting point: `librechat_flutter/` already contains the Android project (namespace, minSdk, label, network security config, launcher icons, R8 release build signed with the debug key), the Material 3 theme with accent presets, route constants, a placeholder router and `scripts/ci.sh`. Requirements 1 and 2 decide which of these are trimmed.

Conventions: route paths are relative to the Server_URL. "As in the KMP_App" refers to the behavior and the English copy of the matching KMP screen. That copy lives in the matching KMP module's `strings.xml` files (including `app/src/main/res/values/strings.xml`), or in the KMP Kotlin code where the KMP_App hard-codes the text.

## Glossary

- **App**: The Flutter Android application in `librechat_flutter/`, labelled "Switchboard", applicationId `com.garfiec.librechat.flutter`.
- **KMP_App**: The existing Kotlin Multiplatform client in this repository (package `com.garfiec.librechat`). Read-only reference.
- **Rewrite**: The set of repository changes this spec produces.
- **Server**: The user's self-hosted, unmodified LibreChat backend.
- **Server_URL**: The normalized base URL of the Server. The URL may include a subpath, such as `https://host/librechat`.
- **Server_Authority**: The scheme, host and port of the Server_URL, with the default port (443 for https, 80 for http) when none is written.
- **Server_Config**: The JSON that `GET /api/config` returns.
- **Role_Permissions**: The permission set that `GET /api/roles/{role}` returns for the signed-in user's role.
- **Server_Version**: The Server's LibreChat version. The App takes the Server_Config `version` field when present, otherwise the release whose tag commit equals Server_Config `buildInfo.commit` in a list of LibreChat release commits shipped with the App, and otherwise reports "unknown". LibreChat has no version endpoint.
- **Target_Version**: LibreChat v0.8.8-rc4, as recorded in `UPSTREAM_VERSION` and in `backendTargetVersion` in `version.properties`.
- **Feature_Gate**: The App logic that decides whether a feature is offered.
- **API_Client**: The dio-based client for REST requests to the Server.
- **Stream_Client**: The `dart:io` `HttpClient`-based client that opens and reads a Stream.
- **SSE_Parser**: The parser that turns `text/event-stream` bytes into events (event name, data, id).
- **SSE_Formatter**: Test-support code that writes events as `text/event-stream` text, used to verify the SSE_Parser.
- **Browser_User_Agent**: A Chrome-for-Android User-Agent string. The Server's ua-parser-js middleware answers HTTP 403 to non-browser agents.
- **Arg_Envelope**: The request body shape `{"arg": {...}}` that the Server's conversation update, archive, pin and delete routes expect.
- **Custom_Headers**: Static request headers the user defines for the Server, such as Cloudflare Access service-token headers.
- **Reserved_Header_Names**: `host`, `content-length`, `transfer-encoding`, `connection`, `upgrade`, `te`, `authorization`, `user-agent`, `accept`, `accept-encoding`, `content-type`, `expect` and `proxy-authorization`, compared case-insensitively.
- **Header_Validator**: The App function that accepts or rejects one Custom_Headers name/value pair.
- **Access_Gateway_Error**: The error the App raises when a response carries a `WWW-Authenticate` header line containing `Cloudflare-Access`.
- **Auth_Service**: The single App component that signs in, stores tokens, refreshes the Access_Token and signs out.
- **Access_Token**: The JWT that the Server returns in the `token` field of login, two-factor and refresh responses, sent as `Authorization: Bearer`.
- **Refresh_Token**: The value of the `refreshToken` cookie that the Server sets through `Set-Cookie`. The v0.8.8-rc4 refresh route reads this token only from the `Cookie` request header, not from the request body.
- **LibreChat_Refresh_Rejection**: A response from `POST /api/auth/refresh` that LibreChat itself authored to end the session: HTTP 401 or 403 whose body contains `Invalid refresh token`, `Invalid OpenID refresh token`, `No session found`, `Refresh token expired or not found for this user` or `OPENID_SESSION_MISSING`; HTTP 200 whose body is `Refresh token not provided`; or a redirect to the Server's `/login` path.
- **Secure_Store**: flutter_secure_storage, which holds the Access_Token, the Refresh_Token and the Custom_Headers.
- **Settings_Store**: shared_preferences, which holds simple settings.
- **Cache**: The drift SQLite database that holds cached Server data and Composer drafts. The Server stays the source of truth.
- **Server_URL_Normalizer**: The App function that turns user input into a Server_URL.
- **Server_URL_Screen**, **Login_Screen**, **Register_Screen**, **Forgot_Password_Screen**, **Reset_Password_Screen**, **Verify_Email_Screen**, **Two_Factor_Screen**, **Terms_Screen**: The onboarding and authentication screens of the same names in the KMP_App.
- **SSO_Screen**: The in-app WebView screen for social, OpenID and SAML sign-in.
- **App_Shell**: The signed-in frame: navigation drawer or sidebar, banners and global dialogs.
- **Conversation_List**: The list of conversations shown in the drawer or sidebar.
- **Archived_Screen**: The screen that lists archived conversations.
- **Chat_Screen**: The screen that shows one conversation, or the new-chat landing state.
- **Composer**: The message input area of the Chat_Screen with its attachments, tools and send and stop controls.
- **Model_Selector**: The sheet for choosing the endpoint, model, model spec or agent.
- **Message_Renderer**: The widgets that render one message's content.
- **Message_Tree**: The App logic that links messages by `parentMessageId` and picks the displayed path.
- **Root_Parent_Id**: `00000000-0000-0000-0000-000000000000`, the `parentMessageId` of a conversation's first message.
- **Siblings**: Messages that share a `parentMessageId`.
- **Active_Path**: The chain of messages from a root to a leaf that the Chat_Screen displays.
- **Media_Screen**: The screen that shows the images and files of one conversation.
- **Run**: One Server-side generation, started by a chat request.
- **Stream**: The event stream at `GET /api/agents/chat/stream/{streamId}` that carries a Run's events.
- **Final_Frame**: The `final` stream event that ends a Run. The event carries the saved request and response messages and may carry the `aborted` and `earlyAbort` flags.
- **Sync_Frame**: The `sync` stream event that a resumed Stream sends first, carrying the Run's current content.
- **Optimistic_Message**: The user message the App shows before the Server confirms the message.
- **Partial_Reply**: Assistant content received before a Run ended early.
- **Pending_Action**: A human-in-the-loop pause: a tool-approval request or an ask-user question.
- **Steer**: A message the user injects into a running Run.
- **Queued_Turn**: A message the user composes during a Run, to run as the next turn.
- **Comparison**: A Run that answers with two models or agents in parallel through `addedConvo`.
- **Artifact**: A `:::artifact{...}` block in assistant text that the App renders as a document.
- **Artifact_Parser**: The App function that finds Artifacts in message text.
- **Artifact_Viewer**: The App screen or sheet that shows one Artifact.
- **Prompt_Variable_Parser**: The App function that finds and fills `{{variable}}` placeholders in a prompt.
- **OpenAPI_Parser**: The App function that reads an agent action's OpenAPI spec and derives the action's domain and function definitions.
- **Vendored_Web_Assets**: The pinned third-party JavaScript and CSS in `feature/chat/src/commonMain/composeResources/files/web/` (mermaid, React, ReactDOM, Babel, Tailwind, marked, highlight.js, KaTeX).
- **WebView_Host**: The App component that renders Mermaid diagrams and HTML, React and SVG Artifacts in a WebView.
- **Voice_Service**: The App component for speech-to-text and text-to-speech.
- **Agent_Marketplace**, **Agent_Detail_Screen**, **Agent_Editor**, **Prompts_Library**, **Projects_Screen**, **Files_Manager**, **Skills_Screen**, **Schedules_Screen**: The screens of the same names in the KMP_App, including their dialogs and sheets.
- **Settings_Screen**: The settings root and its sub-screens (General, Chat, Data, Account, API keys, provider keys, favorites, MCP servers, memories, preset manager, shared links and role skills).
- **Deep_Link_Handler**: The App component that handles `librechat://` links.
- **Share_Handler**: The App component that receives content shared from other apps.
- **Diagnostic_Log**: The App's local log of technical events, which the user can export.
- **Build**: The Gradle and Flutter build configuration of the App.
- **CI_Workflow**: The GitHub Actions workflow that verifies the App.
- **Parity_Checklist**: A document in `librechat_flutter/` that lists each KMP_App screen and feature with the item's status in the App.

## Requirements

### Requirement 1: Keep the code simple

**User Story:** As the maintainer, I want the Flutter code kept as simple as the features allow, so that one person can read, change and debug the whole app.

#### Acceptance Criteria

1. THE App SHALL port from the KMP_App only behavior that users can see or that correct operation against the Server requires, leaving out mechanisms that exist only for multi-account, iOS or rare race conditions (token epochs, per-account token slots, account-switch resets, add-account flows and proactive-refresh suppression markers).
2. THE Auth_Service SHALL hold one session, made of one Server_URL, one Access_Token and one Refresh_Token.
3. THE App SHALL read and write the Access_Token and the Refresh_Token only through the Auth_Service.
4. THE App SHALL introduce an abstract interface only where at least two production implementations of that interface exist.
5. THE App SHALL use the default settings of Flutter and of each package, except where a requirement in this document needs a different setting.
6. THE App's `pubspec.yaml` SHALL list only packages that the App's code or tests import, plus the code generation and lint tools that the App's build runs.
7. THE App SHALL depend only on stable, non-prerelease package versions, each pinned to an exact version.
8. THE App SHALL use code generation only for data models (immutability, equality and JSON serialization) and for the Cache schema.
9. THE App SHALL declare a navigation route only for a screen that is implemented.
10. THE App SHALL keep platform scaffolding only for Android and iOS, leaving the `ios/` folder as `flutter create` generated it until the deferred iOS work.
11. THE App SHALL pass `flutter analyze` with zero issues under the `flutter_lints` rule set plus only the additional rules that the design document lists with a reason.

### Requirement 2: Project setup and coexistence with the KMP app

**User Story:** As the maintainer, I want the Flutter app to live beside the KMP app without touching the KMP app, so that both can be built and installed during the transition.

#### Acceptance Criteria

1. THE Rewrite SHALL add, change or delete files only inside `librechat_flutter/`, except for adding the CI_Workflow file in `.github/workflows/` and this spec's files in `.kiro/specs/flutter-android-rewrite/`.
2. THE App SHALL use `com.garfiec.librechat.flutter` as the Android namespace and applicationId, so that the App installs beside the KMP_App's release build (`com.garfiec.librechat`) and debug build (`com.garfiec.librechat.debug`) without replacing either.
3. THE App SHALL set the Android minSdk to 26, the launcher label to "Switchboard" and the launcher icons to those of the KMP_App's release build.
4. THE App SHALL permit cleartext traffic to every host, as the KMP_App's network security configuration does, so that the SSO_Screen can load pages from an `http://` Server_URL that the user confirmed.
5. THE App SHALL build with Flutter 3.44.4 (stable channel) and Dart 3.12.2, on the maintainer's machine and in the CI_Workflow.
6. THE App SHALL use Riverpod for app state and dependency injection, go_router for navigation between screens, and freezed with json_serializable for data models.
7. THE App SHALL use a WebView only in the SSO_Screen and the WebView_Host.
8. THE App SHALL show the KMP_App's exact English wording for every UI text that the KMP_App also shows, copied from the KMP_App's `strings.xml` files or, where the KMP_App hard-codes the text, from the KMP_App's Kotlin code.

### Requirement 3: Theme and appearance

**User Story:** As a user, I want the app to follow my theme and color choices, so that the app looks the way I like.

#### Acceptance Criteria

1. WHILE dynamic color is off, THE App SHALL build every screen from Material 3 components colored with the Material 3 tonal-spot color scheme generated from the accent seed.
2. THE Settings_Screen SHALL offer the KMP_App's 11 accent seed presets in the KMP_App's order, with Blue `#3B82F6` first and selected by default, and mark the selected preset.
3. WHERE the device runs Android 12 or later, WHILE dynamic color is on, THE App SHALL build every screen from Material 3 components colored with the color scheme generated from the device's wallpaper colors.
4. WHERE the device runs Android 12 or later, THE Settings_Screen SHALL show a "Use wallpaper colors" switch for dynamic color, which is off by default.
5. WHILE dynamic color is on, THE Settings_Screen SHALL show the accent seed setting as disabled and ignore taps on it.
6. THE Settings_Screen SHALL offer the theme modes System, Light and Dark as a single choice labelled "System default", "Light" and "Dark", with System selected by default.
7. WHILE the theme mode is System, THE App SHALL use the light or dark variant of the color scheme that matches the device's dark theme setting.
8. WHEN the theme mode, the accent seed, the dynamic color setting or the device's dark theme setting changes, THE App SHALL recolor every open screen within 1 second, without a restart and without leaving the current screen.
9. WHEN the App starts, THE App SHALL draw its first frame with the theme mode, accent seed and dynamic color setting held in the Settings_Store.

### Requirement 4: Request rules for an unmodified server

**User Story:** As a user, I want every request to be accepted by a stock LibreChat server, so that the app works with my deployment as it is.

#### Acceptance Criteria

1. THE API_Client SHALL resolve every route path against the Server_URL, keeping the Server_URL's subpath.
2. THE App SHALL send the Browser_User_Agent on every REST, Stream and image request to the Server.
3. THE App SHALL send the Access_Token, the Refresh_Token cookie and the Custom_Headers only on requests whose scheme, host and port equal the Server_Authority, checking each hop of a redirect.
4. THE App SHALL send the Refresh_Token as a `refreshToken` cookie on requests for the Server's `/images/` path, because the Server authenticates that path by cookie only.
5. THE API_Client SHALL wrap the request body of the conversation update, archive, pin and delete routes in the Arg_Envelope.
6. THE API_Client SHALL omit unset optional fields from request bodies, because several Server routes treat `null` as "clear this value".
7. THE API_Client SHALL ignore unknown fields in Server responses and decode unknown enum values to an "unknown" value.
8. FOR ALL data model values, encoding the value to JSON and decoding the JSON SHALL produce an equal value (round-trip property).
9. IF a connection to the Server is not established within 10 seconds, THEN THE API_Client SHALL fail the request with a connection error.
10. IF a REST request other than a file upload or download receives no complete response within 30 seconds, THEN THE API_Client SHALL fail the request with a timeout error.
11. IF a request fails, THEN THE App SHALL show the `message` or `error` text of a JSON error body, or otherwise a message for the failure kind: offline, timeout, server error or Access_Gateway_Error.

### Requirement 5: Custom headers and access gateways

**User Story:** As a user whose server sits behind Cloudflare Access or a similar gateway, I want to add static headers for my server, so that the app gets through the gateway without sending those secrets anywhere else.

#### Acceptance Criteria

1. THE App SHALL offer one Custom_Headers editor, with the KMP_App's copy, for adding, editing and removing name/value rows, with each value masked until the user taps that row's show-value toggle, in the Server_URL_Screen's collapsible Advanced section, which opens expanded when Custom_Headers are stored, and in the "Server connection" dialog, opened from the Security group of the Account section of the Settings_Screen.
2. THE Header_Validator SHALL reject a name/value pair exactly when one of these holds, and report the first one that holds (model-based property): the trimmed name is empty or has a character outside the RFC 7230 token characters (invalid name); the trimmed name is one of the Reserved_Header_Names (reserved name); the trimmed value has a character outside 0x20 to 0x7E other than horizontal tab (invalid value).
3. IF the user submits a URL on the Server_URL_Screen or taps Save in the "Server connection" dialog, and the Header_Validator rejects any row whose name or value is non-empty after trimming, THEN THE App SHALL show the KMP_App's reason text next to each rejected row, keep the typed rows in the open editor, and neither send the `GET /api/config` request nor store the Custom_Headers.
4. THE App SHALL build Custom_Headers from editor rows by trimming surrounding whitespace from each name and value, skipping each row whose name and value are then both empty, and keeping only the last row of each name compared case-insensitively.
5. WHEN the user taps Save in the "Server connection" dialog and the Header_Validator rejects no row, THE App SHALL store the Custom_Headers built from the rows in the Secure_Store and show the KMP_App's saved confirmation.
6. IF the Secure_Store fails to store the Custom_Headers, THEN THE App SHALL show an error saying the headers were not saved, keep the editor open with the typed rows, and keep the previously stored Custom_Headers in effect.
7. THE App SHALL send Custom_Headers on every REST, Stream and image request to the Server_Authority, including the sign-in and refresh routes: the Custom_Headers built from the typed rows on the Server_URL_Screen's `GET /api/config` request, and the stored Custom_Headers on every other request.
8. IF the Custom_Headers include a header named `Cookie` in any letter case and a request carries the Refresh_Token cookie, THEN THE App SHALL send one `Cookie` header made of the Refresh_Token cookie and each `;`-separated segment of the custom value whose cookie name is not exactly `refreshToken`, so that the header holds exactly one `refreshToken` segment for every custom value (invariant).
9. IF a response to a REST, Stream or image request, including a redirect response, carries a `WWW-Authenticate` header line that contains `Cloudflare-Access` in any letter case, THEN THE App SHALL, without following the redirect, retrying the request or reconnecting the Stream, fail the request with an Access_Gateway_Error whose message is the KMP_App's "Your server's access gateway rejected this request. Check Server connection in Settings." while a session exists, or points to the Server_URL_Screen's Advanced section while no session exists.
10. WHEN the App stores new Custom_Headers, THE App SHALL send the new set, and none of the replaced headers, on every request sent after the store completes, without an App restart or a new sign-in.

### Requirement 6: Feature availability and server version

**User Story:** As a user of any LibreChat deployment, I want the app to offer exactly the features my server and role support, so that I never run into controls that cannot work.

#### Acceptance Criteria

1. WHEN the App starts with a stored session, and after each sign-in, THE App SHALL fetch Server_Config and Role_Permissions.
2. IF Server_Config cannot be fetched, THEN THE App SHALL use the last Server_Config that the App stored.
3. THE Feature_Gate SHALL derive each feature's availability only from Server_Config, the Server's endpoint list, Role_Permissions and the Server_Version.
4. THE Feature_Gate SHALL order versions by semantic versioning precedence, with release candidates before the release (0.8.8-rc1 < 0.8.8-rc4 < 0.8.8).
5. WHERE a feature needs a Server route that first shipped in a LibreChat release later than the Server_Version, THE Feature_Gate SHALL hide the feature, using the minimum versions in the table below.
6. WHILE the Server_Version is unknown, THE Feature_Gate SHALL treat the Server as running the Target_Version.
7. IF a Server route behind an offered feature returns HTTP 404, THEN THE App SHALL hide that feature until the App restarts and tell the user that the Server does not support the feature.
8. WHEN the Server_Version belongs to a different major.minor.patch release line than the Target_Version, THE App_Shell SHALL show a version banner that names both versions.
9. WHEN the user chooses "Don't show again" on the version banner, THE App SHALL hide the version banner for that Server_Version on later launches.
10. WHILE the Server_Version is unknown, THE App_Shell SHALL hide the version banner.

| Feature that needs a newer Server route | First LibreChat release with the route |
| --------------------------------------- | -------------------------------------- |
| Chat Projects                           | v0.8.7-rc1                             |
| Conversation pin and unpin              | v0.8.7                                 |
| "Add to chat" quotes                    | v0.8.7                                 |
| Steering                                | v0.8.8-rc1                             |
| Tool favorites                          | v0.8.8-rc1                             |
| Server-side queued turns                | v0.8.8-rc2                             |
| Archive all conversations               | v0.8.8-rc2                             |
| Memory addressing by id                 | v0.8.8-rc2                             |

### Requirement 7: Server URL onboarding

**User Story:** As a new user, I want to point the app at my LibreChat server, so that I can sign in to my server.

#### Acceptance Criteria

1. WHEN the App launches without a stored Server_URL, THE App SHALL open the Server_URL_Screen.
2. WHEN the App launches with a stored Server_URL and no session, THE App SHALL open the Login_Screen.
3. WHEN the user submits a URL that the Server_URL_Normalizer accepts, THE Server_URL_Screen SHALL request `GET /api/config` from the normalized URL, after the confirmation in criterion 4 when the URL uses `http://`, and only when Requirement 5.3 does not block the request.
4. IF the normalized URL uses `http://`, THEN THE Server_URL_Screen SHALL show the KMP_App's cleartext warning dialog and continue only after the user confirms.
5. IF the config request fails or the response body does not decode as a Server_Config, THEN THE Server_URL_Screen SHALL show the failure reason and keep the input for editing.
6. WHEN the config request succeeds, THE App SHALL store the Server_URL and the Custom_Headers and open the Login_Screen.
7. WHEN the user scans a QR code that contains a URL, THE Server_URL_Screen SHALL put the scanned URL into the URL field.
8. WHEN the user chooses "Change server" on the Login_Screen, THE App SHALL open the Server_URL_Screen with the stored URL and Custom_Headers filled in.
9. WHEN the user saves a Server_URL that differs from the stored Server_URL, THE App SHALL clear the Cache and the stored tokens.

### Requirement 8: Server URL normalization

**User Story:** As a user, I want the URL I type to be cleaned up the same way every time, so that small typing differences still reach the same server.

#### Acceptance Criteria

1. THE Server_URL_Normalizer SHALL trim surrounding whitespace from the input, lowercase the scheme and the host, drop user info, and drop a port that equals the scheme's default port (443 for `https`, 80 for `http`).
2. IF the trimmed input contains no `://`, THEN THE Server_URL_Normalizer SHALL prefix the input with `https://`, so `localhost:3080` becomes `https://localhost:3080`.
3. THE Server_URL_Normalizer SHALL drop the query and the fragment, remove every trailing `/` from the path, and keep the rest of the path unchanged, including its letter case.
4. IF the trimmed input is empty, has a scheme other than `http` or `https`, has an empty host, or has a port that is not a whole number from 1 to 65535, THEN THE Server_URL_Normalizer SHALL reject the input and report the first of these reasons that applies.
5. IF the Server_URL_Normalizer rejects the submitted input, THEN THE Server_URL_Screen SHALL show the reason under the URL field, keep the input for editing and send no request.
6. FOR ALL accepted inputs, normalizing the Server_URL_Normalizer's output again SHALL return the same output (idempotence property).

### Requirement 9: Sign-in

**User Story:** As a user, I want to sign in with the method my server allows, so that I can reach my conversations.

#### Acceptance Criteria

1. WHERE Server_Config enables email login, THE Login_Screen SHALL show an identifier field and a password field.
2. WHERE Server_Config enables LDAP with username login, THE Login_Screen SHALL label the identifier field "Username" and send the entered username as the identifier.
3. WHEN the user submits credentials, THE Auth_Service SHALL send the credentials to `POST /api/auth/login`.
4. WHEN a login response carries a `token`, THE Auth_Service SHALL store that Access_Token together with the Refresh_Token from the response's `refreshToken` Set-Cookie header.
5. WHEN the Auth_Service has stored a new session, THE App SHALL open the App_Shell.
6. WHEN a login response reports `twoFAPending` with a `tempToken`, THE App SHALL open the Two_Factor_Screen with that tempToken.
7. IF a login response carries the message `Email not verified.`, THEN THE App SHALL open the Verify_Email_Screen for the entered email.
8. IF login fails for any other reason, THEN THE Login_Screen SHALL show the Server's message and keep the entered identifier.
9. WHERE Server_Config enables social login, THE Login_Screen SHALL show one button for each enabled provider among Google, GitHub, Discord, Facebook, Apple, OpenID and SAML, using the Server_Config label and image for OpenID and SAML when Server_Config provides a label or an image.
10. WHERE Server_Config enables OpenID and sets `openidAutoRedirect`, WHEN the Login_Screen opens for the first time in an App session, THE Login_Screen SHALL start OpenID sign-in.
11. WHERE Server_Config enables registration, THE Login_Screen SHALL link to the Register_Screen.
12. WHERE Server_Config enables password reset, THE Login_Screen SHALL link to the Forgot_Password_Screen.

### Requirement 10: Two-factor sign-in

**User Story:** As a user with two-factor authentication, I want to finish sign-in with my code or a backup code, so that my account stays protected.

#### Acceptance Criteria

1. WHEN the user submits a 6-digit code on the Two_Factor_Screen, THE Auth_Service SHALL send the tempToken and the code to `POST /api/auth/2fa/verify-temp`.
2. WHEN the user submits a code in backup-code mode, THE Auth_Service SHALL send the tempToken and the code as a backup code.
3. WHEN verification succeeds, THE Auth_Service SHALL store the returned Access_Token together with the Refresh_Token from the `refreshToken` Set-Cookie header.
4. IF verification fails, THEN THE Two_Factor_Screen SHALL show the Server's message and keep the user on the Two_Factor_Screen.

### Requirement 11: Registration, password reset, email verification and terms

**User Story:** As a new or locked-out user, I want to register, reset my password, verify my email and accept the terms in the app, so that I don't need a browser for account basics.

#### Acceptance Criteria

1. WHEN the user submits the registration form (name, username, email, password and password confirmation), THE Register_Screen SHALL send the form to `POST /api/auth/register`.
2. IF the password is shorter than Server_Config `minPasswordLength` or differs from the confirmation, THEN THE Register_Screen SHALL show the field error before sending the form.
3. WHEN registration succeeds, THE App SHALL show the Server's message and open the Login_Screen.
4. WHEN the user submits an email on the Forgot_Password_Screen, THE App SHALL send the email to `POST /api/auth/requestPasswordReset` and show the Server's confirmation message.
5. WHEN a password reset response carries a `link`, THE App SHALL open the Reset_Password_Screen with the `token` and `userId` taken from that link.
6. WHEN the user submits a new password and the password confirmation on the Reset_Password_Screen, THE App SHALL send the reset to `POST /api/auth/resetPassword` and open the Login_Screen after success.
7. WHEN the user asks the Verify_Email_Screen to resend the verification email, THE Verify_Email_Screen SHALL call `POST /api/user/verify/resend` and disable resending for 60 seconds.
8. WHERE Server_Config requires acceptance of the terms of service, WHEN `GET /api/user/terms` reports the terms as not accepted after sign-in, THE App SHALL show the Terms_Screen with the Server's terms text.
9. WHEN the user accepts the terms, THE App SHALL call `POST /api/user/terms/accept` and open the App_Shell.
10. WHEN the user declines the terms, THE App SHALL sign the user out.

### Requirement 12: Session, token refresh and sign-out

**User Story:** As a user, I want to stay signed in until my session really ends, so that brief network or gateway trouble never signs me out.

#### Acceptance Criteria

1. THE Auth_Service SHALL store the Access_Token and the Refresh_Token in the Secure_Store.
2. WHEN the App launches with a stored session, THE App SHALL open the App_Shell as the first screen.
3. WHEN a request other than the login, register, refresh and two-factor routes returns HTTP 401, THE Auth_Service SHALL refresh the Access_Token and retry the request once with the new Access_Token.
4. WHILE a refresh is in progress, THE Auth_Service SHALL make each request that receives HTTP 401 wait for that refresh and use the refresh's result, so concurrent 401 responses cause one refresh.
5. THE Auth_Service SHALL send the Refresh_Token to `POST /api/auth/refresh` as the `refreshToken` cookie in the `Cookie` request header.
6. WHEN a refresh response sets a new `refreshToken` cookie, THE Auth_Service SHALL replace the stored Refresh_Token with the new value.
7. IF a refresh response is a LibreChat_Refresh_Rejection, THEN THE Auth_Service SHALL clear the session and report the session as expired.
8. IF a refresh fails in any other way, including a network error, a timeout, HTTP 5xx, an Access_Gateway_Error, a 403 that LibreChat did not author, or a 2xx response without a `token`, THEN THE Auth_Service SHALL keep the session and fail the waiting requests with the refresh error.
9. IF a retried request returns HTTP 401 again, THEN THE Auth_Service SHALL return the 401 response to the caller and keep the session.
10. WHEN the user signs out, THE Auth_Service SHALL call `POST /api/auth/logout` and then clear the session, whether or not the logout call succeeds.
11. WHEN the session is cleared, THE App SHALL delete the Cache contents and keep the Server_URL and the Custom_Headers.

### Requirement 13: Single sign-on

**User Story:** As a user whose server uses Google, GitHub, OpenID or another provider, I want to sign in inside the app, so that I get a normal session without copying tokens.

#### Acceptance Criteria

1. WHEN the user starts a social sign-in for the first time on the device, THE Login_Screen SHALL show the KMP_App's one-time embedded-browser warning and continue after the user acknowledges the warning.
2. WHEN social sign-in starts, THE SSO_Screen SHALL clear every WebView cookie and, after the clear completes, load `{Server_URL}/oauth/{provider}`.
3. THE SSO_Screen SHALL send Chrome for Android's reduced User-Agent string (`Mozilla/5.0 (Linux; Android 10; K) … Chrome/… Mobile Safari/537.36`) from the WebView, so providers that refuse embedded WebViews accept the sign-in.
4. WHEN the WebView is about to leave the Server's OAuth callback page for another Server page, THE SSO_Screen SHALL cancel that navigation, so the Server's web app cannot refresh and rotate the Refresh_Token first.
5. WHEN a page on the Server_Authority finishes loading and the WebView holds a `refreshToken` cookie for the Server_URL, THE SSO_Screen SHALL capture the cookie value, expire the cookie in the WebView, and hand the value to the Auth_Service.
6. WHEN the Auth_Service receives a Refresh_Token from the SSO_Screen, THE Auth_Service SHALL exchange the token through `POST /api/auth/refresh`, keep the rotated Refresh_Token when the response sets one and the captured token otherwise, and load the user from `GET /api/user`.
7. IF the WebView returns from the provider to the Server_Authority and a Server page finishes loading without a `refreshToken` cookie, THEN THE SSO_Screen SHALL show a sign-in failure with a retry action.
8. WHEN the user closes the SSO_Screen, THE App SHALL return to the Login_Screen.

### Requirement 14: App shell

**User Story:** As a user, I want one consistent frame around my chats, so that conversations, tools and server notices are always within reach.

#### Acceptance Criteria

1. WHILE the window width is below 600 dp, THE App_Shell SHALL show the Conversation_List in a modal navigation drawer.
2. WHILE the window width is 600 dp or more, THE App_Shell SHALL show the Conversation_List in a persistent sidebar beside the current screen.
3. THE App_Shell SHALL offer entries for new chat, archived conversations, the Agent_Marketplace, the Prompts_Library, the Files_Manager, the Skills_Screen, the Schedules_Screen and the Settings_Screen, each shown only when the Feature_Gate allows the entry's feature.
4. WHEN `GET /api/banner` returns a banner, THE App_Shell SHALL show the banner's message above the current screen.
5. WHERE a banner is persistable, THE App_Shell SHALL keep the banner visible on every launch for as long as the Server returns the banner.
6. WHEN the user dismisses a banner that is not persistable, THE App_Shell SHALL hide the banner with that banner id on later launches.
7. WHEN the Auth_Service reports the session as expired, THE App_Shell SHALL show a session-expired dialog whose action opens the Login_Screen.
8. WHILE the device has no network connection, THE App_Shell SHALL show an offline indicator.

### Requirement 15: Conversation list

**User Story:** As a user, I want my conversations listed by date and searchable, including offline, so that I can find any chat fast.

#### Acceptance Criteria

1. THE Conversation_List SHALL load conversations from `GET /api/convos` one cursor page at a time, requesting the next page when the user scrolls within 5 rows of the end.
2. THE Conversation_List SHALL group conversations by last update time under Today, Yesterday, Previous 7 Days and Previous 30 Days, followed by one group per month and year.
3. FOR ALL conversation lists and current dates, the grouping SHALL place each conversation in exactly one group and order the groups from newest to oldest (invariant).
4. WHERE pinning is available, THE Conversation_List SHALL show pinned conversations in a Pinned section above the date groups.
5. WHEN the Conversation_List opens, THE Conversation_List SHALL show the cached conversations first and then the Server's first page.
6. WHILE the device has no network connection, THE Conversation_List SHALL show the cached conversations.
7. WHEN the user types in the search field, THE Conversation_List SHALL query `GET /api/convos` with the search text 500 ms after the last keystroke and show the results in place of the grouped list.
8. WHEN the user clears the search field, THE Conversation_List SHALL show the grouped list again.
9. WHERE bookmarks are enabled, THE Conversation_List SHALL show the user's tags as filter chips and filter the list through the Server by the selected tags.
10. WHEN the user pulls to refresh, THE Conversation_List SHALL reload the first page from the Server.

### Requirement 16: Conversation management

**User Story:** As a user, I want to rename, organize, share, archive, delete, export and import conversations, so that my chat history stays tidy.

#### Acceptance Criteria

1. WHEN the user renames a conversation, THE App SHALL send the title to `POST /api/convos/update` and show the new title in the Conversation_List and the Chat_Screen.
2. WHEN the user confirms deletion of a conversation, THE App SHALL call `DELETE /api/convos`, remove the conversation from the Cache, and open a new chat when the deleted conversation was open.
3. WHEN the user archives or unarchives a conversation, THE App SHALL set `isArchived` through `POST /api/convos/archive` and move the conversation between the Conversation_List and the Archived_Screen.
4. THE Archived_Screen SHALL list archived conversations page by page with open, unarchive and delete actions.
5. WHERE pinning is available, WHEN the user pins or unpins a conversation, THE App SHALL call `POST /api/convos/pin` and update the Pinned section.
6. WHEN the user changes a conversation's tags in the tag picker, THE App SHALL save the tags through `PUT /api/tags/convo/{conversationId}`.
7. WHEN the user creates, renames or deletes a tag, THE App SHALL save the change through the `/api/tags` routes.
8. WHEN the user duplicates a conversation, THE App SHALL call `POST /api/convos/duplicate` and open the copy.
9. WHERE Server_Config enables shared links, WHEN the user shares a conversation, THE App SHALL create or reuse the conversation's share link through the `/api/share` routes and offer to copy or share `{Server_URL}/share/{shareId}`.
10. WHEN the user exports a conversation, THE App SHALL let the user choose JSON or Markdown and save the file through the Android document picker.
11. FOR ALL conversations, decoding the App's JSON export of a conversation SHALL produce the same conversation and messages (round-trip property).
12. WHEN the user picks a JSON file to import, THE App SHALL upload the file to `POST /api/convos/import` and then refresh the Conversation_List.
13. IF the import file exceeds Server_Config `conversationImportMaxFileSize` or the Server rejects the import, THEN THE App SHALL show the reason and keep the Conversation_List unchanged.

### Requirement 17: Reading a conversation

**User Story:** As a user, I want to read a conversation with all of its branches, so that I can follow and compare alternative replies.

#### Acceptance Criteria

1. WHEN the user opens a conversation, THE Chat_Screen SHALL show the cached messages first and then the messages from `GET /api/messages/{conversationId}`.
2. WHILE the first load of a conversation is in progress and the Cache holds no messages for the conversation, THE Chat_Screen SHALL show a loading indicator.
3. THE Message_Tree SHALL link messages by `parentMessageId` and treat a message as a root when the message's parent is the Root_Parent_Id or is missing from the conversation.
4. THE Message_Tree SHALL choose the newest Sibling at each level of the Active_Path, unless the user selected another Sibling at that level.
5. FOR ALL message sets, the Active_Path SHALL be a chain that starts at a root, in which the parent of each later message is the message before the later message (invariant).
6. WHERE a displayed message has Siblings, THE Chat_Screen SHALL show an "n/m" navigator with previous and next controls.
7. WHEN the user selects another Sibling, THE Message_Tree SHALL rebuild the Active_Path from that Sibling downward, choosing the newest Sibling at each lower level.
8. WHILE no conversation is open, THE Chat_Screen SHALL show the landing state with a greeting, the selected model's or agent's icon, the Server_Config custom welcome text when set, and the selected agent's conversation starters when the agent has starters.
9. WHEN the user taps a conversation starter, THE Composer SHALL send the starter's text as a message.
10. WHILE auto-scroll is enabled and the user has not scrolled away from the newest message, THE Chat_Screen SHALL keep the newest content in view.
11. WHILE the newest message is out of view, THE Chat_Screen SHALL show a scroll-to-bottom button.

### Requirement 18: Sending and streaming a reply

**User Story:** As a user, I want to see the reply, its reasoning and its tool calls appear live, so that I can follow the model's work as it happens.

#### Acceptance Criteria

1. WHEN the user sends a message, THE Chat_Screen SHALL show the Optimistic_Message before the Server responds.
2. WHEN the user sends a message, THE App SHALL start a Run through `POST /api/agents/chat/{endpoint}`, for every endpoint, carrying the text, a client-generated message id, the parent message id (the Root_Parent_Id in a new conversation), the selected endpoint and model or agent, the attachments, the enabled tools and the model parameters.
3. WHEN the start request returns `{streamId}`, THE Stream_Client SHALL open `GET /api/agents/chat/stream/{streamId}` and read the Stream's events.
4. THE SSE_Parser SHALL parse the WHATWG `text/event-stream` format, including multi-line `data` fields, comment lines and CR, LF and CRLF line endings.
5. FOR ALL event sequences, writing the events with the SSE_Formatter, splitting the bytes into chunks at arbitrary positions and parsing the chunks with the SSE_Parser SHALL yield the original events (round-trip property).
6. WHEN the Stream delivers an event type that the App does not handle, THE Stream_Client SHALL skip the event and continue reading.
7. WHILE a Run streams, THE Chat_Screen SHALL render text deltas, reasoning in a collapsible thinking block, tool calls with each call's progress, attachments and title updates as the events arrive.
8. WHILE a Run streams, THE Chat_Screen SHALL rebuild only the widgets that show the streaming reply for each received event.
9. WHILE a Run has delivered no content yet, THE Chat_Screen SHALL show a waiting indicator in place of the reply.
10. WHEN a `created` event arrives for a new conversation, THE App SHALL move to the conversation's route with the Optimistic_Message and the streaming reply still on screen.
11. WHEN a Final_Frame arrives, THE Chat_Screen SHALL replace the streaming reply with the final messages in one update.
12. WHEN a Final_Frame arrives, THE App SHALL match the Optimistic_Message to the Server's request message by message id or, when the ids differ, by equal parent and equal text, and show only the Server's copy.
13. WHEN a Final_Frame arrives in a conversation that is not temporary, THE App SHALL write the final messages to the Cache.
14. IF the Stream delivers an `error` event, THEN THE Chat_Screen SHALL show the error in the reply and keep the content received before the error.

### Requirement 19: Stream recovery

**User Story:** As a user on a flaky connection, I want a reply to continue after a network drop or after I switch apps, so that I never lose a long answer.

#### Acceptance Criteria

1. IF a Stream ends without a Final_Frame or an `error` event, THEN THE Stream_Client SHALL reconnect to the Stream with `?resume=true`.
2. THE Stream_Client SHALL wait 1, 2, 4, 8 and 8 seconds before reconnect attempts 1 through 5 respectively.
3. WHEN the SSE_Parser yields an event, THE Stream_Client SHALL reset the reconnect attempt count to zero.
4. WHEN a resumed Stream delivers a Sync_Frame, THE Chat_Screen SHALL replace the streaming reply with the Sync_Frame's text, reasoning, tool calls, Pending_Action and pending Steers.
5. IF a resume request returns HTTP 404, THEN THE App SHALL treat the Run as finished and reload the conversation's messages from the Server.
6. IF reconnect attempt 5 fails, THEN THE App SHALL request `GET /api/agents/chat/status/{conversationId}`, resuming the Stream once more when the Run is active and reloading the messages when the Run is not active.
7. IF the status request fails, THEN THE Chat_Screen SHALL show a network error and keep the Partial_Reply.
8. WHEN the App returns to the foreground or the network reconnects while the open conversation has a Run without a Final_Frame and no open Stream, THE App SHALL check the Run status and resume the Stream when the Run is active.
9. WHEN the user opens a conversation, THE App SHALL check the Run status and resume the Stream when a Run is active.

### Requirement 20: Stopping a reply

**User Story:** As a user, I want to stop a reply and keep what was written so far, so that I don't wait for or lose an answer I've seen enough of.

#### Acceptance Criteria

1. WHILE a Run is active, THE Composer SHALL show a Stop control.
2. WHEN the user taps Stop, THE App SHALL send `POST /api/agents/chat/abort` for the conversation and keep reading the Stream.
3. WHEN a Final_Frame with `aborted: true` arrives, THE Chat_Screen SHALL show the Final_Frame's reply content as the stopped reply.
4. IF no Final_Frame arrives within 15 seconds after the abort request, or the abort request fails, THEN THE App SHALL close the Stream and keep the Partial_Reply on screen.
5. WHEN a Final_Frame reports `earlyAbort`, THE App SHALL remove the Optimistic_Message and put the Optimistic_Message's text back into the Composer.
6. IF an aborted Final_Frame has empty response content, has no request message, or has a response message id equal to the request message id followed by one underscore character, THEN THE App SHALL drop the response message from the turn, because the Server saved no reply.
7. WHEN a Run ends through Stop, THE App SHALL skip automatic read-aloud, title generation and the sending of locally queued messages.
8. WHILE a Stop is pending, THE Composer SHALL disable the Stop control.

### Requirement 21: New chat, temporary chat, drafts, model choice and titles

**User Story:** As a user, I want to start chats with the model I want, keep unsent text, and get titles automatically, so that starting and resuming work is effortless.

#### Acceptance Criteria

1. WHEN the user starts a new chat, THE Chat_Screen SHALL open in the landing state with the last used endpoint and model selected.
2. THE Model_Selector SHALL list the Server's endpoints and models from `GET /api/endpoints` and `GET /api/models`, the Server_Config model specs, and the agents available to the user under the agents endpoint.
3. THE Model_Selector SHALL filter the list by a search text and list the user's favorites first.
4. WHERE Server_Config disables the endpoints menu or model selection, THE Model_Selector SHALL hide the disabled choices.
5. WHERE temporary chat is enabled, THE Composer SHALL offer a temporary chat toggle.
6. WHILE the temporary chat toggle is on, THE App SHALL send `isTemporary: true` and keep the conversation out of the Conversation_List and the Cache.
7. WHEN the user leaves a conversation with unsent Composer text, THE App SHALL store the text in the Cache as the conversation's draft.
8. WHEN the user opens a conversation that has a draft, THE Composer SHALL restore the draft.
9. WHEN the user sends a message, THE App SHALL delete the conversation's draft.
10. WHEN the first Run of a new conversation ends with a Final_Frame that is not aborted, THE App SHALL load the title from `GET /api/convos/gen_title/{conversationId}` and show the title in the Chat_Screen and the Conversation_List.
11. WHEN a `title` event arrives, THE App SHALL show the new title.

### Requirement 22: Text, code and math rendering

**User Story:** As a user, I want replies rendered as rich text with code and math, so that answers are easy to read and reuse.

#### Acceptance Criteria

1. THE Message_Renderer SHALL render GitHub-flavored Markdown natively, including headings, emphasis, lists, task lists, blockquotes, links, tables, inline code and horizontal rules.
2. THE Message_Renderer SHALL render fenced code blocks with syntax highlighting, a language label and a copy button that shows a check mark for 3 seconds after copying.
3. THE Message_Renderer SHALL render `$$…$$` and `\[…\]` as block math and `\(…\)` as inline math, using native rendering.
4. THE Message_Renderer SHALL render `$…$` as inline math when the content reads as LaTeX, and as plain text when the content reads as a currency amount.
5. IF a math expression fails to parse, THEN THE Message_Renderer SHALL show the expression's source in a monospace font.
6. WHERE a message carries web search or file citations, THE Message_Renderer SHALL render citation markers that show the cited source on tap.
7. WHEN the user taps a link in a message, THE App SHALL open the link in the external browser.
8. WHILE a Run streams, THE Message_Renderer SHALL show a cursor at the end of the streamed text.
9. THE Message_Renderer SHALL use the font size and the message layout chosen in the Chat section of the Settings_Screen.

### Requirement 23: Tool calls and other content parts

**User Story:** As a user, I want tool calls, images, files and run events shown in a readable form, so that I understand what the model did.

#### Acceptance Criteria

1. THE Message_Renderer SHALL render each tool call as an expandable card that shows the call's arguments and output when expanded.
2. THE Message_Renderer SHALL title a tool call card with the call's `intent` argument when `intent` is the first key of the arguments, and with the tool name otherwise.
3. THE Message_Renderer SHALL render web search calls with the cited sources, file search calls with the matched files, memory calls with the changed memories, and image generation calls with a progress indicator until the image arrives.
4. THE Message_Renderer SHALL render image parts and image attachments inline.
5. WHEN the user taps an image, THE App SHALL open a fullscreen viewer with pinch zoom, pan, save and share.
6. THE Message_Renderer SHALL render file attachments as cards that open or download the file.
7. THE Message_Renderer SHALL show office document attachments with the preview state the Server reports: pending, ready with the preview, or failed.
8. THE Message_Renderer SHALL play audio and video parts inline with play, pause and seek controls.
9. THE Message_Renderer SHALL render `error` parts as error notices, `summary` parts as collapsible context summaries, `agent_update` parts as agent handoff markers, and `steer` parts as user turns at the place where the Steer entered the reply.
10. THE Message_Renderer SHALL fold consecutive reasoning and tool call parts into one collapsible activity group titled by the group's `activity_label` part.
11. WHERE a message has no `activity_label` part, THE Message_Renderer SHALL fold each run of two or more consecutive tool calls into a group and show each reasoning part as a separate block.
12. THE Message_Renderer SHALL show activity groups collapsed, except in the reply that has just finished streaming.
13. THE Message_Renderer SHALL render an answered `ask_user_question` tool call as a record of the question and the chosen answer.
14. WHEN the Message_Renderer meets an unknown part type, THE Message_Renderer SHALL skip that part and render the remaining parts.

### Requirement 24: Artifacts and Mermaid diagrams

**User Story:** As a user, I want HTML, React, SVG and Mermaid output rendered in the app, offline and safely, so that I can use generated documents and diagrams directly.

#### Acceptance Criteria

1. THE Artifact_Parser SHALL find `:::artifact{...}` blocks in assistant text, accepting backtick and tilde fences of three or more characters, unfenced content, quoted, unquoted and valueless attributes, and CRLF line endings.
2. FOR ALL artifacts, writing the artifact as an artifact block and parsing the text with the Artifact_Parser SHALL yield the same identifier, type, title and content (round-trip property).
3. IF an artifact block has no closing `:::`, THEN THE Message_Renderer SHALL render the artifact's source as a code block.
4. THE Message_Renderer SHALL render each complete Artifact as a button that shows the Artifact's type and title and opens the Artifact_Viewer.
5. WHERE the Chat section of the Settings_Screen enables inline display for an artifact type, THE Message_Renderer SHALL show Artifacts of that type inline after the reply has finished streaming.
6. THE WebView_Host SHALL render `text/html`, `application/vnd.code-html`, `image/svg+xml`, `application/vnd.react` and `application/vnd.mermaid` Artifacts, and Mermaid code blocks.
7. THE App SHALL render `text/markdown` and `text/plain` Artifacts natively.
8. THE WebView_Host SHALL load scripts and styles only from the Vendored_Web_Assets bundled in the APK, and allow remote URLs only for images.
9. THE WebView_Host SHALL keep Artifact pages isolated from the App's tokens, the Custom_Headers and the App's files.
10. IF an Artifact page navigates to another URL, THEN THE WebView_Host SHALL open that URL in the external browser.
11. IF a React Artifact imports a module other than the bundled React modules, THEN THE WebView_Host SHALL show an error that names the module.
12. WHERE an Artifact identifier has several versions in the conversation, THE Artifact_Viewer SHALL offer previous and next controls with a "vN/M" indicator.
13. THE Artifact_Viewer SHALL offer a code/preview toggle, a fullscreen mode, copying the source, and sharing the source as a file.
14. IF the WebView fails to render an Artifact, THEN THE Artifact_Viewer SHALL show an error with an action that switches to the code view.
15. THE WebView_Host SHALL render Mermaid diagrams and Artifacts in their dark variant when the App's surface color has a relative luminance below 0.5, and in their light variant otherwise.

### Requirement 25: Message actions

**User Story:** As a user, I want to edit, retry, continue, rate, copy, fork, quote and search messages, so that I can steer the conversation the way I want.

#### Acceptance Criteria

1. WHEN the user edits a user message and submits the edit, THE App SHALL send the edited text as a new Sibling of the original message and show the new branch.
2. WHEN the user regenerates an assistant reply, THE App SHALL start a Run for the same user message and show the new reply as a Sibling of the old reply.
3. WHEN the user edits an assistant reply and chooses Save, THE App SHALL store the new text through `PUT /api/messages/{conversationId}/{messageId}` and show the saved text.
4. WHEN the user edits an assistant reply and chooses Submit, THE App SHALL regenerate the reply from the reply's parent user message with `isEdited: true`.
5. WHEN the user taps Continue on an assistant reply, THE App SHALL start a Run with `isContinued: true` that extends that reply.
6. WHERE feedback is enabled, WHEN the user picks a thumbs-up or thumbs-down rating, THE App SHALL ask for a required reason tag and an optional comment and send `{rating, tag, text}` to `/api/messages/{conversationId}/{messageId}/feedback`.
7. WHEN the user taps the rating that is already selected, THE App SHALL clear the message's feedback on the Server.
8. WHEN the user copies a message, THE App SHALL put the message's text on the clipboard.
9. WHEN the user forks from a message, THE App SHALL offer the KMP_App's fork modes and the split-at-target option with the defaults from the Settings_Screen, call `POST /api/convos/fork`, and open the new conversation.
10. WHERE quoting is available and the endpoint is not an Assistants endpoint, WHEN the user selects text in a reply and chooses "Add to chat", THE Composer SHALL add the selection as a quote chip and send the quotes with the next message.
11. WHEN the user searches within a conversation, THE Chat_Screen SHALL highlight the matches, show the match count, and move between matches with next and previous controls, expanding collapsed content that holds the current match.
12. THE Media_Screen SHALL show the open conversation's images and files in a grid and open an item on tap.
13. WHEN the user taps a message timestamp, THE Chat_Screen SHALL switch that timestamp between relative and absolute time.
14. WHILE a Run streams, THE Chat_Screen SHALL disable the edit, regenerate, continue, branch switching and feedback controls.

### Requirement 26: Attachments and uploads

**User Story:** As a user, I want to attach files, images and photos within my server's limits, so that the model can work with my material.

#### Acceptance Criteria

1. THE Composer SHALL let the user attach files from the system file picker, images from the photo picker, photos from the camera, and files already on the Server through the Files_Manager in picker mode.
2. THE App SHALL read the upload limits (file count, per-file size, total size and accepted types per endpoint) from `GET /api/files/config`.
3. IF an attachment breaks a limit or has a type that the selected endpoint does not accept, THEN THE Composer SHALL reject the attachment and name the limit.
4. FOR ALL attachment sets and limits, the Composer SHALL accept the set exactly when the file count, every file size and the total size are within the limits and every type is accepted (model-based property).
5. WHEN an attached file can be delivered either to the provider or as extracted text, THE Composer SHALL ask the user to choose the delivery before uploading the file.
6. WHEN an attachment is accepted, THE App SHALL upload the file to the Server and show the file's upload progress with a cancel action.
7. WHILE an attachment is uploading, THE Composer SHALL disable sending.
8. WHEN the user removes an attachment before sending, THE Composer SHALL drop the attachment from the message.

### Requirement 27: Tools, parameters, presets, prompt commands and favorites

**User Story:** As a user, I want to pick tools, tune parameters, reuse presets and prompts, and keep favorite models, so that each chat is set up the way I need.

#### Acceptance Criteria

1. THE Composer SHALL offer toggles for web search, code interpreter, file search, artifacts and memory, and a list of MCP servers, each shown only when the Feature_Gate allows the tool for the selected endpoint.
2. WHEN the user sends a message, THE App SHALL include the enabled tools and MCP servers in the Run request.
3. WHERE Server_Config enables parameters, THE Composer SHALL offer a parameters sheet with the KMP_App's parameter set for the selected endpoint, applied to the next Run.
4. WHERE presets are enabled, THE Composer SHALL let the user apply a saved preset, and save the current endpoint, model and parameters as a new preset through `/api/presets`.
5. WHEN the Composer text starts with `/`, THE Composer SHALL list the prompts whose command starts with the typed text.
6. WHEN the user picks a prompt from the `/` list, THE Composer SHALL replace the typed command with the prompt's text.
7. WHEN a picked prompt has fillable `{{variable}}` placeholders, THE App SHALL ask for each variable's value and insert the prompt with the values filled in.
8. THE Prompt_Variable_Parser SHALL leave `{{current_date}}`, `{{current_user}}`, `{{iso_datetime}}` and `{{current_datetime}}` in the text for the Server to fill.
9. FOR ALL templates and value maps, the Prompt_Variable_Parser SHALL replace each fillable placeholder that has a non-blank value, matching names case-insensitively after trimming, and leave every other placeholder unchanged (model-based property).
10. THE Model_Selector SHALL let the user add and remove model and agent favorites, saved through `/api/user/settings/favorites`.

### Requirement 28: Human-in-the-loop pauses

**User Story:** As a user, I want to approve tool calls and answer the agent's questions in the chat, so that agents can pause safely for my input.

#### Acceptance Criteria

1. WHEN an `on_pending_action` event arrives, or a Sync_Frame or status response carries a Pending_Action, THE Chat_Screen SHALL show the Pending_Action card at the end of the unfinished reply.
2. WHERE the Pending_Action is a tool approval, THE Chat_Screen SHALL offer approve, reject, edit-arguments and respond actions for each pending tool call.
3. WHERE the Pending_Action is an ask-user question, THE Chat_Screen SHALL show the question, the question's options as single or multiple choice as the question specifies, a free-text answer field and a Skip action.
4. WHEN the user submits a decision or an answer, THE App SHALL send the decision to `POST /api/agents/chat/resume` and keep reading the open Stream for the continuation.
5. WHEN the user skips a question, THE App SHALL resume the Run with the Server's declined-answer value.
6. WHILE a Pending_Action is shown, THE Chat_Screen SHALL hide the in-progress tool call card of the same call.
7. WHILE a Pending_Action is shown, THE Chat_Screen SHALL keep the Run active with Stop available.
8. IF the resume request fails, THEN THE Chat_Screen SHALL show the error on the Pending_Action card and keep the user's input for a retry.

### Requirement 29: Steering and queued turns

**User Story:** As a user, I want to add to a running reply or line up my next message while the model works, so that I never wait to say what I mean and never lose a message.

#### Acceptance Criteria

1. WHILE a Run is active, THE Composer SHALL keep sending available and route a send to the during-run action chosen in the Settings_Screen (steer or queue), with a menu to pick the other action for one message.
2. WHERE steering is available, WHEN the user steers a text-only message in an existing conversation that is not a Comparison and has no Pending_Action, THE App SHALL send the message to `POST /api/agents/chat/steer` and show the message as a chip above the Composer.
3. WHEN an `on_steer_applied` event arrives, THE Chat_Screen SHALL remove the chip of the applied Steer.
4. WHEN the user cancels a pending Steer, THE App SHALL call `POST /api/agents/chat/steer/cancel` and remove the Steer's chip.
5. IF a steer request fails, or a Final_Frame, abort response or status response returns a Steer as not applied, THEN THE App SHALL move the Steer's text into the queue as a Queued_Turn, once per Steer.
6. WHEN the user steers a message that has attachments, THE App SHALL queue the message as a Queued_Turn.
7. WHEN the user queues a message during a Run, THE Composer SHALL show the Queued_Turn above the Composer with edit and remove actions.
8. WHERE server-side queued turns are available and the conversation uses the agents endpoint, THE App SHALL hand each Queued_Turn to the Server through `POST /api/agents/chat/queued-turns` and remove a Queued_Turn through `DELETE /api/agents/chat/queued-turns/{id}`.
9. WHEN a conversation that uses the agents endpoint opens, or the App returns to the foreground on such a conversation, THE App SHALL show the Server's queued turns from `GET /api/agents/chat/queued-turns`.
10. WHEN a Run ends while the Server holds a Queued_Turn for the conversation, THE App SHALL attach to the Server's next Run for the conversation.
11. WHEN a Run ends with a Final_Frame that is not aborted, THE App SHALL send the oldest locally held Queued_Turn as the next turn.
12. FOR ALL orders of steer failures, Final_Frames, aborts and queue sends, THE App SHALL send each steered or queued text exactly once (model-based property).
13. IF the Server rejects a Queued_Turn, THEN THE App SHALL put the Queued_Turn's text back into the Composer and show the error.

### Requirement 30: Compare models

**User Story:** As a user, I want two models or agents to answer side by side, so that I can compare them and continue with the better answer.

#### Acceptance Criteria

1. WHERE Server_Config enables multi-conversation, THE Composer SHALL let the user add a second model or agent for comparison.
2. WHEN the user sends in comparison mode, THE App SHALL send the second selection as `addedConvo` in the Run request.
3. WHILE a Comparison Run streams, THE Chat_Screen SHALL show two panes and route each delta to the pane of the agent recorded for the delta's run step.
4. THE Chat_Screen SHALL render a saved Comparison turn as two panes by splitting the content parts on `agentId`, where the second agent's ids carry a `____N` suffix.
5. THE Chat_Screen SHALL render each part of a Comparison pane as a standalone part, outside activity groups.
6. WHEN the user continues with one pane's response, THE App SHALL call `POST /api/messages/branch` with that agent's parts and continue the conversation from the new branch.
7. WHEN the user opens a conversation whose latest reply is a Comparison, THE Chat_Screen SHALL restore comparison mode.

### Requirement 31: Context usage, compaction, subagents and traces

**User Story:** As a user of long agent runs, I want to see context usage, compact the context, and inspect subagents and traces, so that I can manage and understand complex runs.

#### Acceptance Criteria

1. WHERE Server_Config enables context usage, THE Chat_Screen SHALL show a context gauge below the app bar, fed by `on_context_usage` events and the limits from `GET /api/endpoints/token-config`.
2. WHERE Server_Config sets `compactionEnabled` to `true`, THE Chat_Screen SHALL offer a Compact action that starts a Run with `compact: true`.
3. WHEN `on_subagent_update` events arrive, THE Chat_Screen SHALL show one progress card per subagent with the subagent's status.
4. WHEN the user opens a subagent card, THE App SHALL load the subagent threads from `GET /api/convos/{conversationId}/subagents` and show the selected thread's messages in a sheet.
5. WHERE Server_Config enables the trace viewer and `GET /api/traces/{conversationId}/availability` reports a trace, THE Chat_Screen SHALL offer a trace viewer that lists the trace records page by page and shows a record's detail on tap.

### Requirement 32: Voice input and read-aloud

**User Story:** As a user, I want to dictate messages and hear replies, on the device or through my server, so that I can chat hands-free.

#### Acceptance Criteria

1. WHERE speech-to-text is enabled in the Settings_Screen, THE Composer SHALL show a microphone control.
2. WHERE the on-device speech engine is selected, WHEN the user taps the microphone, THE Voice_Service SHALL transcribe speech with the Android speech recognizer into the Composer.
3. WHERE the Server speech engine is selected, WHEN the user taps the microphone, THE Voice_Service SHALL record audio, send the recording to `POST /api/files/speech/stt`, and insert the returned text into the Composer.
4. WHEN the user taps Read aloud on a reply, THE Voice_Service SHALL speak the reply with the selected engine: Android text-to-speech, or audio from `POST /api/files/speech/tts/manual` in the voice chosen from `GET /api/files/speech/tts/voices`.
5. WHILE a reply is read aloud, THE Chat_Screen SHALL offer a control that stops the playback.
6. WHERE auto read-aloud is enabled, WHEN a Run ends with a Final_Frame that is not aborted, THE Voice_Service SHALL read the reply aloud.
7. THE Settings_Screen SHALL take the Server's speech defaults from `GET /api/files/speech/config/get`.

### Requirement 33: Agent marketplace and detail

**User Story:** As a user, I want to browse, search and open agents, so that I can find and start chats with the right agent.

#### Acceptance Criteria

1. WHERE the Feature_Gate allows the agent marketplace, THE Agent_Marketplace SHALL list agents 10 per page, requesting the next page when the user scrolls within 3 items of the end.
2. THE Agent_Marketplace SHALL show the categories from `GET /api/agents/categories` as filters, including Top Picks and All.
3. WHEN the user changes the search text or the category, THE Agent_Marketplace SHALL reload from the first page, searching 500 ms after the last keystroke.
4. WHEN the user opens an agent, THE Agent_Detail_Screen SHALL show the agent's avatar, name, description, author, capabilities and tools.
5. THE Agent_Detail_Screen SHALL offer Start chat, Favorite, Copy link, Duplicate, Edit and Delete actions, each shown only when the user's permissions on the agent allow the action.
6. WHEN the user taps Start chat, THE App SHALL open a new chat with the agents endpoint and that agent selected.
7. WHEN the user duplicates an agent, THE App SHALL call `POST /api/agents/{id}/duplicate` and open the copy.
8. WHEN the user confirms deletion of an agent, THE App SHALL call `DELETE /api/agents/{id}` and return to the Agent_Marketplace.

### Requirement 34: Agent editor

**User Story:** As an agent author, I want to build and maintain agents with tools, actions, files, skills and sharing, so that I can tailor agents for myself and my team.

#### Acceptance Criteria

1. THE Agent_Editor SHALL create an agent through `POST /api/agents` and save changes through `PATCH /api/agents/{id}`.
2. THE Agent_Editor SHALL edit the agent's name, description, instructions, category, provider, model and model parameters.
3. WHEN the user picks an avatar image, THE Agent_Editor SHALL upload the image through `POST /api/files/images/agents/{id}/avatar`.
4. THE Agent_Editor SHALL set the agent's capabilities and run settings (artifacts, end after tools, hide sequential outputs and recursion limit) that the Server allows.
5. THE Agent_Editor SHALL offer one searchable picker for built-in capabilities, plugin tools, MCP tools and skills, and list the items already on the agent with remove actions.
6. WHEN the user adds a tool that needs credentials, THE Agent_Editor SHALL ask for the credentials and save the credentials through the Server's tool authentication routes.
7. WHERE tool favorites are available, THE Agent_Editor SHALL let the user star picker items and filter the picker by favorites.
8. THE Agent_Editor SHALL create, edit and delete OpenAPI actions through `/api/agents/actions/{agentId}`, each with a JSON or YAML spec and an authentication setting of none, API key or OAuth.
9. THE OpenAPI_Parser SHALL read the spec as JSON or, when JSON parsing fails, as YAML, take the action domain from `servers[0].url`, and derive one function definition per operation.
10. IF a spec lacks an `openapi` field, a `servers` array or `paths`, or fails to parse, THEN THE Agent_Editor SHALL show the error and keep the action editor open.
11. FOR ALL valid specs, the OpenAPI_Parser SHALL derive the same domain and function definitions from a YAML spec and from the same spec written as JSON (metamorphic property).
12. THE Agent_Editor SHALL attach files for file search and code interpreter, and remove attached files.
13. THE Agent_Editor SHALL configure the agent's skills, subagents and handoff agents.
14. THE Agent_Editor SHALL list the agent's versions from `GET /api/agents/{id}/versions` and revert to a chosen version through `POST /api/agents/{id}/revert`.
15. THE Agent_Editor SHALL edit the agent's sharing permissions through the permissions routes, including a search for users and groups.
16. WHEN the user leaves the Agent_Editor with unsaved changes, THE App SHALL ask for confirmation before discarding the changes.

### Requirement 35: Prompts library

**User Story:** As a user, I want to manage reusable prompts with versions and sharing, so that good prompts are one tap away.

#### Acceptance Criteria

1. WHERE the Feature_Gate allows prompts, THE Prompts_Library SHALL list prompt groups with a search field and filters for category and owner.
2. WHEN the user opens a prompt group, THE Prompts_Library SHALL show the group's production prompt, command and description, with Use, Edit, Share and Delete actions, each shown only when the user's permissions on the group allow the action.
3. WHEN the user saves a new prompt, THE Prompts_Library SHALL create the group, then save the one-line description and the `/` command, and report success only after every request succeeds.
4. WHEN the user saves a changed prompt body, THE Prompts_Library SHALL add the body as a new version through `POST /api/prompts/groups/{groupId}/prompts`, with the prompt nested under `prompt`, and then make that version the production version through `PATCH /api/prompts/{promptId}/tags/production`.
5. THE Prompts_Library SHALL list a group's versions and let the user make a chosen version the production version.
6. THE Prompts_Library SHALL edit a group's sharing permissions through the permissions routes.
7. WHEN the user taps Use, THE App SHALL insert the prompt into the Composer, asking for variable values first when the prompt has fillable variables.
8. WHEN a prompt is created, changed or deleted, THE App SHALL show the change in the Prompts_Library and in the Composer's `/` list the next time each one is shown.

### Requirement 36: Projects

**User Story:** As a user, I want to group conversations into projects, so that related work stays together.

#### Acceptance Criteria

1. WHERE projects are available, THE App_Shell SHALL offer a Chats | Projects switch above the Conversation_List.
2. THE Projects_Screen SHALL list projects and let the user create, rename and delete projects through `/api/projects`.
3. WHEN the user opens a project, THE Projects_Screen SHALL list the project's conversations and offer a new chat inside the project.
4. WHEN the user moves a conversation into or out of a project, THE App SHALL save the assignment through `/api/projects/conversations/{conversationId}`.

### Requirement 37: Files manager

**User Story:** As a user, I want to see and manage the files on my server, so that I can reuse, download or clean up uploads.

#### Acceptance Criteria

1. THE Files_Manager SHALL list the user's files from `GET /api/files` as a grid or a list, as the user chooses.
2. THE Files_Manager SHALL sort the files by name, date or size, and filter the files by type: all, images, documents, audio or video.
3. THE Files_Manager SHALL upload files with progress and cancel, within the limits from `GET /api/files/config`.
4. WHEN the user downloads a file, THE App SHALL fetch the file from the Server and save the file through the Android document picker.
5. WHEN the user taps an image or a PDF file, THE Files_Manager SHALL show an in-app preview.
6. WHEN the user opens a file that the App cannot preview, THE App SHALL offer to open the file with another app.
7. WHILE multi-select mode is on, THE Files_Manager SHALL delete the selected files with one `DELETE /api/files` request after the user confirms.
8. WHERE the Files_Manager runs in picker mode, THE Files_Manager SHALL return the selected files to the Composer as attachments.

### Requirement 38: Skills

**User Story:** As a user, I want to import, edit, share and toggle skills, so that agents can use the procedures I rely on.

#### Acceptance Criteria

1. WHERE the Feature_Gate allows skills, THE Skills_Screen SHALL list the user's skills.
2. WHEN the user imports a skill file, THE App SHALL upload the file to `POST /api/skills/import`.
3. IF a skill import fails, THEN THE Skills_Screen SHALL show the Server's failure details.
4. THE Skills_Screen SHALL show a skill's details and toggle whether the skill is active for the user through `/api/user/settings/skills/active`.
5. THE Skills_Screen SHALL create and edit skills, manage a skill's files, and edit a skill's sharing permissions.
6. WHEN the user confirms deletion of a skill, THE App SHALL delete the skill through `DELETE /api/skills/{id}`.

### Requirement 39: Schedules

**User Story:** As a user, I want to schedule recurring agent chats, so that routine work runs without me.

#### Acceptance Criteria

1. WHERE Role_Permissions grant schedule use and Server_Config `interface.schedules` is `true` or an object whose `use` is not `false`, THE App_Shell SHALL show the Schedules entry, treating an absent value as disabled.
2. THE Schedules_Screen SHALL list schedules with an enable toggle and Run now and Delete actions.
3. WHERE Role_Permissions grant schedule creation, THE Schedules_Screen SHALL offer creating and editing schedules.
4. THE Schedules_Screen SHALL let the user set a schedule's prompt, agent, project and cadence.
5. IF the chosen cadence is shorter than the Server's minimum interval, THEN THE Schedules_Screen SHALL reject the cadence before submitting.
6. WHILE the user has the Server's maximum number of schedules, THE Schedules_Screen SHALL hide the Create action.
7. WHEN the user taps Run now, THE App SHALL call `POST /api/schedules/{id}/run` and show the result.

### Requirement 40: General, chat and about settings

**User Story:** As a user, I want to adjust how the app looks and how chats behave, so that the app fits the way I work.

#### Acceptance Criteria

1. THE Settings_Screen SHALL group settings into General, Chat, Data and Account sections, plus entries for API keys, provider keys, favorites, MCP servers, memories, presets, shared links and role skills.
2. THE Settings_Screen SHALL contain the theme mode, accent seed and dynamic color settings in the General section.
3. THE Settings_Screen SHALL contain font size, message layout, auto-scroll, dismiss keyboard on send, during-run action, artifact display, `/` commands, speech, fork defaults and memory personalization in the Chat section.
4. WHEN the user changes a Chat setting, THE App SHALL apply the change to open screens without a restart.
5. THE Settings_Store SHALL keep every General and Chat setting across App restarts.
6. WHERE dismiss keyboard on send is enabled, WHEN the user sends a message, THE Composer SHALL close the on-screen keyboard.
7. WHERE `/` commands are disabled, THE Composer SHALL treat a leading `/` as plain text.
8. WHEN the user changes the memory personalization setting, THE App SHALL save the choice through `PATCH /api/memories/preferences`.
9. THE Settings_Screen SHALL show an About section with the App version, the Server_URL, the Server_Version and, when Server_Config provides one, the help link.

### Requirement 41: Data settings

**User Story:** As a user, I want bulk data controls and diagnostics, so that I can manage my history and report problems.

#### Acceptance Criteria

1. WHERE archiving everything is available, WHEN the user confirms "Archive all", THE App SHALL call `POST /api/convos/archive/all`, report the archived count, and mark the cached conversations as archived.
2. WHEN the user confirms "Delete all conversations", THE App SHALL call `DELETE /api/convos/all` and remove the cached conversations.
3. WHEN the user confirms "Revoke all keys", THE App SHALL delete all of the user's provider keys through `/api/keys`.
4. WHEN the user taps "Clear cache", THE App SHALL delete the cached conversations, messages and images, and keep the session, the drafts and the settings.
5. WHEN the user exports diagnostic logs, THE App SHALL share the Diagnostic_Log as a text file through the Android share sheet.
6. THE Settings_Screen SHALL list the user's shared links page by page with open, copy and delete actions.

### Requirement 42: Account settings

**User Story:** As a user, I want to manage my profile, balance and two-factor security, so that my account stays under my control.

#### Acceptance Criteria

1. THE Settings_Screen SHALL show the user's name, username, email and avatar from `GET /api/user` in the Account section.
2. WHEN the user picks a new avatar image, THE App SHALL upload the image as the user's avatar and show the new avatar.
3. WHERE Server_Config enables balance, THE Settings_Screen SHALL show the token balance from `GET /api/balance` in the Account section.
4. WHEN the user enables two-factor authentication, THE App SHALL show the setup secret as a QR code and as text, show the backup codes, and finish setup through the Server's `/api/auth/2fa/` routes after the user confirms with a valid code.
5. WHEN the user disables two-factor authentication, THE App SHALL require a current code or a backup code.
6. WHEN the user regenerates backup codes, THE App SHALL show the new codes with copy and save actions.
7. WHERE Server_Config allows account deletion, WHEN the user confirms deletion, THE App SHALL call `DELETE /api/user/delete`, including a two-factor or backup code when two-factor authentication is on, and then clear the session.
8. THE Settings_Screen SHALL offer Sign out in the Account section.

### Requirement 43: Keys, favorites, MCP servers, memories, presets and role skills

**User Story:** As a user, I want to manage keys, MCP servers, memories and presets in the app, so that I don't need the web app for configuration.

#### Acceptance Criteria

1. WHERE the Feature_Gate allows remote agents, THE Settings_Screen SHALL list, create and delete the user's API keys through `/api/api-keys`, showing a new key's value with a copy action in the creation dialog, because the Server returns the value only once.
2. THE Settings_Screen SHALL list the endpoints that take user-provided keys and let the user set a key with an expiry, or delete the key, through `/api/keys`.
3. THE Settings_Screen SHALL list the user's model and agent favorites with remove actions.
4. WHERE the Feature_Gate allows MCP servers, THE Settings_Screen SHALL list the MCP servers with each server's connection status from `GET /api/mcp/connection/status`.
5. WHERE Role_Permissions allow creating MCP servers, THE Settings_Screen SHALL create, edit and delete MCP servers of the SSE and streamable HTTP types.
6. WHEN the user reinitializes an MCP server, THE App SHALL call `POST /api/mcp/{serverName}/reinitialize` and show the outcome: connected, connecting, or OAuth required.
7. WHEN a reinitialize response requires OAuth, THE App SHALL show a consent dialog and open the OAuth URL in the external browser only after the user confirms.
8. THE Settings_Screen SHALL list an MCP server's tools from `GET /api/mcp/tools`.
9. WHERE the Feature_Gate allows memories, THE Settings_Screen SHALL list, create, edit and delete memories, keeping a memory's key read-only after creation.
10. WHERE memory addressing by id is available, THE App SHALL update and delete memories through `/api/memories/id/{id}`, and through `/api/memories/{key}` otherwise.
11. THE Settings_Screen SHALL list presets and delete a preset through `POST /api/presets/delete`.
12. WHERE the user's role is ADMIN, THE Settings_Screen SHALL let the user choose which skills each role may use through `/api/roles/{role}/skills`.

### Requirement 44: Deep links, sharing and permissions

**User Story:** As an Android user, I want links and shared content to open in the app, so that the app fits into the rest of my phone.

#### Acceptance Criteria

1. THE App SHALL register the `librechat` URL scheme and run as a single-task activity, so a link or a share reaches the running instance.
2. WHEN a `librechat://conversation/{id}` link arrives, THE Deep_Link_Handler SHALL open that conversation.
3. WHEN a `librechat://model?endpoint={endpoint}&model={model}` link arrives, THE Deep_Link_Handler SHALL open a new chat with that endpoint and model selected.
4. WHEN a `librechat://oauth` link arrives, THE Deep_Link_Handler SHALL bring the App to the foreground and keep the current screen.
5. WHILE no session exists, WHEN a conversation or model link arrives, THE Deep_Link_Handler SHALL open the Login_Screen and open the link's target after sign-in.
6. IF a link is malformed or names an unknown target, THEN THE Deep_Link_Handler SHALL open a new chat and show a message that the link could not be opened.
7. WHEN another app shares text, one or more images, or one or more files with the App, THE Share_Handler SHALL open a new chat with the text in the Composer and the files attached.
8. WHILE no session exists, WHEN content is shared with the App, THE Share_Handler SHALL keep the content until sign-in and then attach the content to a new chat.
9. THE App SHALL declare the INTERNET, ACCESS_NETWORK_STATE, RECORD_AUDIO and CAMERA permissions.
10. WHEN a feature first needs the microphone or the camera, THE App SHALL request the matching runtime permission.
11. IF the user denies a runtime permission, THEN THE App SHALL explain which feature needs the permission and keep the rest of the screen usable.

### Requirement 45: Offline cache

**User Story:** As a user, I want recent conversations available without a network, so that I can read them anywhere.

#### Acceptance Criteria

1. THE Cache SHALL store the conversation list, the messages of opened conversations and the Composer drafts.
2. WHEN the App shows data that the Cache holds, THE App SHALL show the cached copy first, fetch the Server's copy, and replace the cached copy with the Server's copy.
3. IF a fetch fails, THEN THE App SHALL keep the cached copy on screen and show the error separately.
4. WHEN an App update changes the Cache schema version, THE App SHALL rebuild the Cache.

### Requirement 46: Security and privacy

**User Story:** As a user, I want my credentials and conversations protected on the device, so that using the app does not expose my account.

#### Acceptance Criteria

1. THE App SHALL keep the Access_Token, the Refresh_Token and the Custom_Headers only in the Secure_Store.
2. THE App SHALL validate TLS certificates only against the Android system trust store.
3. THE Diagnostic_Log SHALL exclude tokens, cookie values, Custom_Headers values, passwords and message content.
4. THE Diagnostic_Log SHALL keep at most the newest 1 MB of entries.

### Requirement 47: Accessibility

**User Story:** As a user who relies on accessibility features, I want the app to work with TalkBack and large text, so that I can use the app fully.

#### Acceptance Criteria

1. THE App SHALL give every icon-only control a semantic label.
2. THE App SHALL size every tappable control at 48 by 48 dp or larger.
3. THE App SHALL render body text with a contrast ratio of at least 4.5:1 in the light and dark themes.
4. THE App SHALL scale text with the system font size setting.

### Requirement 48: Release readiness and parity

**User Story:** As the maintainer, I want a verified release build and a parity record, so that the Flutter app can replace the KMP app with confidence.

#### Acceptance Criteria

1. THE Build SHALL produce a release APK with R8 code shrinking and resource shrinking enabled.
2. THE Build SHALL sign the release APK with the debug key.
3. THE Build SHALL bundle copies of the Vendored_Web_Assets that the App uses.
4. THE CI_Workflow SHALL run on pushes and pull requests that change `librechat_flutter/`, the Vendored_Web_Assets or the CI_Workflow file.
5. THE CI_Workflow SHALL resolve dependencies, run code generation, run `flutter analyze` and `flutter test`, and build the release APK, failing on the first error.
6. THE CI_Workflow SHALL fail when a bundled web asset differs from the KMP_App file that the asset copies.
7. THE release APK SHALL complete the smoke flow (onboarding, sign-in, opening a conversation, streaming a reply and stopping a reply) on an Android 8.0 (API 26) device and on a device at the App's targetSdk.
8. THE Parity_Checklist SHALL list every KMP_App screen and feature with the item's status in the App: ported, deferred with the deferral named, or dropped with the reason.
9. WHEN the Rewrite is declared feature-complete, THE Parity_Checklist SHALL show every in-scope item as ported.
