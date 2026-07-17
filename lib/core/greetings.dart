import 'package:flutter/material.dart';
import 'strings.dart';

/// Returns a greeting based on the current hour, localized.
String greetingMessage() {
  final h = DateTime.now().hour;
  final en = T.lang == 'en';
  if (h >= 5 && h < 12) return en ? 'Good morning 🌅' : 'صبح بخیر 🌅';
  if (h >= 12 && h < 17) return en ? 'Good afternoon ☀️' : 'ظهر بخیر ☀️';
  if (h >= 17 && h < 21) return en ? 'Good evening 🌇' : 'عصر بخیر 🌇';
  return en ? 'Good night 🌙' : 'شب بخیر 🌙';
}

/// Returns the user's first name (before @ or space) for a personal touch.
String firstName(String? emailOrName) {
  if (emailOrName == null || emailOrName.isEmpty) return '';
  final base = emailOrName.contains('@') ? emailOrName.split('@').first : emailOrName;
  final name = base.split('.').first.split(' ').first;
  return name.isNotEmpty ? name : '';
}
