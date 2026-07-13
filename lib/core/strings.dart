import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// Lightweight i18n. Each string has a fa + en value. Switches on the
/// current locale so the whole UI flips language instantly.
class T {
  T._();
  static String _(String fa, String en) =>
      _locale == 'en' ? en : fa;

  static String get localeCode => _locale;
  static String _locale = 'fa';

  static void setLocale(String code) => _locale = code;

  // --- common ---
  static String get appName => _('Iranian Spotify', 'Iranian Spotify');
  static String get home => _('خانه', 'Home');
  static String get search => _('جستجو', 'Search');
  static String get library => _('کتابخانه', 'Library');
  static String get profile => _('پروفایل', 'Profile');
  static String get playlists => _('پلی‌لیست‌ها', 'Playlists');
  static String get songs => _('آهنگ‌ها', 'Songs');
  static String get albums => _('آلبوم‌ها', 'Albums');
  static String get artists => _('خوانندگان', 'Artists');
  static String get genres => _('دسته‌بندی‌ها', 'Genres');
  static String get settings => _('تنظیمات', 'Settings');
  static String get logout => _('خروج از حساب', 'Log out');
  static String get login => _('ورود', 'Log in');
  static String get signup => _('ثبت‌نام', 'Sign up');
  static String get loginWithGoogle => _('ورود با حساب گوگل', 'Sign in with Google');
  static String get email => _('ایمیل', 'Email');
  static String get password => _('رمز عبور', 'Password');
  static String get fullName => _('نام و نام خانوادگی', 'Full name');
  static String get changePassword => _('تغییر رمز عبور', 'Change password');
  static String get newPassword => _('رمز عبور جدید (حداقل ۶ کاراکتر)', 'New password (min 6)');
  static String get displayName => _('نام نمایشی', 'Display name');
  static String get save => _('ذخیره', 'Save');
  static String get cancel => _('انصراف', 'Cancel');
  static String get darkTheme => _('تم تیره', 'Dark theme');
  static String get language => _('زبان', 'Language');
  static String get telegramChannel => _('کانال تلگرام ما', 'Our Telegram channel');
  static String get addSong => _('افزودن آهنگ (پنل مدیریت)', 'Add song (admin)');
  static String get nowPlaying => _('در حال پخش', 'Now playing');
  static String get noResults => _('نتیجه‌ای یافت نشد', 'No results');
  static String get addFromDevice => _('افزودن از حافظه گوشی', 'Add from device');
  static String get localFiles => _('فایل‌های دستگاه', 'Device files');
  static String get liked => _('علاقه‌مندی‌ها', 'Liked');
  static String get about => _('درباره Iranian Spotify', 'About Iranian Spotify');
  static String get version => _('نسخه ۱.۰.۰', 'Version 1.0.0');
  static String get welcomeBack => _('خوش برگشتی', 'Welcome back');
  static String get createAccount => _('حساب جدید بساز', 'Create account');
  static String get alreadyHave => _('قبلاً ثبت‌نام کردی؟ وارد شو', 'Have an account? Log in');
  static String get noAccount => _('حساب نداری؟ همین‌جا بساز', "Don't have an account? Sign up");
}

/// Call once at app start (and on locale change) so T reads the right language.
void syncLocale(WidgetRef ref) {
  T.setLocale(ref.read(localeProvider).languageCode);
}
