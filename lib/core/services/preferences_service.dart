import 'package:shared_preferences/shared_preferences.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

/// Service for managing app preferences and local storage
class PreferencesService {
  static PreferencesService? _instance;
  static PreferencesService get instance => _instance ??= PreferencesService._();

  PreferencesService._();

  SharedPreferences? _prefs;

  /// Initialize the preferences service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Log.d('Preferences service initialized');
    } catch (error) {
      Log.e('Error initializing preferences service: $error');
    }
  }

  /// Get the SharedPreferences instance
  SharedPreferences? get prefs => _prefs;

  // ---- REMEMBER ME FUNCTIONALITY --------------------------------

  /// Save remember me preference
  Future<bool> setRememberMe(bool rememberMe) async {
    try {
      if (_prefs == null) await initialize();
      final result = await _prefs!.setBool('remember_me', rememberMe);
      Log.d('Remember me preference saved: $rememberMe');
      return result;
    } catch (error) {
      Log.e('Error saving remember me preference: $error');
      return false;
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    try {
      if (_prefs == null) await initialize();
      final rememberMe = _prefs!.getBool('remember_me') ?? false;
      Log.d('Remember me preference retrieved: $rememberMe');
      return rememberMe;
    } catch (error) {
      Log.e('Error getting remember me preference: $error');
      return false;
    }
  }

  /// Save user credentials when remember me is enabled
  Future<bool> saveCredentials(String email, String password) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.setString('saved_email', email);
      await _prefs!.setString('saved_password', password);
      Log.d('User credentials saved for remember me');
      return true;
    } catch (error) {
      Log.e('Error saving credentials: $error');
      return false;
    }
  }

  /// Get saved user credentials
  Future<Map<String, String?>> getSavedCredentials() async {
    try {
      if (_prefs == null) await initialize();
      final email = _prefs!.getString('saved_email');
      final password = _prefs!.getString('saved_password');
      Log.d('Saved credentials retrieved: ${email != null ? 'email present' : 'no email'}');
      return {'email': email, 'password': password};
    } catch (error) {
      Log.e('Error getting saved credentials: $error');
      return {'email': null, 'password': null};
    }
  }

  /// Clear saved credentials
  Future<bool> clearSavedCredentials() async {
    try {
      if (_prefs == null) await initialize();
      await _prefs!.remove('saved_email');
      await _prefs!.remove('saved_password');
      Log.d('Saved credentials cleared');
      return true;
    } catch (error) {
      Log.e('Error clearing saved credentials: $error');
      return false;
    }
  }

  // ---- SESSION PERSISTENCE --------------------------------------

  /// Save session persistence preference
  Future<bool> setSessionPersistence(bool persist) async {
    try {
      if (_prefs == null) await initialize();
      final result = await _prefs!.setBool('session_persistence', persist);
      Log.d('Session persistence preference saved: $persist');
      return result;
    } catch (error) {
      Log.e('Error saving session persistence preference: $error');
      return false;
    }
  }

  /// Get session persistence preference
  Future<bool> getSessionPersistence() async {
    try {
      if (_prefs == null) await initialize();
      final persist = _prefs!.getBool('session_persistence') ?? true; // Default to true
      Log.d('Session persistence preference retrieved: $persist');
      return persist;
    } catch (error) {
      Log.e('Error getting session persistence preference: $error');
      return true; // Default to true on error
    }
  }

  // ---- GENERAL PREFERENCE METHODS ------------------------------

  /// Save a string preference
  Future<bool> setString(String key, String value) async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.setString(key, value);
    } catch (error) {
      Log.e('Error saving string preference $key: $error');
      return false;
    }
  }

  /// Get a string preference
  Future<String?> getString(String key) async {
    try {
      if (_prefs == null) await initialize();
      return _prefs!.getString(key);
    } catch (error) {
      Log.e('Error getting string preference $key: $error');
      return null;
    }
  }

  /// Save a boolean preference
  Future<bool> setBool(String key, bool value) async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.setBool(key, value);
    } catch (error) {
      Log.e('Error saving boolean preference $key: $error');
      return false;
    }
  }

  /// Get a boolean preference
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      if (_prefs == null) await initialize();
      return _prefs!.getBool(key) ?? defaultValue;
    } catch (error) {
      Log.e('Error getting boolean preference $key: $error');
      return defaultValue;
    }
  }

  /// Remove a preference
  Future<bool> remove(String key) async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.remove(key);
    } catch (error) {
      Log.e('Error removing preference $key: $error');
      return false;
    }
  }

  /// Clear all preferences
  Future<bool> clear() async {
    try {
      if (_prefs == null) await initialize();
      return await _prefs!.clear();
    } catch (error) {
      Log.e('Error clearing preferences: $error');
      return false;
    }
  }
}
