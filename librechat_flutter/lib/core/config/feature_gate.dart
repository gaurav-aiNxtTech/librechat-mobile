/// A Server feature the Feature_Gate can hide (design Feature_Gate table).
///
/// API calls behind a feature pass it to `ApiClient.send(feature:)`, so a
/// route the Server lacks marks it missing (Req 6.7). `FeatureGates` and
/// `featureGatesProvider` join this file with Task 7.2.
enum Feature {
  // Server_Config `interface.<feature>` plus the Role_Permissions USE bit.
  prompts,
  bookmarks,
  memories,
  mcpServers,
  skills,
  temporaryChat,

  /// Comparison (Compare models).
  multiConvo,
  webSearch,
  runCode,
  fileSearch,
  agents,
  marketplace,
  schedules,
  sharedLinks,
  apiKeys,

  // Server_Config only.
  presets,
  parameters,
  endpointsMenu,
  modelSelect,
  feedback,
  contextUsage,
  traceViewer,
  balance,

  // Minimum Server_Version only.
  projects,
  pin,
  quotes,
  steering,
  toolFavorites,
  serverQueue,
  archiveAll,
  memoryById,
}
