import 'dart:convert';

import 'prefs.dart';

class SkipSettings {
  final int intro;
  final int outro;
  const SkipSettings({this.intro = 0, this.outro = 0});

  SkipSettings copyWith({int? intro, int? outro}) => SkipSettings(
        intro: intro ?? this.intro,
        outro: outro ?? this.outro,
      );
}

class SkipStore {
  static String _key(String id) => 'skip_$id';

  static SkipSettings load(String id) {
    final raw = Prefs.instance.getString(_key(id));
    if (raw == null) return const SkipSettings();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SkipSettings(
        intro: (m['intro'] as num?)?.toInt() ?? 0,
        outro: (m['outro'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const SkipSettings();
    }
  }

  static Future<void> save(String id, SkipSettings s) async {
    await Prefs.instance.setString(
      _key(id),
      jsonEncode({'intro': s.intro, 'outro': s.outro}),
    );
  }
}
