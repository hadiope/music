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
  static String get language => _lang == 'en' ? 'Language' : 'زبان';
  static String get settings => _lang == 'en' ? 'Settings' : 'تنظیمات';

  // auth / guest
  static String get continueAsGuest => _lang == 'en' ? 'Continue as guest' : 'ورود به عنوان مهمان';
  static String get signIn => _lang == 'en' ? 'Sign in' : 'ورود';
  static String get signUp => _lang == 'en' ? 'Sign up' : 'ثبت‌نام';

  // player
  static String get lyrics => _lang == 'en' ? 'Lyrics' : 'متن آهنگ';
  static String get noLyrics => _lang == 'en' ? 'No lyrics added for this song.' : 'متن آهنگی برای این آهنگ ثبت نشده است.';
  static String get nowPlayingTitle => _lang == 'en' ? 'Now Playing' : 'در حال پخش';
  static String get newReleases => _lang == 'en' ? 'New releases' : 'تازه‌ها';
  static String get popular => _lang == 'en' ? 'Popular' : 'محبوب‌ها';
  static String get noSongPlaying => _lang == 'en' ? 'Nothing is playing' : 'آهنگی پخش نمی‌شود';
  static String get noPlaylist => _lang == 'en' ? 'No songs yet, add from above' : 'آهنگی ندارد، از بالا اضافه کن';
  static String get addFromApp => _lang == 'en' ? 'From app' : 'از برنامه';
  static String get pickCategoryOrSearch => _lang == 'en' ? 'Pick a category or search' : 'یک دسته‌بندی انتخاب کن یا جستجو کن';
  static String get deviceSong => _lang == 'en' ? 'Device song' : 'آهنگ گوشی';
  static String get playing => _lang == 'en' ? 'Playing' : 'در حال پخش';
  static String get setupTitle => _lang == 'en' ? 'Iranian Sedà' : 'Iranian Sedà';
  static String get setupBody => _lang == 'en'
      ? 'App installed successfully ✅\n\nTo activate songs and sign-in,\nadd your Supabase keys in\nlib/core/constants.dart\nand rebuild.'
      : 'اپ با موفقیت نصب شد ✅\n\nبرای فعال شدن آهنگ‌ها و ورود،\nباید اطلاعات Supabase را در فایل\nlib/core/constants.dart وارد کنی\nو دوباره build بگیری.';
  static String get noPlaylists => _lang == 'en' ? "You have no playlists" : 'پلی‌لیستی نداری';
  static String get createFirstPlaylist => _lang == 'en' ? 'Create your first playlist' : 'بساز اولین پلی‌لیست';
  static String get newPlaylist => _lang == 'en' ? 'New playlist' : 'پلی‌لیست جدید';
  static String get playlistName => _lang == 'en' ? 'Playlist name' : 'اسم پلی‌لیست';
  static String get cancel => _lang == 'en' ? 'Cancel' : 'لغو';
  static String get create => _lang == 'en' ? 'Create' : 'بساز';
  static String get displayName => _lang == 'en' ? 'Display name' : 'نام نمایشی';
  static String get nameFamily => _lang == 'en' ? 'Name and family' : 'نام و نام خانوادگی';
  static String get changePassTitle => _lang == 'en' ? 'Change password' : 'تغییر رمز عبور';
  static String get newPassHint => _lang == 'en' ? 'New password (min 6 chars)' : 'رمز عبور جدید (حداقل ۶ کاراکتر)';
  static String get darkTheme => _lang == 'en' ? 'Dark theme' : 'تم تیره';
  static String get about => _lang == 'en' ? 'About Iranian Sedà' : 'درباره Iranian Sedà';
  static String get telegramChannel => _lang == 'en' ? 'Our Telegram channel' : 'کانال تلگرام ما';
  static String get joinTelegram => _lang == 'en' ? 'Join to hear about new songs' : 'عضو شو و از آهنگای جدید باخبر شو';
  static String get guest => _lang == 'en' ? 'Guest' : 'مهمان';
  static String get user => _lang == 'en' ? 'User' : 'کاربر';
  static String get nameSaved => _lang == 'en' ? 'Name saved' : 'نام با موفقیت ذخیره شد';
  static String get passChanged => _lang == 'en' ? 'Password changed' : 'رمز عبور با موفقیت تغییر کرد';
  static String get passMin => _lang == 'en' ? 'Password must be at least 6 characters' : 'رمز جدید حداقل ۶ کاراکتر باشد';
  static String get profileSettings => _lang == 'en' ? 'Profile & Settings' : 'پروفایل و تنظیمات';
  static String get signOut => _lang == 'en' ? 'Sign out' : 'خروج از حساب';
}
