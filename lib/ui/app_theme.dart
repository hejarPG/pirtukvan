import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color brandBlue = Color(0xFF118AB2);
  static const Color brandGreen = Color(0xFF06D6A0);
  static const Color brandYellow = Color(0xFFFFD166);
  static const Color brandRed = Color(0xFFEF476F);

  static final ThemeData lightTheme = _buildLightTheme();

  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: brandBlue, brightness: Brightness.light).copyWith(
      secondary: brandGreen,
      error: brandRed,
      surface: Colors.white,
      onSurface: Colors.black87,
    );

    final base = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      primaryColor: colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withAlpha(36)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        actionTextColor: colorScheme.primary,
      ),
      // Cards use default styling; individual cards can override shape/elevation as needed.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brandBlue),
      iconTheme: IconThemeData(color: colorScheme.primary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.black54,
      ),
      extensions: <ThemeExtension<dynamic>>[
        _BrandColors.light,
      ],
    );
  }

  static ThemeData _buildDarkTheme() {
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: brandBlue, brightness: Brightness.dark).copyWith(
      secondary: brandGreen,
      error: brandRed,
      surface: const Color(0xFF0F1720),
      onSurface: Colors.white70,
    );

    final base = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      primaryColor: colorScheme.primary,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.onSurface.withAlpha(31)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandGreen,
        foregroundColor: Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        actionTextColor: colorScheme.primary,
      ),
      // Cards use default styling in dark theme; customize per-widget if required.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1216),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brandBlue),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.white54,
      ),
      extensions: <ThemeExtension<dynamic>>[
        _BrandColors.dark,
      ],
    );
  }
}

class _BrandColors extends ThemeExtension<_BrandColors> {
  final Color blue;
  final Color green;
  final Color yellow;
  final Color red;

  const _BrandColors({required this.blue, required this.green, required this.yellow, required this.red});

  static const _BrandColors light = _BrandColors(blue: AppTheme.brandBlue, green: AppTheme.brandGreen, yellow: AppTheme.brandYellow, red: AppTheme.brandRed);

  static const _BrandColors dark = _BrandColors(blue: AppTheme.brandBlue, green: AppTheme.brandGreen, yellow: AppTheme.brandYellow, red: AppTheme.brandRed);

  @override
  ThemeExtension<_BrandColors> copyWith({Color? blue, Color? green, Color? yellow, Color? red}) {
    return _BrandColors(blue: blue ?? this.blue, green: green ?? this.green, yellow: yellow ?? this.yellow, red: red ?? this.red);
  }

  @override
  ThemeExtension<_BrandColors> lerp(ThemeExtension<_BrandColors>? other, double t) {
    if (other is! _BrandColors) return this;
    return _BrandColors(
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      red: Color.lerp(red, other.red, t)!,
    );
  }
}
