import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const seedGreen = Color(0xFF2E6748);
    const deepSoil = Color(0xFF20372B);
    const harvestClay = Color(0xFFB9603D);
    const harvestGold = Color(0xFFC79436);
    const fieldMist = Color(0xFFF1F4EE);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedGreen,
        brightness: Brightness.light,
      ).copyWith(
        primary: seedGreen,
        onPrimary: Colors.white,
        secondary: harvestClay,
        onSecondary: Colors.white,
        tertiary: harvestGold,
        surface: const Color(0xFFFFFEFB),
        onSurface: deepSoil,
        primaryContainer: const Color(0xFFDCE9DC),
        onPrimaryContainer: deepSoil,
        secondaryContainer: const Color(0xFFF3E0D8),
        onSecondaryContainer: const Color(0xFF542719),
      ),
      scaffoldBackgroundColor: fieldMist,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: fieldMist,
        foregroundColor: deepSoil,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: deepSoil,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: deepSoil,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: deepSoil,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF2D3C2F),
          height: 1.48,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF536759),
          height: 1.48,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFEFB),
        elevation: 0,
        shadowColor: const Color(0x1420362B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFDCE4D9)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE7EEE4),
        selectedColor: const Color(0xFFD4E5D2),
        side: const BorderSide(color: Color(0xFFC8D7C5)),
        labelStyle: const TextStyle(
          color: deepSoil,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFEFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD5DFD2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD5DFD2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedGreen, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFEFB),
        indicatorColor: const Color(0xFFDCE9DC),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedGreen
                : const Color(0xFF718174),
          ),
        ),
      ),
      dividerColor: const Color(0xFFDCE4D9),
    );
  }
}
