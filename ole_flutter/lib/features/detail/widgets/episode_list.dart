import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/episode.dart';

class EpisodeList extends StatelessWidget {
  final List<Episode> episodes;
  final int currentIdx;
  final int lastWatchedIdx;
  final ValueChanged<int> onTap;

  const EpisodeList({
    super.key,
    required this.episodes,
    required this.currentIdx,
    required this.lastWatchedIdx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '播放列表（${episodes.length}${episodes.length == 1 ? '部' : '集'}）',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (lastWatchedIdx >= 0 &&
                lastWatchedIdx < episodes.length) ...[
              const SizedBox(width: 12),
              Text(
                '上次看到：${episodes[lastWatchedIdx].title}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentSoft,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < episodes.length; i++)
              _EpButton(
                title: episodes[i].title +
                    (i == lastWatchedIdx && i != currentIdx ? ' ▶' : ''),
                active: i == currentIdx,
                lastWatched: i == lastWatchedIdx && i != currentIdx,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _EpButton extends StatelessWidget {
  final String title;
  final bool active;
  final bool lastWatched;
  final VoidCallback onTap;
  const _EpButton({
    required this.title,
    required this.active,
    required this.lastWatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppTheme.surfaceAlt;
    Color fg = AppTheme.textPrimary;
    Color? borderColor;
    if (active) {
      bg = AppTheme.accent;
      fg = Colors.white;
    } else if (lastWatched) {
      bg = AppTheme.surface;
      fg = AppTheme.accentSoft;
      borderColor = AppTheme.accentSoft.withValues(alpha: 0.6);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: fg,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
