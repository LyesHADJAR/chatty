import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Dark mode theme
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: const Color(0xFF121212),
    primary: const Color(0xFF5B7FFF), // Lighter Royal Blue for dark mode
    secondary: const Color(0xFF252525),
    tertiary: const Color(0xFF353535),
    surface: const Color(0xFF1E1E1E),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.white,
    onSurface: Colors.white,
    error: Colors.red.shade300,
    onError: Colors.white,
  ),
  
  // Use Montserrat font for all text
  textTheme: GoogleFonts.montserratTextTheme(
    const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: Colors.white),
      labelSmall: TextStyle(color: Colors.white70),
    ),
  ),
  
  // Card theme
  cardTheme: CardTheme(
    color: const Color(0xFF1E1E1E),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    shadowColor: Colors.black.withOpacity(0.3),
  ),
  
  // AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF121212),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.montserrat(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  
  // Button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5B7FFF),
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
      foregroundColor: const Color(0xFF5B7FFF),
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
    fillColor: const Color(0xFF252525),
    hintStyle: GoogleFonts.montserrat(
      color: Colors.grey.shade400,
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
      borderSide: const BorderSide(color: Color(0xFF5B7FFF), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
    ),
  ),
  
  // Tab bar theme
  tabBarTheme: TabBarTheme(
    labelColor: const Color(0xFF5B7FFF),
    unselectedLabelColor: Colors.grey.shade400,
    indicatorColor: const Color(0xFF5B7FFF),
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
    backgroundColor: Color(0xFF5B7FFF),
    foregroundColor: Colors.white,
    elevation: 2,
    shape: CircleBorder(),
  ),
  
  // Divider theme
  dividerTheme: DividerThemeData(
    color: Colors.grey.shade800,
    thickness: 1,
    space: 32,
  ),
  
  // Icon theme
  iconTheme: IconThemeData(
    color: Colors.grey.shade300,
    size: 24,
  ),
  
  // Switch theme
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF5B7FFF);
      }
      return Colors.grey.shade600;
    }),
    trackColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF5B7FFF).withOpacity(0.5);
      }
      return Colors.grey.shade700;
    }),
  ),
  
  // Checkbox theme
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF5B7FFF);
      }
      return Colors.grey.shade600;
    }),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
  
  // Radio theme
  radioTheme: RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return const Color(0xFF5B7FFF);
      }
      return Colors.grey.shade600;
    }),
  ),
  
  // Scaffold background color
  scaffoldBackgroundColor: const Color(0xFF121212),
  
  // Dialog theme
  dialogTheme: DialogTheme(
    backgroundColor: const Color(0xFF1E1E1E),
    elevation: 5,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    titleTextStyle: GoogleFonts.montserrat(
      color: Colors.white, 
      fontSize: 20, 
      fontWeight: FontWeight.w600
    ),
    contentTextStyle: GoogleFonts.montserrat(
      color: Colors.white, 
      fontSize: 16
    ),
  ),
);