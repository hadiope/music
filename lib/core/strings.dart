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
  static String get myMusic => _lang == 'en' ? 'My Music' : 'آهنگ‌های من';
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
  static String get signInToAccount => _lang == 'en' ? 'Sign in to your account' : 'ورود به حساب کاربری';
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
  static String get setupTitle => _lang == 'en' ? 'Iran Seda' : 'Iran Seda';
  static String get setupBody => _lang == 'en'
      ? 'App installed successfully ✅\n\nTo activate songs and sign-in,\nadd your Supabase keys in\nlib/core/constants.dart\nand rebuild.'
      : 'اپ با موفقیت نصب شد ✅\n\nبرای فعال شدن آهنگ‌ها و ورود،\nباید اطلاعات Supabase را در فایل\nlib/core/constants.dart وارد کنی\nو دوباره build بگیری.';
  static String get noPlaylists => _lang == 'en' ? "You have no playlists" : 'پلی‌لیستی نداری';
  static String get createFirstPlaylist => _lang == 'en' ? 'Create your first playlist' : 'بساز اولین پلی‌لیست';
  static String get guestPlaylistBlocked => _lang == 'en'
      ? 'You need to sign in to create playlists'
      : 'برای ساخت پلی‌لیست باید وارد حساب کاربری شوید';
  static String get newPlaylist => _lang == 'en' ? 'New playlist' : 'پلی‌لیست جدید';
  static String get playlistName => _lang == 'en' ? 'Playlist name' : 'اسم پلی‌لیست';
  static String get cancel => _lang == 'en' ? 'Cancel' : 'لغو';
  static String get create => _lang == 'en' ? 'Create' : 'بساز';
  static String get displayName => _lang == 'en' ? 'Display name' : 'نام نمایشی';
  static String get nameFamily => _lang == 'en' ? 'Name and family' : 'نام و نام خانوادگی';
  static String get changePassTitle => _lang == 'en' ? 'Change password' : 'تغییر رمز عبور';
  static String get newPassHint => _lang == 'en' ? 'New password (min 6 chars)' : 'رمز عبور جدید (حداقل ۶ کاراکتر)';
  static String get darkTheme => _lang == 'en' ? 'Dark theme' : 'تم تیره';
  static String get about => _lang == 'en' ? 'About Iran Seda' : 'درباره Iran Seda';
  static String get telegramChannel => _lang == 'en' ? 'Our Telegram channel' : 'کانال تلگرام ما';
  static String get joinTelegram => _lang == 'en' ? 'Join to hear about new songs' : 'عضو شو و از آهنگای جدید باخبر شو';
  static String get guest => _lang == 'en' ? 'Guest' : 'مهمان';
  static String get user => _lang == 'en' ? 'User' : 'کاربر';
  static String get nameSaved => _lang == 'en' ? 'Name saved' : 'نام با موفقیت ذخیره شد';
  static String get passChanged => _lang == 'en' ? 'Password changed' : 'رمز عبور با موفقیت تغییر کرد';
  static String get passMin => _lang == 'en' ? 'Password must be at least 6 characters' : 'رمز جدید حداقل ۶ کاراکتر باشد';
  static String get profileSettings => _lang == 'en' ? 'Profile & Settings' : 'پروفایل و تنظیمات';
  static String get signOut => _lang == 'en' ? 'Sign out' : 'خروج از حساب';

  // auth screen
  static String get loginHint => _lang == 'en' ? 'Sign in to your account' : 'وارد حساب کاربری خود شوید';
  static String get signUpHint => _lang == 'en' ? 'Create your new account' : 'حساب جدید خود را بسازید';
  static String get googleSignIn => _lang == 'en' ? 'Sign in with Google' : 'ورود با گوگل';
  static String get guestSignIn => _lang == 'en' ? 'Continue as guest' : 'ورود به عنوان مهمان';
  static String get noAccount => _lang == 'en' ? "Don't have an account? Create one 🎵" : 'حساب نداری؟ همین‌جا بساز 🎵';
  static String get hasAccount => _lang == 'en' ? 'Already registered? Sign in' : 'قبلاً ثبت‌نام کردی؟ وارد شو';

  // errors / generic
  static String get errorPrefix => _lang == 'en' ? 'Error: ' : 'خطا: ';
  static String get noSongsInGenre => _lang == 'en' ? 'No songs in this category yet 🎵' : 'هنوز آهنگی در این دسته نیست 🎵';
  static String get changePassBtn => _lang == 'en' ? 'Change password' : 'تغییر رمز عبور';
  static String get deviceSongsTitle => _lang == 'en' ? 'Device music' : 'موزیک گوشی';
  static String get storagePermissionRequired => _lang == 'en'
      ? 'Storage permission is required to read device songs.'
      : 'برای خوندن آهنگ‌های گوشی، دسترسی حافظه لازمه.';
  static String get grantPermission => _lang == 'en' ? 'Grant permission' : 'دادن دسترسی';
  static String get noDeviceSongs => _lang == 'en' ? 'No songs found on this device.' : 'آهنگی روی گوشی پیدا نشد.';
  static String get unknownArtist => _lang == 'en' ? 'Unknown' : 'نامشخص';
  static String get couldNotPlay => _lang == 'en' ? 'Could not play this file' : 'پخش این فایل ممکن نشد';
  static String get reload => _lang == 'en' ? 'Reload' : 'بارگذاری مجدد';
  static String get seeAll => _lang == 'en' ? 'See all' : 'همه';
  static String get persian => _lang == 'en' ? 'Persian' : 'فارسی';
  static String get or => _lang == 'en' ? 'or' : 'یا';
  static String get loginBtn => _lang == 'en' ? 'Sign in' : 'ورود';
  static String get signUpBtn => _lang == 'en' ? 'Sign up' : 'ثبت‌نام';
  static String get playingDevice => _lang == 'en' ? 'Playing: ' : 'در حال پخش: ';
  static String get addAudioFile => _lang == 'en' ? 'Pick audio file' : 'انتخاب فایل صوتی';
  static String get audioSelected => _lang == 'en' ? 'Audio selected ✅' : 'فایل انتخاب شد ✅';
  static String get addCover => _lang == 'en' ? 'Pick cover (optional)' : 'انتخاب کاور (اختیاری)';
  static String get coverSelected => _lang == 'en' ? 'Cover selected ✅' : 'کاور انتخاب شد ✅';
  static String get publishSong => _lang == 'en' ? 'Publish song' : 'انتشار آهنگ';
  static String get uploading => _lang == 'en' ? 'Uploading...' : 'در حال آپلود...';
  static String get addSongTitle => _lang == 'en' ? 'Add song' : 'افزودن آهنگ';
  static String get pickAudioRequired => _lang == 'en' ? 'Pick an audio file' : 'فایل صوتی را انتخاب کن';
  static String get titleArtistRequired => _lang == 'en' ? 'Title and artist are required' : 'عنوان و خواننده الزامی‌ست';
  static String get songAdded => _lang == 'en' ? 'Song added successfully ✅' : 'آهنگ با موفقیت اضافه شد ✅';
  static String get uploadedNote => _lang == 'en'
      ? 'Uploaded songs show up immediately in New releases and by category.'
      : 'آهنگ‌های آپلود شده بلافاصله در «تازه‌ها» و بر اساس دسته‌بندی نمایش داده می‌شوند.';

  // form labels
  static String get songTitleLabel => _lang == 'en' ? 'Song title' : 'عنوان آهنگ';
  static String get artistNameLabel => _lang == 'en' ? 'Artist name' : 'نام خواننده';
  static String get categoryLabel => _lang == 'en' ? 'Category' : 'دسته‌بندی';

  // auth screen
  static String get authFillFields => _lang == 'en'
      ? 'Enter email and password (min 6 chars)'
      : 'ایمیل و رمز عبور (حداقل ۶ کاراکتر) را وارد کن';
  static String get authFillName => _lang == 'en' ? 'Enter your full name' : 'لطفاً نام و نام خانوادگی خود را وارد کن';
  static String get fullNameLabel => _lang == 'en' ? 'Full name' : 'نام و نام خانوادگی';
  static String get emailLabel => _lang == 'en' ? 'Email' : 'ایمیل';
  static String get passwordLabel => _lang == 'en' ? 'Password' : 'رمز عبور';

  // player share text
  static String get shareText => _lang == 'en'
      ? 'Listen to this song: {title} - {artist}\nFrom Iran Seda app 🎧\nOur channel: {channel}'
      : 'به این آهنگ گوش بده: {title} - {artist}\nاز اپ Iran Seda 🎧\nکانال ما: {channel}';
  static String get lyricsTooltip => _lang == 'en' ? 'Lyrics' : 'متن آهنگ';
  static String get localSongTitleDefault => _lang == 'en' ? 'Local song' : 'آهنگ محلی';
  static String get localSongArtistDefault => _lang == 'en' ? 'Device' : 'دستگاه';

  // local songs
  static String get playingPrefix => _lang == 'en' ? 'Playing: ' : 'در حال پخش: ';

  // library / playlist errors
  static String get errGeneric => _lang == 'en' ? 'Error: {e}' : 'خطا: {e}';
  static String get addedFromDevice => _lang == 'en' ? '{n} songs added from device' : '{n} آهنگ از گوشی اضافه شد';
}
