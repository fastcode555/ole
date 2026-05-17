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

class CategoryPage extends StatefulWidget {
  final String type;
  final int page;
  const CategoryPage({super.key, required this.type, this.page = 1});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<PagedResult> _future;

  @override
  void initState() {
    super.initState();
    _future =
        OleScraper.instance.fetchCategory(widget.type, page: widget.page);
  }

  @override
  void didUpdateWidget(covariant CategoryPage old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type || old.page != widget.page) {
      _future = OleScraper.instance
          .fetchCategory(widget.type, page: widget.page);
    }
  }

  void _gotoPage(int p) {
    context.go(
        '/category?type=${Uri.encodeComponent(widget.type)}&page=$p');
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppHeader(activeCategory: widget.type),
      body: FutureBuilder<PagedResult>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const StatusView(message: '加载中...', loading: true);
          }
          if (snap.hasError) {
            return StatusView(message: '加载失败：${snap.error}');
          }
          final data = snap.data!;
          if (data.items.isEmpty) {
            return const StatusView(message: '暂无内容');
          }
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.type,
                  style: const TextStyle(
                    fontSize: 22,
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
                totalPages: data.totalPages,
                onChange: _gotoPage,
              ),
            ],
          );
        },
      ),
    );
  }
}
