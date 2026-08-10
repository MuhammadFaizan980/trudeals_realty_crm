import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'trudeals_colors.dart';

class TruDealsTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: TruDealsColors.sageDeep,
        primary: TruDealsColors.sageDeep,
        surface: TruDealsColors.paper,
        surfaceContainer: TruDealsColors.card,
        error: TruDealsColors.red,
      ),
      scaffoldBackgroundColor: TruDealsColors.paper,
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          textStyle: base.textTheme.displayLarge,
          fontWeight: FontWeight.w400,
          color: TruDealsColors.ink,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          textStyle: base.textTheme.displayMedium,
          fontWeight: FontWeight.w400,
          color: TruDealsColors.ink,
        ),
        displaySmall: GoogleFonts.dmSerifDisplay(
          textStyle: base.textTheme.displaySmall,
          fontWeight: FontWeight.w400,
          color: TruDealsColors.ink,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          textStyle: base.textTheme.headlineMedium,
          fontWeight: FontWeight.w400,
          color: TruDealsColors.ink,
        ),
        titleLarge: GoogleFonts.dmSerifDisplay(
          textStyle: base.textTheme.titleLarge,
          fontWeight: FontWeight.w400,
          color: TruDealsColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: TruDealsColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.px),
          side: const BorderSide(color: TruDealsColors.line),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TruDealsColors.paper,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TruDealsColors.sageDeep,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.px)),
          padding: EdgeInsets.symmetric(horizontal: 16.px, vertical: 12.px),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.px),
          borderSide: const BorderSide(color: TruDealsColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.px),
          borderSide: const BorderSide(color: TruDealsColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.px),
          borderSide: const BorderSide(color: TruDealsColors.sageDeep, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: TruDealsColors.charcoal,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFC9CDC8),
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 12.px, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12.px, fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
