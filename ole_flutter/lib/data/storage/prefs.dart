import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get instance {
    final p = _prefs;
    if (p == null) {
      throw StateError('Prefs.init() must be awaited first');
    }
    return p;
  }
}
