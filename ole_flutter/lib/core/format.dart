/// 热度数字格式化（对应 web 版 formatHot）。
String formatHot(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final n = int.tryParse(raw) ?? 0;
  if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}万';
  return n.toString();
}

String _pad(int n) => n < 10 ? '0$n' : '$n';

/// 秒 → HH:MM:SS / MM:SS
String formatTime(num seconds) {
  final s = seconds.floor();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (h > 0) return '$h:${_pad(m)}:${_pad(sec)}';
  return '${_pad(m)}:${_pad(sec)}';
}

/// 同上但用于「看到 xx」的简短显示
String formatTimeShort(num seconds) => formatTime(seconds);

/// 把详情页 a 标签里的 vodId 抽出来：/index.php/vod/detail/id/12345.html → 12345
String? extractVodId(String? url) {
  if (url == null) return null;
  final m = RegExp(r'/id/(\d+)').firstMatch(url);
  return m?.group(1);
}

/// 从"更新至30集" / "第15集" / "更新到第8集" 等字符串里抽集数。
/// 抽不到（如"已完结"、"高清"、"HD"）就返回 null。
int? extractEpNum(String? s) {
  if (s == null || s.isEmpty) return null;
  final m = RegExp(r'(\d+)').firstMatch(s);
  return m == null ? null : int.tryParse(m.group(1)!);
}
