// ignore_for_file: avoid_classes_with_only_static_members

/// Centralized, translatable string table.
/// Usage: T.home  →  current locale string (fa / en)
class T {
  static String _lang = 'fa';

  static void setLocale(String code) => _lang = code;

  static String get lang => _lang;

  // navigation
  static String get home => _lang == 'en' ? 'Home' : 'خانه';
  static String get search => _lang == 'en' ? 'Search' : 'جستجو';
  static String get library => _lang == 'en' ? 'Library' : 'کتابخانه';
  static String get profile => _lang == 'en' ? 'Profile' : 'پروفایل';
  static String get categories => _lang == 'en' ? 'Categories' : 'دسته‌بندی‌ها';
  static String get nowPlaying => _lang == 'en' ? 'Now Playing' : 'در حال پخش';
  static String get liked => _lang == 'en' ? 'Liked' : 'پسندیده';
  static String get playlists => _lang == 'en' ? 'Playlists' : 'پلی‌لیست‌ها';

  // common
  static String get noResults => _lang == 'en' ? 'Nothing found' : 'نتیجه‌ای یافت نشد';
  static String get addFromDevice => _lang == 'en' ? 'From device' : 'از گوشی';
  static String get localFiles => _lang == 'en' ? 'Local files' : 'فایل‌های گوشی';
  static String get sharePlaylist => _lang == 'en' ? 'Share playlist' : 'اشتراک‌گذاری پلی‌لیست';
  static String get settings => _lang == 'en' ? 'Settings' : 'تنظیمات';
  static String get language => _lang == 'en' ? 'Language' : 'زبان';

  // auth / guest
  static String get continueAsGuest => _lang == 'en' ? 'Continue as guest' : 'ورود به عنوان مهمان';
  static String get signIn => _lang == 'en' ? 'Sign in' : 'ورود';
  static String get signUp => _lang == 'en' ? 'Sign up' : 'ثبت‌نام';

  // player
  static String get lyrics => _lang == 'en' ? 'Lyrics' : 'متن آهنگ';
  static String get noLyrics => _lang == 'en' ? 'No lyrics added for this song.' : 'متن آهنگی برای این آهنگ ثبت نشده است.';
}
