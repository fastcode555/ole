import '../../core/format.dart';

class VideoItem {
  final String title;
  final String url;
  final String img;
  final String score;
  final String status;
  final String hot;
  final String quality;
  final String actors;

  const VideoItem({
    required this.title,
    required this.url,
    this.img = '',
    this.score = '',
    this.status = '',
    this.hot = '',
    this.quality = '',
    this.actors = '',
  });

  String? get vodId => extractVodId(url);
}
