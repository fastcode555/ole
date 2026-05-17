import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models/video_item.dart';
import '../../data/scraper/ole_scraper.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_view.dart';
import '../../widgets/video_grid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, List<VideoItem>>> _future;

  @override
  void initState() {
    super.initState();
    _future = OleScraper.instance.fetchHome();
  }

  void _reload() {
    setState(() {
      _future = OleScraper.instance.fetchHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<Map<String, List<VideoItem>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const StatusView(message: '加载中...', loading: true);
            }
            if (snap.hasError) {
              return StatusView(
                message: '加载失败：${snap.error}',
                onRetry: _reload,
              );
            }
            final data = snap.data ?? {};
            final sections = AppConstants.categories
                .where((c) => (data[c] ?? []).isNotEmpty)
                .toList();
            if (sections.isEmpty) {
              return const StatusView(message: '暂无内容');
            }
            return ListView.builder(
              padding:
                  EdgeInsets.symmetric(horizontal: pad, vertical: 16),
              itemCount: sections.length,
              itemBuilder: (_, i) {
                final cat = sections[i];
                final items = data[cat]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go(
                                '/category?type=${Uri.encodeComponent(cat)}'),
                            child: const Text('更多 ›',
                                style:
                                    TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      VideoGrid(
                        items: items,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
