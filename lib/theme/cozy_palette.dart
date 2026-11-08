import 'package:flutter/material.dart';

import '../services/appearance_service.dart';

/// Central colors for Cozy Kana. Existing light colors remain exactly the same.
///
/// Use CozyPalette.watch(context) at the start of widget build() methods.
/// That registers a dependency on Flutter's Theme, so Follow System and manual
/// theme changes repaint existing screens without losing their learning state.
class CozyPalette {
  CozyPalette._();

  static void watch(BuildContext context) {
    Theme.of(context); // Registers a theme dependency with this BuildContext.
  }

  static bool get isDark {
    final selection = AppearanceService.instance.mode;
    if (selection == ThemeMode.dark) return true;
    if (selection == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  // Exact original Cozy Light colors, also used in MaterialApp's light theme.
  static const Color lightCream = Color(0xFFFDF8F3);
  static const Color lightBeige = Color(0xFFEADFD1);
  static const Color lightSand = Color(0xFFDCC6A8);
  static const Color lightTaupe = Color(0xFFC6B8A5);
  static const Color lightText = Color(0xFF5D534A);
  static const Color lightMuted = Color(0xFF8B8076);
  static const Color lightSage = Color(0xFFB7C9B2);
  static const Color lightGreenButton = Color(0xFF6EAA78);

  // Warm coffee colors rather than high-contrast black-and-white.
  static const Color darkCream = Color(0xFF352B27); // Raised card surface
  static const Color darkBeige = Color(0xFF231D1B); // Main canvas
  static const Color darkSand = Color(0xFF4D3C33); // Card headers
  static const Color darkTaupe = Color(0xFF5D4A40); // Controls
  static const Color darkText = Color(0xFFF2E5D7); // High-contrast foreground
  static const Color darkMuted = Color(0xFFD0BCAA); // Secondary foreground
  static const Color darkSage = Color(0xFF405B4A);
  static const Color darkGreenButton = Color(0xFF45664E);

  static Color get cream => isDark ? darkCream : lightCream;
  static Color get beige => isDark ? darkBeige : lightBeige;
  static Color get sand => isDark ? darkSand : lightSand;
  static Color get taupe => isDark ? darkTaupe : lightTaupe;
  static Color get textDark => isDark ? darkText : lightText;
  static Color get textLight => isDark ? darkMuted : lightMuted;
  // In dark mode, outlines and tactile drop shadows should stay subdued,
  // instead of becoming bright cream when regular text changes to cream.
  static Color get outline => isDark ? const Color(0xFF9E8675) : lightText;
  static Color get shadow => isDark ? const Color(0xFF130E0C) : lightText;
  static Color get sage => isDark ? darkSage : lightSage;
  // Writing strokes need a brighter green than the sage card background.
  static Color get writingInk => isDark ? const Color(0xFFA6D8AE) : lightSage;
  static Color get lightSageShade =>
      isDark ? const Color(0xFF334538) : const Color(0xFFE4EFE7);
  static Color get skyBlue =>
      isDark ? const Color(0xFF415B70) : const Color(0xFFA5C4E5);
  static Color get lightSkyBlue =>
      isDark ? const Color(0xFF2E414F) : const Color(0xFFEBF0F5);
  static Color get greenButton => isDark ? darkGreenButton : lightGreenButton;
  static Color get unlockedGold =>
      isDark ? const Color(0xFFC79F60) : const Color(0xFFE2B457);

  static Color get flameOrange =>
      isDark ? const Color(0xFFF09A65) : const Color(0xFFE06229);
  static Color get flameOrangeProgress =>
      isDark ? const Color(0xFFF09A65) : const Color(0xFFE06D39);
  static Color get flameBadgeBg =>
      isDark ? const Color(0xFF674438) : const Color(0xFFFFD2BA);
  static Color get flameCardBgActive =>
      isDark ? const Color(0xFF50372D) : const Color(0xFFFFD4BE);
  static Color get dangerRed =>
      isDark ? const Color(0xFFBD7470) : const Color(0xFFD88A82);
  static Color get ratingAgain =>
      isDark ? const Color(0xFF915C5A) : const Color(0xFFD88A82);
  static Color get ratingHard =>
      isDark ? const Color(0xFF9B744B) : const Color(0xFFE29E57);
  static Color get ratingGood =>
      isDark ? const Color(0xFF52765B) : const Color(0xFF9FB89A);
  static Color get ratingEasy =>
      isDark ? const Color(0xFF557796) : const Color(0xFFA5C4E5);
  static Color get flashcardRatingAgain =>
      isDark ? const Color(0xFF915C5A) : const Color(0xFFE8A0A0);
  static Color get flashcardRatingHard =>
      isDark ? const Color(0xFF927550) : const Color(0xFFE8C396);
  static Color get correctBg =>
      isDark ? const Color(0xFF3B6451) : const Color(0xFFB4CDB4);
  static Color get correctIcon =>
      isDark ? const Color(0xFF9FDAA5) : const Color(0xFF5CA95C);
  static Color get incorrectBg =>
      isDark ? const Color(0xFF794A47) : const Color(0xFFD88A82);
  static Color get incorrectIcon =>
      isDark ? const Color(0xFFFFA39A) : const Color(0xFFC95B50);

  static Color get basicGreen =>
      isDark ? const Color(0xFF8EBA9B) : const Color(0xFF526E5A);
  static Color get dakuonBlue =>
      isDark ? const Color(0xFF84B0D0) : const Color(0xFF7BA2C7);
  static Color get yoonBrown =>
      isDark ? const Color(0xFFD3A77C) : const Color(0xFFA67C52);
  static Color get activeDay =>
      isDark ? const Color(0xFF5E8264) : const Color(0xFF8FA98F);

  static Color get introSage =>
      isDark ? const Color(0xFF526C48) : const Color(0xFF8EA66F);
  static Color get welcomeBrown => isDark ? darkText : const Color(0xFF79502F);
  static Color get welcomeMuted => isDark ? darkMuted : const Color(0xFF947963);
  static Color get welcomeDanger =>
      isDark ? const Color(0xFFF09A8B) : const Color(0xFFB14F44);
  static Color get lavender =>
      isDark ? const Color(0xFF4E4154) : const Color(0xFFF3E7F7);
  static Color get paleGold =>
      isDark ? const Color(0xFF584936) : const Color(0xFFFFF0D4);

  // Additional Word Builder and dialog feedback shades.
  static Color get successLight =>
      isDark ? const Color(0xFF354D3B) : const Color(0xFFD3EEDD);
  static Color get errorLight =>
      isDark ? const Color(0xFF543839) : const Color(0xFFFDE8E7);
  static Color get correctStrong =>
      isDark ? const Color(0xFF85C897) : const Color(0xFF2E633C);
  static Color get correctMid =>
      isDark ? const Color(0xFF739D7B) : const Color(0xFF4A885B);
  static Color get incorrectStrong =>
      isDark ? const Color(0xFFFFAEA3) : const Color(0xFF8C342C);
  static Color get incorrectMid =>
      isDark ? const Color(0xFFCB8C82) : const Color(0xFFB54C43);
  static Color get softMint =>
      isDark ? const Color(0xFF456C54) : const Color(0xFFA2D3AD);
  static Color get softCoral =>
      isDark ? const Color(0xFF7E5048) : const Color(0xFFE28B83);
  static Color get softCoralBg =>
      isDark ? const Color(0xFF654643) : const Color(0xFFF7D2CE);
}
