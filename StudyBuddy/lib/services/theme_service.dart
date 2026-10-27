import 'package:shared_preferences/shared_preferences.dart'; // Device storage

// Reads and writes the selected colour scheme and brightness mode to device storage.
class ThemeService {
  // SharedPreferences key for the saved colour scheme.
  static const String _schemeKey = 'colour_scheme';

  // SharedPreferences key for the saved brightness mode.
  static const String _modeKey = 'brightness_mode';

  // Saves the colour scheme name to device storage.
  Future<void> setTheme(String schemeName) async {
    final prefs = await SharedPreferences.getInstance(); // Opens device storage
    await prefs.setString(_schemeKey, schemeName); // Writes the scheme name
  }

  // Reads the saved colour scheme name from device storage.
  // Returns null when no scheme has been saved yet.
  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance(); // Opens device storage
    return prefs.getString(_schemeKey); // Reads the scheme name
  }

  // Saves the brightness mode name to device storage.
  Future<void> setBrightnessMode(String modeName) async {
    final prefs = await SharedPreferences.getInstance(); // Opens device storage
    await prefs.setString(_modeKey, modeName); // Writes the mode name
  }

  // Reads the saved brightness mode name from device storage.
  // Returns null when no mode has been saved yet.
  Future<String?> getBrightnessMode() async {
    final prefs = await SharedPreferences.getInstance(); // Opens device storage
    return prefs.getString(_modeKey); // Reads the mode name
  }
}