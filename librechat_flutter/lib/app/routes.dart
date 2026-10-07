/// Route paths for go_router. Mirrors the KMP `*Route : NavKey` sealed interfaces
/// (feature/*/navigation/*Navigation.kt) as URL paths.
abstract final class Routes {
  // Auth (KMP AuthRoute)
  static const serverUrl = '/server-url';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const twoFactor = '/two-factor';
  static const verifyEmail = '/verify-email';
  static const terms = '/terms';
  static const ssoLogin = '/sso';

  // Chat (KMP ChatRoute)
  static const newChat = '/chat';
  static String chat(String conversationId) =>
      '/chat/c/${Uri.encodeComponent(conversationId)}';
  static const promptsLibrary = '/prompts';
  static const promptEditor = '/prompts/edit';
  static String promptDetail(String groupId) =>
      '/prompts/g/${Uri.encodeComponent(groupId)}';
  static String conversationMedia(String conversationId) =>
      '/chat/c/${Uri.encodeComponent(conversationId)}/media';
  static const artifactFullscreen = '/artifact';

  // Conversations (KMP ConversationsRoute)
  static const archivedConversations = '/conversations/archived';
  static const projects = '/projects';
  static String projectChats(String projectId) =>
      '/projects/${Uri.encodeComponent(projectId)}';

  // Agents (KMP AgentsRoute)
  static const agentMarketplace = '/agents';
  static String agentDetail(String agentId) =>
      '/agents/a/${Uri.encodeComponent(agentId)}';
  static const agentCreate = '/agents/new';
  static String agentEdit(String agentId) =>
      '/agents/a/${Uri.encodeComponent(agentId)}/edit';

  // Files (KMP FilesRoute)
  static const files = '/files';

  // Schedules (KMP SchedulesRoute)
  static const schedules = '/schedules';
  static const scheduleEditor = '/schedules/edit';

  // Skills (KMP SkillsRoute)
  static const skills = '/skills';
  static String skillDetail(String skillId) =>
      '/skills/s/${Uri.encodeComponent(skillId)}';
  static const skillEditor = '/skills/edit';

  // Settings (KMP SettingsRoute)
  static const settings = '/settings';
  static const settingsGeneral = '/settings/general';
  static const settingsChat = '/settings/chat';
  static const settingsData = '/settings/data';
  static const settingsAccount = '/settings/account';
  static const settingsApiKeys = '/settings/api-keys';
  static const settingsProviderKeys = '/settings/provider-keys';
  static const settingsFavorites = '/settings/favorites';
  static const settingsMcp = '/settings/mcp';
  static const settingsMemories = '/settings/memories';
  static const settingsPresets = '/settings/presets';
  static const settingsRoleSkills = '/settings/role-skills';
  static const settingsSharedLinks = '/settings/shared-links';
}
