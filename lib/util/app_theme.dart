import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // --- COLOR PALETTE DEFINITIONS ---
  
  static ColorScheme _buildColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF060606),          // Near-black — buttons & toggles
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE6E6E6),
        onPrimaryContainer: Color(0xFF0A0A0A),
        secondary: Color(0xFF0D9488),        // Teal 600 — accents, focus, active
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFCCFBF1),
        onSecondaryContainer: Color(0xFF115E59),
        tertiary: Color(0xFF0F766E),        // Teal 700
        onTertiary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF991B1B),
        surface: Colors.white,
        onSurface: Color(0xFF161616),        // Near-black text
        onSurfaceVariant: Color(0xFF6B6B6B),  // Muted grey
        outline: Color(0xFFDEDEDE),          // Edge grey
        outlineVariant: Color(0xFFECECEC),   // Line grey
        surfaceContainerLowest: Color(0xFFF5F5F5), // Well grey
        surfaceContainerLow: Color(0xFFEEEEEE),
        surfaceContainer: Color(0xFFE8E8E8),
        surfaceContainerHigh: Color(0xFFDFDFDF),
        surfaceContainerHighest: Color(0xFFD6D6D6),
      );
    } else {
      return const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFF8F8F8),          // Near-white — buttons & toggles
        onPrimary: Color(0xFF0B0B0B),
        primaryContainer: Color(0xFF2A2A2A),
        onPrimaryContainer: Color(0xFFF0F0F0),
        secondary: Color(0xFF2DD4BF),        // Teal 400 — accents, focus, active
        onSecondary: Color(0xFF003733),
        secondaryContainer: Color(0xFF0D9488),
        onSecondaryContainer: Color(0xFFCCFBF1),
        tertiary: Color(0xFF14B8A6),        // Teal 500
        onTertiary: Color(0xFF003733),
        error: Color(0xFFF87171),
        onError: Color(0xFF550000),
        errorContainer: Color(0xFF991B1B),
        onErrorContainer: Color(0xFFFEE2E2),
        surface: Color(0xFF1B1B1B),          // Card surface
        onSurface: Color(0xFFF2F2F2),
        onSurfaceVariant: Color(0xFF9C9C9C),
        outline: Color(0xFF333333),
        outlineVariant: Color(0xFF262626),
        surfaceContainerLowest: Color(0xFF0B0B0B), // Canvas
        surfaceContainerLow: Color(0xFF121212),
        surfaceContainer: Color(0xFF181818),
        surfaceContainerHigh: Color(0xFF1F1F1F),
        surfaceContainerHighest: Color(0xFF242424),
      );
    }
  }

  // --- TYPOGRAPHY SYSTEM ---
  
  static TextTheme _buildTextTheme(Brightness brightness, TextTheme base) {
    final textColor = brightness == Brightness.light ? const Color(0xFF1E293B) : const Color(0xFFF4F7F5);
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        textStyle: base.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.bodyLarge?.copyWith(
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.bodyMedium?.copyWith(
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.bodySmall?.copyWith(
          fontWeight: FontWeight.normal,
          color: textColor.withValues(alpha: 0.7),
        ),
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor.withValues(alpha: 0.8),
        ),
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        textStyle: base.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // --- THEME BUILDER ---

  static ThemeData _buildTheme(Brightness brightness) {
    final baseColorScheme = _buildColorScheme(brightness);
    final baseTextTheme = brightness == Brightness.light 
        ? ThemeData.light().textTheme 
        : ThemeData.dark().textTheme;
    final customTextTheme = _buildTextTheme(brightness, baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: baseColorScheme.surface,
      textTheme: customTextTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: baseColorScheme.surface,
        foregroundColor: baseColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: baseColorScheme.onSurface,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: baseColorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(0),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: baseColorScheme.surface,
        elevation: 6,
        shadowColor: baseColorScheme.onSurface.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: baseColorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: baseColorScheme.onSurface,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? baseColorScheme.surfaceContainerLowest
            : baseColorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: baseColorScheme.outline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: baseColorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: baseColorScheme.secondary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: baseColorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: baseColorScheme.error,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: baseColorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          color: baseColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.outline.withValues(alpha: 0.3);
            }
            return baseColorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return baseColorScheme.onPrimary;
          }),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.hovered)) return 4;
            return 2;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.surfaceContainerHighest;
            }
            return baseColorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return baseColorScheme.onPrimary;
          }),
          shadowColor: WidgetStateProperty.all(baseColorScheme.onSurface.withValues(alpha: 0.1)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: baseColorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              );
            }
            return BorderSide(color: baseColorScheme.outline, width: 1.2);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return baseColorScheme.onSurface;
          }),
          overlayColor: WidgetStateProperty.all(baseColorScheme.onSurface.withValues(alpha: 0.05)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return baseColorScheme.onSurface;
          }),
          overlayColor: WidgetStateProperty.all(baseColorScheme.onSurface.withValues(alpha: 0.05)),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.outline;
            }
            return baseColorScheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return baseColorScheme.onSurface.withValues(alpha: 0.05);
            }
            return null;
          }),
        ),
      ),
      
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(baseColorScheme.surfaceContainerLow),
        headingTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: baseColorScheme.onSurfaceVariant,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.secondary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return baseColorScheme.onSurface.withValues(alpha: 0.03);
          }
          return null;
        }),
        dataTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: baseColorScheme.onSurface,
        ),
        dividerThickness: 1,
        horizontalMargin: 24,
        columnSpacing: 24,
        dataRowMaxHeight: 56,
      ),

      dividerTheme: DividerThemeData(
        color: baseColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: baseColorScheme.surfaceContainerLowest,
        selectedIconTheme: IconThemeData(color: baseColorScheme.secondary),
        unselectedIconTheme: IconThemeData(color: baseColorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: baseColorScheme.secondary,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        indicatorColor: baseColorScheme.secondary.withValues(alpha: 0.12),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: baseColorScheme.surface,
        elevation: 0,
        shape: Border(right: BorderSide(color: baseColorScheme.outlineVariant)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseColorScheme.primary,
        foregroundColor: baseColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: baseColorScheme.onSurface.withValues(alpha: 0.2),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: baseColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: baseColorScheme.onSurface,
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(baseColorScheme.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(12),
          shadowColor: WidgetStatePropertyAll(baseColorScheme.onSurface.withValues(alpha: 0.12)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: baseColorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: baseColorScheme.onSurface,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: baseColorScheme.surfaceContainerLowest,
        disabledColor: baseColorScheme.surfaceContainerLow,
        selectedColor: baseColorScheme.secondary.withValues(alpha: 0.14),
        secondarySelectedColor: baseColorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.secondary,
          fontWeight: FontWeight.w700,
        ),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        side: BorderSide(color: baseColorScheme.outline),
      ),
    );
  }

  static final light = _buildTheme(Brightness.light);
  static final dark = _buildTheme(Brightness.dark);

  /// Builds a complete [ThemeData] from an existing [colorScheme] and brightness,
  /// honoring [GoogleFonts.plusJakartaSans] typography and [scaffoldBackgroundColor].
  ///
  /// Used by [AppTypeService] to generate per-vertical light/dark theme variants
  /// without losing Material3 color scheme semantics.
  static ThemeData buildThemeFromScheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
  }) {
    final baseTextTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final customTextTheme = _buildTextTheme(brightness, baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: customTextTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.error,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.outline.withValues(alpha: 0.3);
            }
            if (states.contains(WidgetState.hovered)) {
              return brightness == Brightness.light
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF14B8A6);
            }
            if (states.contains(WidgetState.pressed)) {
              return brightness == Brightness.light
                  ? const Color(0xFF115E59)
                  : const Color(0xFF0F766E);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return colorScheme.onPrimary;
          }),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.hovered)) return 2;
            if (states.contains(WidgetState.pressed)) return 1;
            return 1;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest;
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return colorScheme.onPrimary;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              );
            }
            return BorderSide(color: colorScheme.primary, width: 1.2);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return colorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return colorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.outline;
            }
            return colorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(colorScheme.surfaceContainerHighest),
        headingTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.06);
          }
          return null;
        }),
        dataTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 20,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brightness == Brightness.light
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: brightness == Brightness.light ? Colors.white : colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            brightness == Brightness.light ? Colors.white : colorScheme.surfaceContainerHigh,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(6),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          color: colorScheme.onPrimary,
        ),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }
}

