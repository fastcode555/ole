import '../data/models/video_item.dart';
import '../data/storage/progress_store.dart';
import 'format.dart';

/// 判断"已收藏的剧有新一集未看"。
///
/// 规则：列表里的 `status`（如"更新至30集"）和本地存的 `lastep_<id>_title`
/// （如"第15集"）都能抽出集数，且 status > lastWatched 视为有更新。
///
/// 抽不出数字（电影、综艺，或 status 为"已完结"/"高清"）一律返回 false。
bool hasUpdate(VideoItem item) {
  final id = item.vodId;
  if (id == null) return false;
  final lastTitle = ProgressStore.getLastEpTitle(id);
  if (lastTitle == null || lastTitle.isEmpty) return false;
  if (lastTitle.startsWith('__time__')) return false; // 电影类，无集数概念
  final lastEp = extractEpNum(lastTitle);
  final latestEp = extractEpNum(item.status);
  if (lastEp == null || latestEp == null) return false;
  return latestEp > lastEp;
}
