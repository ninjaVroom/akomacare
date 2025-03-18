import 'package:flutter/material.dart';

/// v1 "Solid Red" (2023) tokens, from research/02_design-system/tokens-2023.json.
class C {
  static const red = Color(0xFFC2272D);
  static const redDark = Color(0xFF9E2024);
  static const headerRed = Color(0xFFCA2E2F);
  static const readPillHalo = Color(0xFFF5DFE1);
  static const onboardPink = Color(0xFFFFABAB);
  static const pageBg = Color(0xFFEFEFEF);
  static const pageBgGames = Color(0xFFE1E1E1);
  static const pageBgRankings = Color(0xFFE6E6E6);
  static const card = Color(0xFFFFFFFF);
  static const bottomNavBg = Color(0xFFFFF5F4);
  static const bannerDark = Color(0xFF191413);
  static const bannerShadow = Color(0xFF231F22);
  static const calcTab = Color(0xFFDF507D);
  static const gold = Color(0xFFD5B779);
  static const goldText = Color(0xFFCC9628);
  static const goldTitle = Color(0xFFCCA34E);
  static const teal = Color(0xFF3AAA94);
  static const tealIcon = Color(0xFFB084F5);
  static const rankTabBar = Color(0xFFE7E7E7);
  static const rankRow = Color(0xFFFFF6F7);
  static const rankRowMe = Color(0xFFFEE0E0);
  static const podiumCard = Color(0xFFF7F7F7);
  static const rankA = Color(0xFFFBA29A);
  static const rankB = Color(0xFFF06F94);
  static const scoreB = Color(0xFFF78996);
  static const text = Color(0xFF1D1D1D);
  static const textBrown = Color(0xFF48211B);
  static const muted = Color(0xFF797473);
  static const olive = Color(0xFFBDB89A);
  static const oliveLight = Color(0xFFE2DFCB);
  static const puzzleGreen = Color(0xFF6E9A5A);
  static const playGreen = Color(0xFF3E9B4F);

  static const rankBadge = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rankA, rankB]);
  static const scorePill = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [rankA, scoreB]);
  static const shadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))];
}

TextStyle slab(double size, Color color) => TextStyle(fontFamily: 'RobotoSlab', fontSize: size, color: color);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Urbanist', // bundled in assets/fonts (offline-safe)
    colorScheme: ColorScheme.fromSeed(seedColor: C.red, primary: C.red, surface: C.card),
    scaffoldBackgroundColor: C.pageBg,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.text, displayColor: C.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.red, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.redDark)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.red,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
