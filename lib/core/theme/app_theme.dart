import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seedColor = Color(0xFFC64600);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFBE6F),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 255, 241, 236),
      scrolledUnderElevation: 0,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w600,
        color: Color(0xFFC64600),
        letterSpacing: 1.2,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
