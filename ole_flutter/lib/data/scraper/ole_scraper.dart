import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../core/constants.dart';
import '../models/episode.dart';
import '../models/paged_result.dart';
import '../models/video_detail.dart';
import '../models/video_item.dart';
import 'ad_filter.dart';
import 'http_client.dart';

class OleScraper {
  static final OleScraper instance = OleScraper._();
  OleScraper._();

  final _http = HttpClient.instance;

  // ───────── 工具 ─────────

  List<VideoItem> _dedup(List<VideoItem> items) {
    final seen = <String>{};
    final out = <VideoItem>[];
    for (final it in items) {
      if (seen.contains(it.url)) continue;
      seen.add(it.url);
      out.add(it);
    }
    return out;
  }

  VideoItem? _parseVodlistItem(Element li) {
    // a.vodlist_thumb 是封面链接，承载大部分元数据
    final a = li.querySelector('a.vodlist_thumb');
    if (a == null) return null;

    final href = a.attributes['href'] ?? '';
    final title = a.attributes['title'] ?? '';
    final img =
        a.attributes['data-original'] ?? a.attributes['data-src'] ?? '';

    if (!href.contains('/vod/detail/') || isAd(href) || title.isEmpty) {
      return null;
    }

    // span.text_right: 评分 + 状态混在一起，用正则拆开
    final rawScore =
        a.querySelector('span.text_right')?.text.trim() ?? '';
    final scoreMatch = RegExp(r'^[\d.]+').firstMatch(rawScore);
    final score = scoreMatch?.group(0) ?? '';
    final status =
        rawScore.replaceFirst(RegExp(r'^[\d.]+'), '').trim();

    // span:last-child 拿热度（数字）
    String hot = '';
    final spans = a.querySelectorAll('span');
    if (spans.isNotEmpty) {
      final raw = spans.last.text;
      hot = raw.replaceAll(RegExp(r'\s'), '').replaceAll(RegExp(r'[^\d]'), '');
    }

    // em.voddate_year 最后一个是清晰度
    final qualities = a.querySelectorAll('em.voddate_year');
    final quality = qualities.isNotEmpty ? qualities.last.text.trim() : '';

    final actors = li
            .querySelector('.vodlist_sub')
            ?.text
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ') ??
        '';

    return VideoItem(
      title: title,
      url: href,
      img: img,
      score: score,
      status: status,
      hot: hot,
      quality: quality,
      actors: actors,
    );
  }

  // ───────── 首页 ─────────

  Future<Map<String, List<VideoItem>>> fetchHome() async {
    final html = await _http.getHtml(AppConstants.baseUrl);
    final doc = html_parser.parse(html);

    final sections = <String, List<VideoItem>>{};
    const allowed = AppConstants.categories;

    for (final h2 in doc.querySelectorAll('h2')) {
      final rawTitle = h2.text.trim();
      String? title;
      for (final t in allowed) {
        if (rawTitle.contains(t)) {
          title = t;
          break;
        }
      }
      if (title == null) continue;

      // 找 h2 最近的 .pannel 祖先
      Element? pannel = h2;
      while (pannel != null && !pannel.classes.contains('pannel')) {
        pannel = pannel.parent;
      }
      if (pannel == null) continue;

      final items = <VideoItem>[];
      for (final li in pannel.querySelectorAll('li.vodlist_item')) {
        final item = _parseVodlistItem(li);
        if (item != null) items.add(item);
      }
      sections[title] = _dedup(items).take(12).toList();
    }
    return sections;
  }

  // ───────── 分类 ─────────

  Future<PagedResult> fetchCategory(String type, {int page = 1}) async {
    final id = AppConstants.categoryIds[type];
    if (id == null) {
      throw Exception('unknown type: $type');
    }
    final url =
        '${AppConstants.baseUrl}/index.php/vod/type/id/$id/page/$page.html';
    final html = await _http.getHtml(url);
    final doc = html_parser.parse(html);

    final items = <VideoItem>[];
    for (final li in doc.querySelectorAll('li.vodlist_item')) {
      final it = _parseVodlistItem(li);
      if (it != null) items.add(it);
    }

    int? total;
    final body = doc.body?.text ?? '';
    final m = RegExp(r'共(\d+)条').firstMatch(body);
    if (m != null) total = int.tryParse(m.group(1)!);

    return PagedResult(items: _dedup(items), page: page, total: total);
  }

  // ───────── 详情 ─────────

  Future<VideoDetail> fetchDetail(String id) async {
    final url = '${AppConstants.baseUrl}/index.php/vod/detail/id/$id.html';
    final html = await _http.getHtml(url);
    final doc = html_parser.parse(html);

    final rawTitle = doc.querySelector('title')?.text ?? '';
    final title = rawTitle.split('_').first.trim();

    final coverA = doc.querySelector('a.vodlist_thumb');
    final cover = coverA?.attributes['data-original'] ??
        coverA?.querySelector('img')?.attributes['src'] ??
        '';

    final desc =
        doc.querySelector('.content_desc span')?.text.trim() ?? '';
    final score = doc.querySelector('.star_tips')?.text.trim() ?? '';

    final episodes = <Episode>[];
    final seen = <String>{};
    for (final a in doc.querySelectorAll('a')) {
      final href = a.attributes['href'] ?? '';
      if (!href.contains('/vod/play/id/')) continue;
      if (href.contains('play_vip') || href.contains('javascript')) continue;
      final epTitleRaw = a.text.trim().replaceAll(RegExp(r'\s+'), '');
      if (epTitleRaw.isEmpty) continue;
      final displayTitle = (epTitleRaw.contains('立即播放') ||
              epTitleRaw.contains('播放'))
          ? '播放'
          : epTitleRaw;
      if (seen.contains(href)) continue;
      seen.add(href);
      episodes.add(Episode(title: displayTitle, url: href));
    }

    return VideoDetail(
      title: title,
      cover: cover,
      desc: desc,
      score: score,
      episodes: episodes,
    );
  }

  // ───────── 视频源 ─────────

  Future<String> fetchVideoSrc(String playPath) async {
    final url = AppConstants.baseUrl + playPath;
    final html = await _http.getHtml(url);
    final m = RegExp(r'player_aaaa=(\{[^<]+\})').firstMatch(html);
    if (m == null) throw Exception('no player data found');
    final json = jsonDecode(m.group(1)!) as Map<String, dynamic>;
    final rawUrl = json['url'] as String?;
    if (rawUrl == null || rawUrl.isEmpty) {
      throw Exception('no url in player data');
    }
    return rawUrl.replaceAll(r'\/', '/');
  }

  // ───────── 搜索 ─────────

  Future<PagedResult> search(String q, {int page = 1}) async {
    final url =
        '${AppConstants.baseUrl}/index.php/vod/search/page/$page/wd/${Uri.encodeComponent(q)}.html';
    final html = await _http.getHtml(url);
    final doc = html_parser.parse(html);

    final items = <VideoItem>[];

    for (final li in doc.querySelectorAll('li.searchlist_item')) {
      final a = li.querySelector('a.vodlist_thumb');
      if (a == null) continue;
      final href = a.attributes['href'] ?? '';
      final title = a.attributes['title'] ?? '';
      final img =
          a.attributes['data-original'] ?? a.attributes['data-src'] ?? '';
      if (!href.contains('/vod/detail/') || isAd(href) || title.isEmpty) {
        continue;
      }
      final rawScore =
          a.querySelector('span.text_right')?.text.trim() ?? '';
      final scoreMatch = RegExp(r'^[\d.]+').firstMatch(rawScore);
      final score = scoreMatch?.group(0) ?? '';
      String status =
          rawScore.replaceFirst(RegExp(r'^[\d.]+'), '').trim();
      if (status.isEmpty) {
        status = a.querySelector('.pic_text')?.text.trim() ?? '';
      }
      final actors = li
              .querySelectorAll('.vodlist_sub')
              .firstOrNull
              ?.text
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ') ??
          '';

      items.add(VideoItem(
        title: title,
        url: href,
        img: img,
        score: score,
        status: status,
        actors: actors,
      ));
    }

    // fallback
    if (items.isEmpty) {
      for (final a
          in doc.querySelectorAll('a.vodlist_thumb[href*="/vod/detail/"]')) {
        final href = a.attributes['href'] ?? '';
        final title = a.attributes['title'] ?? '';
        final img = a.attributes['data-original'] ?? '';
        if (isAd(href) || title.isEmpty) continue;
        items.add(VideoItem(title: title, url: href, img: img));
      }
    }

    return PagedResult(items: _dedup(items), page: page);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
