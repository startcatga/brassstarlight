import 'package:flutter/material.dart';

import 'palette.dart';

/// Cinzel for titles and names; Crimson Pro for everything read.
class Lettering {
  static const _title = 'Cinzel';
  static const _read = 'CrimsonPro';

  static TextStyle display({Color color = Palette.starlight}) => TextStyle(
      fontFamily: _title, fontSize: 34, fontWeight: FontWeight.w600,
      letterSpacing: 1.5, height: 1.1, color: color);

  static TextStyle title({Color color = Palette.starlight}) => TextStyle(
      fontFamily: _title, fontSize: 24, fontWeight: FontWeight.w600,
      letterSpacing: 0.8, height: 1.15, color: color);

  static TextStyle name({Color color = Palette.starlight}) => TextStyle(
      fontFamily: _title, fontSize: 19, fontWeight: FontWeight.w600,
      letterSpacing: 0.4, height: 1.2, color: color);

  static TextStyle label({Color color = Palette.starlight}) => TextStyle(
      fontFamily: _title, fontSize: 15, fontWeight: FontWeight.w600,
      letterSpacing: 0.6, height: 1.2, color: color);

  static TextStyle body({Color color = Palette.ink}) => TextStyle(
      fontFamily: _read, fontSize: 18, fontWeight: FontWeight.w400,
      height: 1.4, color: color);

  static TextStyle myth({Color color = Palette.inkSoft}) => TextStyle(
      fontFamily: _read, fontSize: 18, fontStyle: FontStyle.italic,
      height: 1.35, color: color);

  static TextStyle small({Color color = Palette.inkSoft}) => TextStyle(
      fontFamily: _read, fontSize: 16, fontWeight: FontWeight.w500,
      height: 1.3, color: color);

  static TextStyle number({Color color = Palette.ink, double size = 18}) =>
      TextStyle(
          fontFamily: _read, fontSize: size, fontWeight: FontWeight.w600,
          height: 1.2, color: color,
          fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Palette.nightInk,
    fontFamily: 'CrimsonPro',
    colorScheme: const ColorScheme.dark(
      primary: Palette.brass,
      onPrimary: Palette.ink,
      secondary: Palette.traceBlue,
      surface: Palette.nightBlue,
      onSurface: Palette.starlight,
      error: Palette.ember,
    ),
    splashFactory: NoSplash.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.brass,
      selectionColor: Color(0x55E2B84C),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
