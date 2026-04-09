import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const seedGreen = Color(0xFF2E7D32);
    const deepSoil = Color(0xFF3D2B1F);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedGreen,
        brightness: Brightness.light,
      ).copyWith(
        primary: seedGreen,
        onPrimary: Colors.white,
        secondary: const Color(0xFF8F6B4F),
        tertiary: const Color(0xFF56A55A),
        surface: Colors.white,
        onSurface: const Color(0xFF1A281A),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F1E9),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFFF5F1E9),
        foregroundColor: deepSoil,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: deepSoil,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: deepSoil,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: deepSoil,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF283028),
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF435344),
          height: 1.45,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.6,
        shadowColor: const Color(0x1A2E7D32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x1A2E7D32)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seedGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAF2E8),
        selectedColor: const Color(0xFFD4E9D0),
        side: const BorderSide(color: Color(0xFFB8D5B2)),
        labelStyle: const TextStyle(
          color: deepSoil,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC5D4C1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC5D4C1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: seedGreen, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDEDD8),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedGreen
                : const Color(0xFF667766),
          ),
        ),
      ),
      dividerColor: const Color(0xFFD8E4D2),
    );
  }
}
