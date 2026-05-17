import 'dart:convert';

import 'prefs.dart';

class ProgressEntry {
  final int epIdx;
  final double time;
  const ProgressEntry({required this.epIdx, required this.time});
}

/// 对应 web 版的 `progress_<id>` / `lastep_<id>` / `lastep_<id>_title`
class ProgressStore {
  static String _progressKey(String id) => 'progress_$id';
  static String _lastEpKey(String id) => 'lastep_$id';
  static String _lastEpTitleKey(String id) => 'lastep_${id}_title';

  // ── 播放进度 ──
  static ProgressEntry? loadProgress(String id) {
    final raw = Prefs.instance.getString(_progressKey(id));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ProgressEntry(
        epIdx: (m['epIdx'] as num?)?.toInt() ?? -1,
        time: (m['time'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProgress(String id, int epIdx, double time) async {
    await Prefs.instance.setString(
      _progressKey(id),
      jsonEncode({'epIdx': epIdx, 'time': time}),
    );
  }

  // ── 上次集数 ──
  static int getLastEp(String id) {
    final v = Prefs.instance.getString(_lastEpKey(id));
    return v == null ? -1 : (int.tryParse(v) ?? -1);
  }

  static Future<void> setLastEp(String id, int idx) async {
    await Prefs.instance.setString(_lastEpKey(id), '$idx');
  }

  // ── 上次集数标题（用于卡片"看到 xx"）──
  /// 标题原样保存；电影类（单集 "播放"）保存为 `__time__<seconds>`
  static String? getLastEpTitle(String id) =>
      Prefs.instance.getString(_lastEpTitleKey(id));

  static Future<void> setLastEpTitle(String id, String title) async {
    await Prefs.instance.setString(_lastEpTitleKey(id), title);
  }

  /// 卡片显示的"看到 xx"文本
  static String? watchedLabel(String id) {
    final t = getLastEpTitle(id);
    if (t == null || t.isEmpty) return null;
    if (t.startsWith('__time__')) {
      final s = int.tryParse(t.substring('__time__'.length)) ?? 0;
      return '看到 ${_fmt(s)}';
    }
    return '看到 $t';
  }

  static String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    String pad(int n) => n < 10 ? '0$n' : '$n';
    if (h > 0) return '$h:${pad(m)}:${pad(sec)}';
    return '${pad(m)}:${pad(sec)}';
  }
}
