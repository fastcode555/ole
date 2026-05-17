import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../core/update_detector.dart';
import '../data/models/video_item.dart';
import '../data/storage/favorites_store.dart';
import 'video_card.dart';

class VideoGrid extends StatelessWidget {
  final List<VideoItem> items;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const VideoGrid({
    super.key,
    required this.items,
    this.shrinkWrap = false,
    this.physics,
  });

  /// 排序优先级（数字越小越靠前）：
  ///   0 = 收藏 + 有更新（最重要，第一时间看到）
  ///   1 = 收藏
  ///   2 = 其余
  /// 同优先级内保持 API 返回的原始顺序（稳定排序）。
  int _priority(VideoItem item, FavoritesStore favs) {
    final faved = favs.isFav(item.vodId);
    if (!faved) return 2;
    if (hasUpdate(item)) return 0;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final cols = Responsive.gridColumns(context);
    final favs = context.watch<FavoritesStore>();
    final indexed = items
        .asMap()
        .entries
        .map((e) => (idx: e.key, item: e.value))
        .toList();
    indexed.sort((a, b) {
      final pa = _priority(a.item, favs);
      final pb = _priority(b.item, favs);
      if (pa != pb) return pa - pb;
      return a.idx - b.idx; // 同层级保持原顺序
    });
    final sorted = indexed.map((e) => e.item).toList();

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) => VideoCard(item: sorted[i]),
    );
  }
}
