import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models/paged_result.dart';
import '../../data/scraper/ole_scraper.dart';
import '../../widgets/app_header.dart';
import '../../widgets/pagination.dart';
import '../../widgets/status_view.dart';
import '../../widgets/video_grid.dart';

class SearchPage extends StatefulWidget {
  final String q;
  final int page;
  const SearchPage({super.key, required this.q, this.page = 1});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Future<PagedResult>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.q.isNotEmpty) {
      _future = OleScraper.instance.search(widget.q, page: widget.page);
    }
  }

  @override
  void didUpdateWidget(covariant SearchPage old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q || old.page != widget.page) {
      _future = widget.q.isEmpty
          ? null
          : OleScraper.instance.search(widget.q, page: widget.page);
    }
  }

  void _gotoPage(int p) {
    context.go('/search?q=${Uri.encodeComponent(widget.q)}&page=$p');
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppHeader(initialQuery: widget.q),
      body: widget.q.isEmpty
          ? const StatusView(message: '请输入搜索词')
          : FutureBuilder<PagedResult>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const StatusView(message: '搜索中...', loading: true);
                }
                if (snap.hasError) {
                  return StatusView(message: '搜索失败：${snap.error}');
                }
                final data = snap.data!;
                if (data.items.isEmpty) {
                  return const StatusView(message: '没有找到相关内容');
                }
                return ListView(
                  padding:
                      EdgeInsets.symmetric(horizontal: pad, vertical: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '搜索：${widget.q}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    VideoGrid(
                      items: data.items,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                    Pagination(
                      current: widget.page,
                      onChange: _gotoPage,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
