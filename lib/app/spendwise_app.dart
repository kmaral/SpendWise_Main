import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/main_screen.dart';
import '../screens/splash_screen.dart';

class SpendWiseApp extends StatefulWidget {
  const SpendWiseApp({super.key});

  @override
  State<SpendWiseApp> createState() => _SpendWiseAppState();
}

class _SpendWiseAppState extends State<SpendWiseApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _currency = '₹';
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final prefsLoad = SharedPreferences.getInstance();
    await Future.wait([
      prefsLoad,
      Future.delayed(const Duration(milliseconds: 3500)),
    ]);
    final prefs = await prefsLoad;
    if (mounted) {
      setState(() {
        _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
        _currency = prefs.getString('currency') ?? '₹';
        _showSplash = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
        _currency = prefs.getString('currency') ?? '₹';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _showSplash
            ? const SplashScreen(key: ValueKey('splash'))
            : MainScreen(
                key: const ValueKey('main'),
                currency: _currency,
                onSettingsChanged: _loadSettings,
              ),
      ),
    );
  }
}
