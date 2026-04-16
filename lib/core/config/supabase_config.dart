/// FlowSpace — Supabase Configuration
abstract class SupabaseConfig {
  /// Local Supabase URL (running on this machine via Docker)
  static const String url = 'http://localhost:54321';

  /// Anon key for local Supabase instance
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9'
      '.CRFA0NiK7kyqd918Os5P6q2nd23OfmoxKSmUMOuNOrE';

  /// Storage bucket for user avatars
  static const String avatarsBucket = 'flowspace-avatars';

  /// Storage bucket for task/project attachments
  static const String attachmentsBucket = 'flowspace-attachments';
}
