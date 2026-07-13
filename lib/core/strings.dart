import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// Lightweight i18n. Each string has a fa + en value. Switches on the
/// current locale so the whole UI flips language instantly.
class T {
  T._();
  static String tr(String fa, String en) =>
      _locale == 'en' ? en : fa;

  static String get localeCode => _locale;
  static String _locale = 'fa';

  static void setLocale(String code) => _locale = code;

  // --- common ---
  static String get appName => tr('Iranian Spotify', 'Iranian Spotify');
  static String get home => tr('خانه', 'Home');
  static String get search => tr('جستجو', 'Search');
  static String get library => tr('کتابخانه', 'Library');
  static String get profile => tr('پروفایل', 'Profile');
  static String get playlists => tr('پلی‌لیست‌ها', 'Playlists');
  static String get songs => tr('آهنگ‌ها', 'Songs');
  static String get albums => tr('آلبوم‌ها', 'Albums');
  static String get artists => tr('خوانندگان', 'Artists');
  static String get genres => tr('دسته‌بندی‌ها', 'Genres');
  static String get settings => tr('تنظیمات', 'Settings');
  static String get logout => tr('خروج از حساب', 'Log out');
  static String get login => tr('ورود', 'Log in');
  static String get signup => tr('ثبت‌نام', 'Sign up');
  static String get loginWithGoogle => tr('ورود با حساب گوگل', 'Sign in with Google');
  static String get email => tr('ایمیل', 'Email');
  static String get password => tr('رمز عبور', 'Password');
  static String get fullName => tr('نام و نام خانوادگی', 'Full name');
  static String get changePassword => tr('تغییر رمز عبور', 'Change password');
  static String get newPassword => tr('رمز عبور جدید (حداقل ۶ کاراکتر)', 'New password (min 6)');
  static String get displayName => tr('نام نمایشی', 'Display name');
  static String get save => tr('ذخیره', 'Save');
  static String get cancel => tr('انصراف', 'Cancel');
  static String get darkTheme => tr('تم تیره', 'Dark theme');
  static String get language => tr('زبان', 'Language');
  static String get telegramChannel => tr('کانال تلگرام ما', 'Our Telegram channel');
  static String get addSong => tr('افزودن آهنگ (پنل مدیریت)', 'Add song (admin)');
  static String get nowPlaying => tr('در حال پخش', 'Now playing');
  static String get noResults => tr('نتیجه‌ای یافت نشد', 'No results');
  static String get addFromDevice => tr('افزودن از حافظه گوشی', 'Add from device');
  static String get localFiles => tr('فایل‌های دستگاه', 'Device files');
  static String get liked => tr('علاقه‌مندی‌ها', 'Liked');
  static String get about => tr('درباره Iranian Spotify', 'About Iranian Spotify');
  static String get version => tr('نسخه ۱.۰.۰', 'Version 1.0.0');
  static String get welcomeBack => tr('خوش برگشتی', 'Welcome back');
  static String get createAccount => tr('حساب جدید بساز', 'Create account');
  static String get alreadyHave => tr('قبلاً ثبت‌نام کردی؟ وارد شو', 'Have an account? Log in');
  static String get noAccount => tr('حساب نداری؟ همین‌جا بساز', "Don't have an account? Sign up");
}

/// Call once at app start (and on locale change) so T reads the right language.
void syncLocale(WidgetRef ref) {
  T.setLocale(ref.read(localeProvider).languageCode);
}
