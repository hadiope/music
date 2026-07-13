/// App-wide constants. EDIT these two values with your own Supabase project keys,
/// and set your Telegram channel link.
class AppConstants {
  // === Supabase (get these from supabase.com -> Project Settings -> API) ===
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // === Your Telegram channel (change this!) ===
  static const String telegramChannel = 'https://t.me/YourChannel';

  // Storage bucket name for audio + covers
  static const String musicBucket = 'music';
  static const String coversBucket = 'covers';
}
