import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Settings provider for app preferences and local profile
class SettingsProvider extends ChangeNotifier {
  String _currencyCode = AppConstants.defaultCurrency;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isBalanceVisible = true;
  String? _ownerName;
  String? _ownerEmail;
  bool _isSetupComplete = false;

  // Getters
  String get currencyCode => _currencyCode;
  ThemeMode get themeMode => _themeMode;
  bool get isBalanceVisible => _isBalanceVisible;
  String? get ownerName => _ownerName;
  String? get ownerEmail => _ownerEmail;
  bool get isSetupComplete => _isSetupComplete;

  /// Load settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currencyCode = prefs.getString('currency_code') ?? AppConstants.defaultCurrency;
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == prefs.getString('theme_mode'),
      orElse: () => ThemeMode.system,
    );
    _isBalanceVisible = prefs.getBool('balance_visible') ?? true;
    _ownerName = prefs.getString('owner_name');
    _ownerEmail = prefs.getString('owner_email');
    _isSetupComplete = prefs.getBool('setup_complete') ?? false;
    
    notifyListeners();
  }

  /// Set currency code (only allowed before financial records exist)
  Future<void> setCurrencyCode(String code) async {
    if (_currencyCode == code) return;
    
    _currencyCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    
    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    
    notifyListeners();
  }

  /// Toggle balance visibility
  Future<void> toggleBalanceVisibility() async {
    _isBalanceVisible = !_isBalanceVisible;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', _isBalanceVisible);
    
    notifyListeners();
  }

  /// Set owner name
  Future<void> setOwnerName(String name) async {
    _ownerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owner_name', name);
    
    notifyListeners();
  }

  /// Set owner email
  Future<void> setOwnerEmail(String email) async {
    _ownerEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('owner_email', email);
    
    notifyListeners();
  }

  /// Mark setup as complete
  Future<void> markSetupComplete() async {
    _isSetupComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setup_complete', true);
    
    notifyListeners();
  }

  /// Reset all settings (for clear data)
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _currencyCode = AppConstants.defaultCurrency;
    _themeMode = ThemeMode.system;
    _isBalanceVisible = true;
    _ownerName = null;
    _ownerEmail = null;
    _isSetupComplete = false;
    
    notifyListeners();
  }

  /// Get greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Get personalized greeting with owner name
  String getPersonalizedGreeting() {
    final greeting = getGreeting();
    if (_ownerName != null && _ownerName!.isNotEmpty) {
      return '$greeting, $_ownerName!';
    }
    return greeting;
  }
}
