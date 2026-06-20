/// FlowSpace — Supabase Configuration
abstract class SupabaseConfig {
  /// Local Supabase URL (running on this machine via Docker)
  static const String url = 'http://2.24.200.178:8001';

  /// Anon key for local Supabase instance
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc2MjA4NTUzLCJleHAiOjIwOTE1NjE1NTN9'
      '.8zAtbd1xAy_4MQ_Sm5pbkEG209lFwW9jn9aQPay1wSg';

  /// Storage bucket for user avatars
  static const String avatarsBucket = 'flowspace-avatars';

  /// Storage bucket for task/project attachments
  static const String attachmentsBucket = 'flowspace-attachments';
}
