/// App-wide constants. EDIT these two values with your own Supabase project keys,
/// and set your Telegram channel link.
class AppConstants {
  // === Supabase (get these from supabase.com -> Project Settings -> API) ===
  static const String supabaseUrl = 'https://xhpglphhbchejhciepcr.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_ODyiDbPZyJY6sxZUMQ4F0Q_USMA1Nex';

  // === Your Telegram channel (change this!) ===
  static const String telegramChannel = 'https://t.me/thetextstory';

  // Storage bucket name for audio + covers
  static const String musicBucket = 'music';
  static const String coversBucket = 'covers';
}
