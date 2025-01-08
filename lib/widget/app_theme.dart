import 'package:flutter/material.dart';

class AppTheme {
   // màu chính
  static const Color primaryColor = Color(0xFF1e3c72);
  // Màu phụ
  static const Color secondaryColor = Color(0xFF008080); 
  static const Color lightGrey = Color(0xFFF2F2F2);
  static const Color cardBackground = Color(0xFFF5F5F5);

  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      hintColor: Colors.grey,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        // thanh ứng dụng
        backgroundColor: Colors.white, 
        elevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
           color: primaryColor,
           fontWeight: FontWeight.w700,
           fontSize: 24,
        ),
      ),
      textTheme: _textTheme,
      inputDecorationTheme: _inputDecorationTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
  }


  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black87),
  );

  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.black38, width: 2.0)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.0)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      textStyle: const TextStyle(
        fontSize: 18.0,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
      ),
    ),
  );


  static TextStyle getHeadlineTextStyle() => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Poppins'
  );

  static TextStyle getLightTextStyle() => const TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.normal,
      color: Colors.black54
  );

  static TextStyle getBoldTextStyle() => const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w700
  );

  static TextStyle getSemiBoldTextStyle() => const TextStyle(
      fontSize: 17.0,
      fontWeight: FontWeight.w500
  );

}