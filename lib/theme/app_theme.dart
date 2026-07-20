import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const cream = Color(0xFFFCF6ED);
  static const ink = Color(0xFF2B2420);
  static const inkMuted = Color(0xFF7A7168);

  static const saffron = Color(0xFFE8912C);
  static const saffronDark = Color(0xFFC97A1E);
  static const teal = Color(0xFF1F6E6B);
  static const tealDark = Color(0xFF15514F);
  static const coral = Color(0xFFE0654A);

  static const success = Color(0xFF4C8C5B);
  static const successBg = Color(0xFFE7F2E9);
  static const warning = Color(0xFFD08A2A);
  static const warningBg = Color(0xFFFAF0DF);
  static const danger = Color(0xFFC85450);
  static const dangerBg = Color(0xFFF9E9E8);

  static const cardBorder = Color(0xFFE9E0D2);
  static const cardShadow = Color(0x14231A0A);
}


class CategoryStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  const CategoryStyle(this.color, this.bg, this.icon);
}

const Map<String, CategoryStyle> kCategoryStyles = {
  "words": CategoryStyle(AppColors.teal, Color(0xFFE4EEED), Icons.spellcheck_rounded),
  "sentences": CategoryStyle(AppColors.saffron, Color(0xFFFBEEDC), Icons.short_text_rounded),
  "poem": CategoryStyle(AppColors.coral, Color(0xFFFAE6E1), Icons.menu_book_rounded),
  "story": CategoryStyle(Color(0xFF6B5B95), Color(0xFFEAE6F2), Icons.auto_stories_rounded),
  "fill_blanks": CategoryStyle(Color(0xFF3E7CB1), Color(0xFFE2ECF4), Icons.edit_note_rounded),
};

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(useMaterial3: true, fontFamily: null);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.saffron,
        secondary: AppColors.teal,
        surface: Colors.white,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
