import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorage {
  static const _stylesKey = 'profile_styles';
  static const _unitKey = 'profile_unit_cm';

  static const _chestKey = 'profile_chest';
  static const _waistKey = 'profile_waist';
  static const _shoulderKey = 'profile_shoulder';
  static const _heightKey = 'profile_height';

  static Future<void> saveStyles(List<String> styles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_stylesKey, styles);
  }

  static Future<List<String>> loadStyles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_stylesKey) ?? [];
  }

  static Future<void> saveUnit(bool useCm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unitKey, useCm);
  }

  static Future<bool> loadUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unitKey) ?? true;
  }

  static Future<void> saveMeasurements({
    required String chest,
    required String waist,
    required String shoulder,
    required String height,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chestKey, chest);
    await prefs.setString(_waistKey, waist);
    await prefs.setString(_shoulderKey, shoulder);
    await prefs.setString(_heightKey, height);
  }

  static Future<Map<String, String>> loadMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'chest': prefs.getString(_chestKey) ?? '',
      'waist': prefs.getString(_waistKey) ?? '',
      'shoulder': prefs.getString(_shoulderKey) ?? '',
      'height': prefs.getString(_heightKey) ?? '',
    };
  }
}
