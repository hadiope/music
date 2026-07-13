# 🎧 Harmony Music — اپ موزیک استریمینگ (Flutter + Supabase)

یه اپلیکیشن موزیک حرفه‌ای شبیه Spotify، ساخته‌شده با **Flutter** و بک‌اند **Supabase**.

## ✨ امکانات
- 🔐 احراز هویت: ثبت‌نام/ورود با ایمیل + ورود با گوگل
- 🏠 صفحه اصلی: بنر تبلیغاتی، ژانرها، «تازه‌ها» و «محبوب‌ها»
- ▶️ پلیر کامل + Mini Player، پخش در پس‌زمینه، کنترل از نوتیفیکیشن و صفحه قفل
- 🔁 تکرار / 🔀 شافل / اسلایدر زمان
- 🔍 جستجوی آهنگ و خواننده
- ❤️ لایک آهنگ + پلی‌لیست شخصی + تاریخچه پخش
- 🌗 تم تیره/روشن + 🌐 فارسی (RTL) و انگلیسی
- ✈️ دکمه «کانال تلگرام ما» + اشتراک‌گذاری آهنگ
- 📢 بنر تبلیغاتی قابل مدیریت از دیتابیس

---

## 🚀 راه‌اندازی (قدم به قدم)

### پیش‌نیازها (یه بار روی سیستمت نصب کن)
1. **Flutter SDK** → https://docs.flutter.dev/get-started/install
2. **Android Studio** (برای Android SDK) → https://developer.android.com/studio
3. تست کن: تو ترمینال بزن `flutter doctor` — همه‌چی باید ✅ باشه

### قدم ۱: ساخت اسکلت پروژه اندروید/iOS
چون این zip فقط سورس‌کد (`lib/`) و تنظیمات رو داره، اول باید پوشه‌های پلتفرم ساخته بشن. تو پوشه‌ی پروژه این رو بزن:
```bash
flutter create .
```
> این دستور پوشه‌های `android/`, `ios/`, `web/` رو می‌سازه بدون اینکه کدهای `lib/` تو رو دست بزنه.

### قدم ۲: نصب پکیج‌ها
```bash
flutter pub get
```

### قدم ۳: ساخت پروژه Supabase
1. برو https://supabase.com → پروژه رایگان بساز
2. از `Project Settings -> API`، دوتا مقدار رو کپی کن:
   - **Project URL**
   - **anon public key**
3. بازشون کن تو فایل `lib/core/constants.dart` و جایگزین کن:
   ```dart
   static const String supabaseUrl = 'اینجا URL خودت';
   static const String supabaseAnonKey = 'اینجا anon key خودت';
   static const String telegramChannel = 'https://t.me/کانال_خودت';
   ```
4. تو Supabase برو `SQL Editor` → محتوای فایل `supabase_setup.sql` رو کپی/پیست کن → **Run**
   (این جدول‌ها، RLS، تابع increment_plays و چندتا آهنگ نمونه رو می‌سازه)
5. برو `Storage` → دو تا باکت **public** بساز: `music` و `covers`

### قدم ۴: تنظیم فایل‌های اندروید (مهم برای پخش پس‌زمینه)
بعد از `flutter create .`، فایل `android/app/src/main/AndroidManifest.xml` رو باز کن و
محتوای فایل `android_manifest_REFERENCE.xml` (تو همین پروژه) رو باهاش تطبیق بده —
مخصوصاً مجوزها و بخش `<service>` مربوط به audio_service رو اضافه کن.

همچنین تو `android/app/build.gradle` مقدار `minSdkVersion` رو بذار **23** یا بالاتر:
```gradle
minSdkVersion 23
```

### قدم ۵: اجرا روی گوشی/شبیه‌ساز
```bash
flutter run
```

### قدم ۶: ساخت فایل نصبی APK 🎉
```bash
flutter build apk --release
```
فایل خروجی اینجاست:
```
build/app/outputs/flutter-apk/app-release.apk
```
اینو بریز رو گوشی یا بذار تو کانال تلگرامت.

### (اختیاری) نسخه بازار (گوگل‌پلی/مایکت):
```bash
flutter build appbundle --release
```

---

## 🎵 اضافه کردن آهنگ
- **راه ساده:** تو Supabase → Table Editor → جدول `songs` → آهنگ اضافه کن (لینک mp3 و کاور)
- **آپلود فایل:** Storage → باکت `music` → آپلود mp3 → کپی Public URL → بذارش تو `audio_url`

## 📢 مدیریت بنر تبلیغاتی
تو جدول `banners` رکورد اضافه/غیرفعال کن — بدون آپدیت اپ، بنر عوض می‌شه.

---

## ⚠️ نکات
- **کپی‌رایت:** برای انتشار عمومی از آهنگ‌های مجاز/بی‌کپی‌رایت یا محتوای خودت استفاده کن.
- **ورود با گوگل:** برای فعال شدن، تو Supabase → Authentication → Providers → Google رو روشن کن و Client ID بذار. مقدار `YOUR_GOOGLE_WEB_CLIENT_ID` تو فایل `auth_provider.dart` رو هم پر کن.
- **آهنگ‌های نمونه:** از SoundHelix (رایگان) استفاده شده که مستقیم پخش می‌شن تا تست کنی.

## 📁 ساختار پروژه
```
lib/
├── core/          → theme, constants
├── models/        → song, album, playlist, banner
├── services/      → database_service, audio_handler
├── providers/     → Riverpod (auth, songs, likes, playlists, player, settings)
├── screens/       → splash, auth, home, search, library, player, profile, main_shell
├── widgets/       → mini_player, song_tile, banner_carousel, section_header
└── main.dart
```

موفق باشی داداش 🚀🎧
