import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    // Brand Colors
    primary: Color(0xFFf5872a),
    onPrimary: Color(0xFF000000), // Primary Text
    secondary: Color(0xFFd06a1a),
    onSecondary: Color(0xFF000000), // Primary Text
    tertiary: Color(0xFFa35311),
    onTertiary: Color(0xFF000000), // Assuming primary text on tertiary
    
    // Utility & Surface Colors
    surface: Color(0xFFf5f5f5), // Primary Background
    onSurface: Color(0xFF000000), // Primary Text
    surfaceContainer: Color(0xFFffffff), // Secondary Background (Alternate)
    
    // Error & Other Colors
    error: Color(0xFFd6534f),
    onError: Color(0xFFffffff), // White text on error color
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    // Brand Colors
    primary: Color(0xFFf5872a),
    onPrimary: Color(0xFFffffff), // Secondary Text (ou Primary Text)
    secondary: Color(0xFFd06a1a),
    onSecondary: Color(0xFFffffff), // Secondary Text
    tertiary: Color(0xFFa35311),
    onTertiary: Color(0xFFffffff), // White text on tertiary
    
    // Utility & Surface Colors
    surface: Color(0xFF000000), // Primary Background
    onSurface: Color(0xFFf5f5f5), // Primary Text
    surfaceContainer: Color(0xFF666666), // Secondary Background
    
    // Error & Other Colors
    error: Color(0xFFd6534f),
    onError: Color(0xFFffffff),
   ) // White text on error color
);