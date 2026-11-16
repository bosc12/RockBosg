import 'package:flutter/material.dart';

import 'data/catalog.dart';

/// Colores tomados del logo RockBosg: cian brillante + gris pizarra.
class Brand {
  static const cyan = Color(0xFF1FB8E0);
  static const cyanDeep = Color(0xFF0B7FA6);
  static const slate = Color(0xFF1C232B);
  static const slateSoft = Color(0xFF2A333D);
  static const gold = Color(0xFFD9A93B);

  static const kindColors = {
    'mineral': Color(0xFF1FB8E0),
    'ignea': Color(0xFFE0603A),
    'sedimentaria': Color(0xFFC79A4A),
    'metamorfica': Color(0xFF7A6BD1),
  };

  static const kindIcons = {
    'mineral': Icons.diamond_rounded,
    'ignea': Icons.volcano_rounded,
    'sedimentaria': Icons.layers_rounded,
    'metamorfica': Icons.compress_rounded,
  };

  static Color kindColor(String kind) => kindColors[kind] ?? cyan;
  static IconData kindIcon(String kind) =>
      kindIcons[kind] ?? Icons.diamond_rounded;
  static Color forMineral(Mineral m) => Color(m.hex);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.cyan,
    brightness: b,
    primary: dark ? Brand.cyan : Brand.cyanDeep,
    surface: dark ? Brand.slate : const Color(0xFFF7F9FA),
  ).copyWith(
    surfaceContainerLowest: dark ? const Color(0xFF151A20) : Colors.white,
    surfaceContainerLow: dark ? Brand.slateSoft : Colors.white,
    surfaceContainer: dark ? const Color(0xFF303A45) : const Color(0xFFEDF1F4),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: scheme.outlineVariant.withOpacity(dark ? 0.4 : 0.6)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
