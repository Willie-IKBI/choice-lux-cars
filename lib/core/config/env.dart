/// Environment configuration for secure API keys and URLs
///
/// These values are loaded from --dart-define flags at build time
/// to avoid hardcoding sensitive information in the source code.
class Env {
  /// Supabase configuration
  /// Production Supabase instance
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hgqrbekphumdlsifuamq.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhncXJiZWtwaHVtZGxzaWZ1YW1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc1MTc2NjgsImV4cCI6MjA0MzA5MzY2OH0.zXwuDm3KzLHiF31CsDIsHrrlYnjCweqnNjFZ90AiK1I',
  );

  /// Firebase configuration
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const firebaseVapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
  );
}
