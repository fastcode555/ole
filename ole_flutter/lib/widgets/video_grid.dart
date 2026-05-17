import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
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

  @override
  Widget build(BuildContext context) {
    final cols = Responsive.gridColumns(context);
    // 监听收藏变化以重排序
    final favs = context.watch<FavoritesStore>();
    final sorted = [...items]
      ..sort((a, b) {
        final fa = favs.isFav(a.vodId);
        final fb = favs.isFav(b.vodId);
        if (fa == fb) return 0;
        return fa ? -1 : 1;
      });

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) => VideoCard(item: sorted[i]),
    );
  }
}
