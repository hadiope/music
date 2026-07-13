import 'package:flutter/material.dart';

/// Returns a Persian greeting based on the current hour.
String greetingMessage() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'صبح بخیر 🌅';
  if (h >= 12 && h < 17) return 'ظهر بخیر ☀️';
  if (h >= 17 && h < 21) return 'عصر بخیر 🌇';
  return 'شب بخیر 🌙';
}

/// Returns the user's first name (before @ or space) for a personal touch.
String firstName(String? emailOrName) {
  if (emailOrName == null || emailOrName.isEmpty) return '';
  final base = emailOrName.contains('@') ? emailOrName.split('@').first : emailOrName;
  final name = base.split('.').first.split(' ').first;
  return name.isNotEmpty ? name : '';
}
