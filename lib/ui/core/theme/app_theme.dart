import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final primaryColor = Colors.deepPurpleAccent;
  static final buttonStyle = ButtonStyle(
    foregroundColor: WidgetStateColor.resolveWith((states) => Colors.white),
    backgroundColor: WidgetStateColor.resolveWith((states) => primaryColor),
    textStyle: WidgetStateTextStyle.resolveWith(
      (states) => TextStyle(fontWeight: FontWeight.w600),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    padding: WidgetStateProperty.resolveWith(
      (states) => EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: primaryColor,
    disabledColor: Colors.deepPurpleAccent.shade100,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyLarge: const TextStyle(color: Colors.black, fontSize: 24),
      bodyMedium: const TextStyle(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder()),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: buttonStyle),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  );
}
