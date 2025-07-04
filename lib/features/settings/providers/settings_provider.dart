import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Theme settings
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  // Notification settings
  bool _pushNotificationsEnabled = true;
  bool _chatNotificationsEnabled = true;
  bool _itemAlertsEnabled = true;
  bool _exchangeNotificationsEnabled = true;

  // Privacy settings
  bool _showOnlineStatus = true;
  bool _profileVisible = true;
  bool _showLocationToOthers = false;

  // Location settings
  bool _locationEnabled = true;
  double _searchRadius = 10.0;

  // Accessibility settings
  bool _highContrastEnabled = false;
  bool _largeTextEnabled = false;
  bool _screenReaderEnabled = false;
  bool _reducedMotionEnabled = false;
  double _textScaleFactor = 1.0;

  // Sound settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _soundVolume = 0.8;

  // Getters
  bool get darkModeEnabled => _darkModeEnabled;
  String get selectedLanguage => _selectedLanguage;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get chatNotificationsEnabled => _chatNotificationsEnabled;
  bool get itemAlertsEnabled => _itemAlertsEnabled;
  bool get exchangeNotificationsEnabled => _exchangeNotificationsEnabled;
  bool get showOnlineStatus => _showOnlineStatus;
  bool get profileVisible => _profileVisible;
  bool get showLocationToOthers => _showLocationToOthers;
  bool get locationEnabled => _locationEnabled;
  double get searchRadius => _searchRadius;
  bool get highContrastEnabled => _highContrastEnabled;
  bool get largeTextEnabled => _largeTextEnabled;
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get reducedMotionEnabled => _reducedMotionEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get soundVolume => _soundVolume;

  // Get selected locale
  Locale get selectedLocale {
    final languageCode = getLanguageCode();
    return Locale(languageCode, '');
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    _pushNotificationsEnabled =
        prefs.getBool('pushNotificationsEnabled') ?? true;
    _chatNotificationsEnabled =
        prefs.getBool('chatNotificationsEnabled') ?? true;
    _itemAlertsEnabled = prefs.getBool('itemAlertsEnabled') ?? true;
    _exchangeNotificationsEnabled =
        prefs.getBool('exchangeNotificationsEnabled') ?? true;
    _showOnlineStatus = prefs.getBool('showOnlineStatus') ?? true;
    _profileVisible = prefs.getBool('profileVisible') ?? true;
    _showLocationToOthers = prefs.getBool('showLocationToOthers') ?? false;
    _locationEnabled = prefs.getBool('locationEnabled') ?? true;
    _searchRadius = prefs.getDouble('searchRadius') ?? 10.0;
    _highContrastEnabled = prefs.getBool('highContrastEnabled') ?? false;
    _largeTextEnabled = prefs.getBool('largeTextEnabled') ?? false;
    _screenReaderEnabled = prefs.getBool('screenReaderEnabled') ?? false;
    _reducedMotionEnabled = prefs.getBool('reducedMotionEnabled') ?? false;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _soundVolume = prefs.getDouble('soundVolume') ?? 0.8;

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
    await prefs.setString('selectedLanguage', _selectedLanguage);
    await prefs.setBool('pushNotificationsEnabled', _pushNotificationsEnabled);
    await prefs.setBool('chatNotificationsEnabled', _chatNotificationsEnabled);
    await prefs.setBool('itemAlertsEnabled', _itemAlertsEnabled);
    await prefs.setBool(
      'exchangeNotificationsEnabled',
      _exchangeNotificationsEnabled,
    );
    await prefs.setBool('showOnlineStatus', _showOnlineStatus);
    await prefs.setBool('profileVisible', _profileVisible);
    await prefs.setBool('showLocationToOthers', _showLocationToOthers);
    await prefs.setBool('locationEnabled', _locationEnabled);
    await prefs.setDouble('searchRadius', _searchRadius);
    await prefs.setBool('highContrastEnabled', _highContrastEnabled);
    await prefs.setBool('largeTextEnabled', _largeTextEnabled);
    await prefs.setBool('screenReaderEnabled', _screenReaderEnabled);
    await prefs.setBool('reducedMotionEnabled', _reducedMotionEnabled);
    await prefs.setDouble('textScaleFactor', _textScaleFactor);
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setDouble('soundVolume', _soundVolume);
  }

  // Theme settings
  Future<void> toggleDarkMode() async {
    _darkModeEnabled = !_darkModeEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateLanguage(String language) async {
    _selectedLanguage = language;
    await _saveSettings();
    notifyListeners();
  }

  // Notification settings
  Future<void> togglePushNotifications() async {
    _pushNotificationsEnabled = !_pushNotificationsEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleChatNotifications() async {
    _chatNotificationsEnabled = !_chatNotificationsEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleItemAlerts() async {
    _itemAlertsEnabled = !_itemAlertsEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleExchangeNotifications() async {
    _exchangeNotificationsEnabled = !_exchangeNotificationsEnabled;
    await _saveSettings();
    notifyListeners();
  }

  // Privacy settings
  Future<void> toggleOnlineStatus() async {
    _showOnlineStatus = !_showOnlineStatus;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleProfileVisibility() async {
    _profileVisible = !_profileVisible;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleLocationSharing() async {
    _showLocationToOthers = !_showLocationToOthers;
    await _saveSettings();
    notifyListeners();
  }

  // Location settings
  Future<void> toggleLocation() async {
    _locationEnabled = !_locationEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateSearchRadius(double radius) async {
    _searchRadius = radius;
    await _saveSettings();
    notifyListeners();
  }

  // Accessibility settings
  Future<void> toggleHighContrast() async {
    _highContrastEnabled = !_highContrastEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleLargeText() async {
    _largeTextEnabled = !_largeTextEnabled;
    _textScaleFactor = _largeTextEnabled ? 1.3 : 1.0;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleScreenReader() async {
    _screenReaderEnabled = !_screenReaderEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleReducedMotion() async {
    _reducedMotionEnabled = !_reducedMotionEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateTextScale(double scale) async {
    _textScaleFactor = scale;
    await _saveSettings();
    notifyListeners();
  }

  // Sound settings
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateSoundVolume(double volume) async {
    _soundVolume = volume;
    await _saveSettings();
    notifyListeners();
  }

  String getLanguageCode() {
    switch (_selectedLanguage) {
      case 'French':
      case 'Français':
        return 'fr';
      default:
        return 'en';
    }
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'name': 'English', 'nativeName': 'English', 'code': 'en'},
      {'name': 'French', 'nativeName': 'Français', 'code': 'fr'},
    ];
  }

  // Get theme data based on settings
  ThemeData getThemeData(BuildContext context) {
    final baseTheme = _darkModeEnabled ? ThemeData.dark() : ThemeData.light();

    // Ensure text scale factor is valid
    final safeFontSizeFactor =
        (_textScaleFactor > 0.0 && _textScaleFactor <= 3.0)
            ? _textScaleFactor
            : 1.0;

    return baseTheme.copyWith(
      textTheme:
          safeFontSizeFactor != 1.0
              ? baseTheme.textTheme.apply(fontSizeFactor: safeFontSizeFactor)
              : baseTheme.textTheme,
      colorScheme:
          _highContrastEnabled
              ? (_darkModeEnabled
                  ? const ColorScheme.highContrastDark()
                  : const ColorScheme.highContrastLight())
              : baseTheme.colorScheme,
    );
  }
}
