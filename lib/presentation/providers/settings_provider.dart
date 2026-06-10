import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _dailyLimit = 0.0;
  String _profileName = 'Catat Cepat'; // <-- Default nama awal

  double get dailyLimit => _dailyLimit;
  String get profileName => _profileName; // <-- Getter nama

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyLimit = prefs.getDouble('dailyLimit') ?? 0.0;
    _profileName = prefs.getString('profileName') ?? 'Catat Cepat'; // <-- Ambil data nama
    notifyListeners();
  }

  Future<void> setDailyLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dailyLimit', limit);
    _dailyLimit = limit;
    notifyListeners();
  }

  // --- FUNGSI BARU UNTUK SIMPAN NAMA ---
  Future<void> setProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileName', name.isEmpty ? 'Catat Cepat' : name);
    _profileName = name.isEmpty ? 'Catat Cepat' : name;
    notifyListeners();
  }
}