import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  // Getter untuk mengecek apakah sedang dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Getter untuk dikirimkan ke MaterialApp
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme(); // Muat tema yang tersimpan saat aplikasi baru dibuka
  }

  void toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Beritahu seluruh aplikasi untuk ganti baju!

    // Simpan pilihan ke memori internal HP
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isOn);
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}