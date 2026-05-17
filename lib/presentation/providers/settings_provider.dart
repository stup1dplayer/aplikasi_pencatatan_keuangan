import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _dailyLimit = 0.0;

  double get dailyLimit => _dailyLimit;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyLimit = prefs.getDouble('dailyLimit') ?? 0.0;
    notifyListeners();
  }

  Future<void> setDailyLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dailyLimit', limit);
    _dailyLimit = limit;
    notifyListeners();
  }
}