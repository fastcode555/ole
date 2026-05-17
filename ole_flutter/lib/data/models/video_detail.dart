import 'episode.dart';

class VideoDetail {
  final String title;
  final String cover;
  final String desc;
  final String score;
  final List<Episode> episodes;

  const VideoDetail({
    required this.title,
    this.cover = '',
    this.desc = '',
    this.score = '',
    this.episodes = const [],
  });
}
