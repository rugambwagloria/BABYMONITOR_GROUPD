import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login.dart';
import 'baby_profile_page.dart';
import 'parent_tips_page.dart';
import 'settings_page.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // initialize DB
  runApp(const BabyMonitorApp());
}

class BabyMonitorApp extends StatefulWidget {
  const BabyMonitorApp({super.key});

  @override
  State<BabyMonitorApp> createState() => _BabyMonitorAppState();
}

class _BabyMonitorAppState extends State<BabyMonitorApp> {
  final ThemeMode _themeMode = ThemeMode.light;
  ColorScheme _accentScheme = _neutralScheme;

  static const _neutralScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFF8A00), // orange
    onPrimary: Colors.white,
    secondary: Color(0xFF6D4C41), // brown
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  static const _blueScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF42A5F5),
    onPrimary: Colors.white,
    secondary: Color(0xFF1565C0),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  static const _pinkScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFF48FB1),
    onPrimary: Colors.white,
    secondary: Color(0xFFC2185B),
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final db = DatabaseHelper.instance;
    final settings = await db.getSettings();
    if (settings != null) {
      final theme = settings['theme'] as String?;
      if (theme == 'blue') {
        setState(() => _accentScheme = _blueScheme);
      } else if (theme == 'pink') {
        setState(() => _accentScheme = _pinkScheme);
      } else {
        setState(() => _accentScheme = _neutralScheme);
      }
    }
  }

  void updateTheme(String themeKey) async {
    final db = DatabaseHelper.instance;
    await db.setSettings({'theme': themeKey});
    if (themeKey == 'blue') {
      setState(() => _accentScheme = _blueScheme);
    } else if (themeKey == 'pink') {
      setState(() => _accentScheme = _pinkScheme);
    } else {
      setState(() => _accentScheme = _neutralScheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _accentScheme;
    return MaterialApp(
      title: 'Baby Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.from(colorScheme: colorScheme, useMaterial3: true)
          .copyWith(
        appBarTheme: AppBarTheme(backgroundColor: colorScheme.primary),
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: colorScheme.primary),
      ),
      home: const LoginPage(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const BabyProfilePage(),
        '/tips': (_) => const ParentTipsPage(),
        '/settings': (_) => SettingsPage(onThemeChange: updateTheme),
      },
    );
  }
}
