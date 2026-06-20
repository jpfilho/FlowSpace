/// FlowSpace — Supabase Configuration
abstract class SupabaseConfig {
  /// Local Supabase URL (running on this machine via Docker)
  static const String url = 'http://2.24.200.178:8001';

  /// Anon key for local Supabase instance
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0'
      '.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE';

  /// Storage bucket for user avatars
  static const String avatarsBucket = 'flowspace-avatars';

  /// Storage bucket for task/project attachments
  static const String attachmentsBucket = 'flowspace-attachments';
}
