import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // --- COLOR PALETTE DEFINITIONS ---
  
  static ColorScheme _buildColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF0D9488),          // Teal 600
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFCCFBF1), // Teal 100
        onPrimaryContainer: Color(0xFF115E59), // Teal 800
        secondary: Color(0xFF0F766E),        // Teal 700
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE2EBE5),
        onSecondaryContainer: Color(0xFF0F3A30),
        tertiary: Color(0xFF0369A1),         // Sky 700
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFE0F2FE),
        onTertiaryContainer: Color(0xFF0369A1),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF991B1B),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),        // Slate 900
        surfaceVariant: Color(0xFFE2EBE5),
        onSurfaceVariant: Color(0xFF3F4E46),  // Muted dark slate-green
        outline: Color(0xFFCBD5E1),          // Slate 300
        outlineVariant: Color(0xFFE2E8F0),
        background: Color(0xFFF4F7F5),       // Calm soft off-white background
        onBackground: Color(0xFF1E293B),     // Slate 800
        surfaceContainerLowest: Color(0xFFFAFAFA), // Softest tinted white
        surfaceContainerLow: Color(0xFFF4F7F5),
        surfaceContainer: Color(0xFFEDF1EE),
        surfaceContainerHigh: Color(0xFFE4EAE5),
        surfaceContainerHighest: Color(0xFFDBE2DC),
      );
    } else {
      return const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF2DD4BF),          // Teal 400
        onPrimary: Color(0xFF003733),
        primaryContainer: Color(0xFF0D9488), // Teal 600
        onPrimaryContainer: Color(0xFFCCFBF1),
        secondary: Color(0xFF14B8A6),        // Teal 500
        onSecondary: Color(0xFF003733),
        secondaryContainer: Color(0xFF202A25),
        onSecondaryContainer: Color(0xFFC0CDC6),
        tertiary: Color(0xFF38BDF8),         // Sky 400
        onTertiary: Color(0xFF00354E),
        tertiaryContainer: Color(0xFF0369A1),
        onTertiaryContainer: Color(0xFFE0F2FE),
        error: Color(0xFFF87171),
        onError: Color(0xFF550000),
        errorContainer: Color(0xFF991B1B),
        onErrorContainer: Color(0xFFFEE2E2),
        surface: Color(0xFF141A17),          // Dark teal-grey surface
        onSurface: Color(0xFFFAFAFA),
        surfaceVariant: Color(0xFF202A25),
        onSurfaceVariant: Color(0xFFC0CDC6),
        outline: Color(0xFF3E4E46),
        outlineVariant: Color(0xFF2E3B35),
        background: Color(0xFF0C110E),       // Elegant dark teal-grey background
        onBackground: Color(0xFFF4F7F5),
        surfaceContainerLowest: Color(0xFF090D0B), // Darkest container surface
        surfaceContainerLow: Color(0xFF0F1412),
        surfaceContainer: Color(0xFF141A17),
        surfaceContainerHigh: Color(0xFF1B221E),
        surfaceContainerHighest: Color(0xFF222B26),
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
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(4),
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: baseColorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.2),
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
            ? Colors.white
            : baseColorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseColorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: baseColorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.outline.withValues(alpha: 0.3);
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
                color: baseColorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              );
            }
            return BorderSide(color: baseColorScheme.primary, width: 1.2);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return baseColorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return baseColorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return baseColorScheme.primary.withValues(alpha: 0.12);
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
              return baseColorScheme.onSurfaceVariant.withValues(alpha: 0.5);
            }
            return baseColorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return baseColorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return baseColorScheme.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return baseColorScheme.outline;
            }
            return baseColorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return baseColorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.pressed)) {
              return baseColorScheme.primary.withValues(alpha: 0.12);
            }
            return null;
          }),
        ),
      ),
      
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(baseColorScheme.surfaceContainerHighest),
        headingTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: baseColorScheme.onSurfaceVariant,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return baseColorScheme.primary.withValues(alpha: 0.06);
          }
          return null;
        }),
        dataTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: baseColorScheme.onSurface,
        ),
        dividerThickness: 1,
        horizontalMargin: 16,
        columnSpacing: 20,
      ),
      
      dividerTheme: DividerThemeData(
        color: baseColorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
      
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brightness == Brightness.light
            ? baseColorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : baseColorScheme.background,
        selectedIconTheme: IconThemeData(color: baseColorScheme.primary),
        unselectedIconTheme: IconThemeData(color: baseColorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          color: baseColorScheme.primary,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        indicatorColor: baseColorScheme.primary.withValues(alpha: 0.12),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: baseColorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseColorScheme.primary,
        foregroundColor: baseColorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: baseColorScheme.surfaceContainerHighest,
        disabledColor: baseColorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        selectedColor: baseColorScheme.primary,
        secondarySelectedColor: baseColorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.onSurface,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          color: baseColorScheme.onPrimary,
        ),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }

  static final light = _buildTheme(Brightness.light);
  static final dark = _buildTheme(Brightness.dark);
}

