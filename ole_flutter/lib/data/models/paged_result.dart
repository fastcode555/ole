import 'video_item.dart';

class PagedResult {
  final List<VideoItem> items;
  final int page;
  final int? total;

  const PagedResult({
    required this.items,
    required this.page,
    this.total,
  });

  int? get totalPages => total == null ? null : (total! / 24).ceil();
}
