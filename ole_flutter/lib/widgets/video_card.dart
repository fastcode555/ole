import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/models/video_item.dart';
import '../data/storage/favorites_store.dart';
import '../data/storage/progress_store.dart';

class VideoCard extends StatelessWidget {
  final VideoItem item;
  const VideoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final id = item.vodId;
    final favs = context.watch<FavoritesStore>();
    final faved = favs.isFav(id);
    final watched = id != null ? ProgressStore.watchedLabel(id) : null;

    return GestureDetector(
      onTap: () {
        if (id != null) context.go('/detail/$id');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: faved ? AppTheme.accent.withValues(alpha: 0.6) : AppTheme.border,
            width: faved ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.img.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: item.img,
                      fit: BoxFit.cover,
                      httpHeaders: const {'Referer': 'https://www.olehdtv.com'},
                      placeholder: (c, _) => Container(
                        color: AppTheme.surfaceAlt,
                        alignment: Alignment.center,
                        child: const Text('🎬',
                            style: TextStyle(fontSize: 32)),
                      ),
                      errorWidget: (c, _, __) => Container(
                        color: AppTheme.surfaceAlt,
                        alignment: Alignment.center,
                        child: const Text('🎬',
                            style: TextStyle(fontSize: 32)),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceAlt,
                      alignment: Alignment.center,
                      child:
                          const Text('🎬', style: TextStyle(fontSize: 32)),
                    ),
                  // 顶部：评分 / 清晰度
                  Positioned(
                    left: 6,
                    right: 6,
                    top: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.score.isNotEmpty)
                          _Pill(
                            text: item.score,
                            color: AppTheme.score,
                            fg: Colors.black,
                          )
                        else
                          const SizedBox.shrink(),
                        if (item.quality.isNotEmpty)
                          _Pill(
                            text: item.quality,
                            color: Colors.black.withValues(alpha: 0.65),
                            fg: Colors.white,
                          ),
                      ],
                    ),
                  ),
                  // 底部：热度 / 收藏
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (item.hot.isNotEmpty)
                          _Pill(
                            text: '🔥 ${formatHot(item.hot)}',
                            color: Colors.black.withValues(alpha: 0.6),
                            fg: AppTheme.hot,
                          )
                        else
                          const SizedBox.shrink(),
                        _FavButton(
                          faved: faved,
                          onTap: () {
                            if (id != null) favs.toggle(id);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Expanded 让信息区吃掉图片下方的剩余空间，避免出现底部空白带。
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (item.status.isNotEmpty || watched != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.status.isNotEmpty)
                          Expanded(
                            child: Text(
                              item.status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        if (watched != null)
                          Text(
                            watched,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentSoft,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (item.actors.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.actors.split(RegExp(r'\s+')).take(3).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color fg;
  const _Pill({required this.text, required this.color, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _FavButton extends StatelessWidget {
  final bool faved;
  final VoidCallback onTap;
  const _FavButton({required this.faved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          faved ? '❤️' : '🤍',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
