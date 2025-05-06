import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Light mode theme
ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF4169E1), // Royal Blue
    secondary: Colors.grey.shade200,
    tertiary: Colors.grey.shade300,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.black87,
    onSurface: Colors.black87,
    error: Colors.red.shade700,
    onError: Colors.white,
  ),
  
  // Use Montserrat font for all text
  textTheme: GoogleFonts.montserratTextTheme(
    const TextTheme(
      displayLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
      labelLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Colors.black87),
      labelSmall: TextStyle(color: Colors.black54),
    ),
  ),
  
  // Card theme
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    shadowColor: Colors.black.withOpacity(0.1),
  ),
  
  // AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.montserrat(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
  ),
  
  // Button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4169E1),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
    ),
  ),
  
  // Text button theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF4169E1),
      textStyle: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  ),
  
  // Input decoration theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100,
    hintStyle: GoogleFonts.montserrat(
      color: Colors.grey.shade500,
      fontSize: 16,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF4169E1), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
    ),
  ),
  
  // Tab bar theme
  tabBarTheme: TabBarTheme(
    labelColor: const Color(0xFF4169E1),
    unselectedLabelColor: Colors.grey.shade600,
    indicatorColor: const Color(0xFF4169E1),
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: GoogleFonts.montserrat(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    unselectedLabelStyle: GoogleFonts.montserrat(
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
  ),
  
  // Floating action button theme
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF4169E1),
    foregroundColor: Colors.white,
    elevation: 2,
    shape: CircleBorder(),
  ),
  
  // Divider theme
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade200,
    thickness: 1,
    space: 32,
  ),
  
  // Icon theme
  iconTheme: IconThemeData(
    color: Colors.grey.shade700,
    size: 24,
  ),
  
  // Switch theme
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF4169E1);
      }
      return Colors.grey.shade400;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF4169E1).withOpacity(0.5);
      }
      return Colors.grey.shade300;
    }),
  ),
  
  // Checkbox theme
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF4169E1);
      }
      return Colors.grey.shade300;
    }),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
  
  // Radio theme
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF4169E1);
      }
      return Colors.grey.shade300;
    }),
  ),
  
  // Scaffold background color
  scaffoldBackgroundColor: Colors.white,
  
  // Dialog theme
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: GoogleFonts.montserrat(
      color: Colors.black87, 
      fontSize: 20, 
      fontWeight: FontWeight.w600
    ),
    contentTextStyle: GoogleFonts.montserrat(
      color: Colors.black87, 
      fontSize: 16
    ),
  ),
);