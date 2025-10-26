// ...existing code...
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String babyName = '';
  String babyGender = ''; // expected values: "Boy","Girl","Other"

  void setProfile(String name, String gender) {
    babyName = name;
    babyGender = gender;
    notifyListeners();
  }

  ThemeData get currentTheme {
    final gender = babyGender.toLowerCase();
    if (gender.contains('boy') || gender == 'male') {
      return _blueTheme;
    } else if (gender.contains('girl') || gender == 'female') {
      return _pinkTheme;
    }
    return _neutralTheme;
  }

  // Neutral: orange, cream, brown
  static final ThemeData _neutralTheme = ThemeData(
    primaryColor: const Color(0xFFEF6C00), // orange
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEF6C00),
      primary: const Color(0xFFEF6C00),
      secondary: const Color(0xFFFFE0B2), // cream
      surface: const Color(0xFFFFF3E0),
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF3E0),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFD84315)),
    useMaterial3: true,
  );

  // Boy: blue shades
  static final ThemeData _blueTheme = ThemeData(
    primaryColor: Colors.blue.shade700,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: Colors.blue.shade700,
      secondary: Colors.blue.shade100,
      surface: Colors.blue.shade50,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.blue.shade50,
    appBarTheme: AppBarTheme(backgroundColor: Colors.blue.shade800),
    useMaterial3: true,
  );

  // Girl: pink shades
  static final ThemeData _pinkTheme = ThemeData(
    primaryColor: Colors.pink.shade600,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pink,
      primary: Colors.pink.shade600,
      secondary: Colors.pink.shade100,
      surface: Colors.pink.shade50,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.pink.shade50,
    appBarTheme: AppBarTheme(backgroundColor: Colors.pink.shade700),
    useMaterial3: true,
  );
}

final appState = AppState();
// ...existing code...