import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../data/models/episode.dart';
import '../../data/models/video_detail.dart';
import '../../data/scraper/ole_scraper.dart';
import '../../data/storage/favorites_store.dart';
import '../../data/storage/progress_store.dart';
import '../../data/storage/skip_store.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_view.dart';
import 'widgets/episode_list.dart';
import 'widgets/player_view.dart';
import 'widgets/skip_settings_panel.dart';

class DetailPage extends StatefulWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late final Player _player;
  late final VideoController _controller;
  final FocusNode _focusNode = FocusNode();

  Future<VideoDetail>? _detailFuture;

  /// 倒序后的集数列表（与 web 版 detail.html 行为一致）
  List<_EpisodeView> _episodes = [];
  int _currentEpIdx = -1;
  int _lastWatchedIdx = -1;

  SkipSettings _skip = const SkipSettings();
  String _playerMsg = '';
  bool _isFloating = false;
  Offset _floatOffset = const Offset(20, 80);

  StreamSubscription? _positionSub;
  StreamSubscription? _completedSub;
  Timer? _saveTimer;
  bool _outroTriggered = false;
  bool _resumeApplied = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _skip = SkipStore.load(widget.id);
    _detailFuture = _load();
    _attachListeners();
  }

  Future<VideoDetail> _load() async {
    final d = await OleScraper.instance.fetchDetail(widget.id);
    // 与 web 版相同：把集数倒过来（最新在前）
    _episodes = d.episodes
        .map((e) => _EpisodeView(title: e.title, url: e.url))
        .toList()
        .reversed
        .toList();

    final progress = ProgressStore.loadProgress(widget.id);
    int startIdx;
    if (progress != null && progress.epIdx >= 0) {
      startIdx = progress.epIdx;
    } else {
      startIdx = ProgressStore.getLastEp(widget.id);
    }
    if (startIdx < 0 || startIdx >= _episodes.length) {
      startIdx = _episodes.isEmpty ? -1 : _episodes.length - 1;
    }
    _lastWatchedIdx = startIdx;
    if (startIdx >= 0) {
      // 不立即播放（pauseAfterLoad: true）
      // ignore: discarded_futures
      _playEp(startIdx, pauseAfterLoad: true);
    }
    return d;
  }

  void _attachListeners() {
    _positionSub = _player.stream.position.listen(_onPosition);
    _completedSub = _player.stream.completed.listen((c) {
      if (!c) return;
      _onEnded();
    });
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final pos = _player.state.position.inMilliseconds / 1000.0;
      if (_player.state.playing && pos > 5) {
        _persistProgress(pos);
      }
    });
  }

  void _onPosition(Duration p) {
    if (!_resumeApplied) return;
    if (_outroTriggered) return;
    if (_skip.outro <= 0) return;
    final dur = _player.state.duration;
    if (dur.inMilliseconds == 0) return;
    final remainingSec =
        (dur.inMilliseconds - p.inMilliseconds) / 1000.0;
    if (remainingSec <= _skip.outro && remainingSec > 0) {
      _outroTriggered = true;
      if (_currentEpIdx > 0) {
        setState(() => _playerMsg = '片尾跳过，即将播放下一集...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _playEp(_currentEpIdx - 1);
        });
      }
    }
  }

  void _onEnded() {
    if (_currentEpIdx > 0) {
      setState(() => _playerMsg = '即将播放下一集...');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _playEp(_currentEpIdx - 1);
      });
    }
  }

  void _persistProgress(double posSec) {
    ProgressStore.saveProgress(widget.id, _currentEpIdx, posSec);
    // 电影类（单集"播放"）保存为 __time__<sec>，与 web 版一致
    if (_episodes.length == 1 &&
        _currentEpIdx == 0 &&
        _episodes[0].title == '播放') {
      ProgressStore.setLastEpTitle(widget.id, '__time__${posSec.floor()}');
    }
  }

  Future<void> _playEp(int idx, {bool pauseAfterLoad = false}) async {
    if (idx < 0 || idx >= _episodes.length) return;
    setState(() {
      _currentEpIdx = idx;
      _playerMsg = '加载视频源...';
      _outroTriggered = false;
      _resumeApplied = false;
    });

    await ProgressStore.setLastEp(widget.id, idx);
    final ep = _episodes[idx];
    if (!(_episodes.length == 1 && ep.title == '播放')) {
      await ProgressStore.setLastEpTitle(widget.id, ep.title);
    }

    String src;
    try {
      final playPath =
          ep.url.replaceFirst(AppConstants.baseUrl, '');
      src = await OleScraper.instance.fetchVideoSrc(playPath);
    } catch (e) {
      if (!mounted) return;
      setState(() => _playerMsg = '加载失败：$e');
      return;
    }

    if (!mounted) return;
    setState(() => _playerMsg = '');

    final progress = ProgressStore.loadProgress(widget.id);
    final resumeSec = (progress != null &&
            progress.epIdx == idx &&
            progress.time > 5)
        ? progress.time
        : 0.0;

    await _player.open(Media(src), play: false);

    Duration? startAt;
    if (resumeSec > 0) {
      startAt = Duration(milliseconds: (resumeSec * 1000).toInt());
    } else if (_skip.intro > 0) {
      startAt = Duration(seconds: _skip.intro);
    }

    if (startAt != null) {
      // 对 HLS/m3u8，open() 完成时 duration 通常还是 0；此时 seek 会被
      // 静默丢掉，导致续播失效。等 duration 流首个非零值再 seek。
      try {
        await _player.stream.duration
            .firstWhere((d) => d > Duration.zero)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // 元数据迟迟不来就放弃 seek，让用户从头看
        startAt = null;
      }
    }

    if (startAt != null && mounted) {
      await _player.seek(startAt);
      if (resumeSec > 0) {
        setState(() => _playerMsg =
            '上次看到 ${_formatSec(resumeSec)}，已自动续播');
      }
    }

    if (!pauseAfterLoad) {
      await _player.play();
    }
    _resumeApplied = true;
  }

  String _formatSec(double s) {
    final i = s.floor();
    final h = i ~/ 3600;
    final m = (i % 3600) ~/ 60;
    final sec = i % 60;
    String pad(int n) => n < 10 ? '0$n' : '$n';
    if (h > 0) return '$h:${pad(m)}:${pad(sec)}';
    return '${pad(m)}:${pad(sec)}';
  }

  void _playNext() {
    if (_currentEpIdx > 0) _playEp(_currentEpIdx - 1);
  }

  void _playPrev() {
    if (_currentEpIdx < _episodes.length - 1) {
      _playEp(_currentEpIdx + 1);
    }
  }

  void _markIntro() {
    final pos = _player.state.position.inSeconds;
    if (pos <= 0) {
      _showSkipMsg('请先拖动到片头结束位置');
      return;
    }
    _updateSkip(_skip.copyWith(intro: pos));
    _showSkipMsg('片头设为 ${_formatSec(pos.toDouble())}');
  }

  void _markOutro() {
    final dur = _player.state.duration;
    final pos = _player.state.position;
    if (dur.inSeconds == 0) {
      _showSkipMsg('视频时长未知，请稍候');
      return;
    }
    final remaining = dur.inSeconds - pos.inSeconds;
    if (remaining <= 0) {
      _showSkipMsg('请先拖动到片尾开始位置');
      return;
    }
    _updateSkip(_skip.copyWith(outro: remaining));
    _showSkipMsg('片尾设为最后 ${_formatSec(remaining.toDouble())}');
  }

  void _updateSkip(SkipSettings s) {
    setState(() => _skip = s);
    SkipStore.save(widget.id, s);
    _outroTriggered = false;
  }

  void _showSkipMsg(String text) {
    setState(() => _playerMsg = text);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _playerMsg == text) {
        setState(() => _playerMsg = '');
      }
    });
  }

  // 键盘控制
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final pos = _player.state.position;
    final dur = _player.state.duration;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _player.state.playing ? _player.pause() : _player.play();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final target = pos + const Duration(seconds: 10);
      _player.seek(target > dur ? dur : target);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final target = pos - const Duration(seconds: 10);
      _player.seek(target.isNegative ? Duration.zero : target);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positionSub?.cancel();
    _completedSub?.cancel();
    // 退出前再保存一次进度
    final pos = _player.state.position.inMilliseconds / 1000.0;
    if (_currentEpIdx >= 0 && pos > 5) {
      _persistProgress(pos);
    }
    _player.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            FutureBuilder<VideoDetail>(
              future: _detailFuture,
              builder: (_, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const StatusView(message: '加载中...', loading: true);
                }
                if (snap.hasError) {
                  return StatusView(message: '加载失败：${snap.error}');
                }
                return Responsive.isWide(context)
                    ? _buildWide(snap.data!)
                    : _buildNarrow(snap.data!);
              },
            ),
            if (_isFloating) _buildFloatingPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _isFloating
            ? Container(
                color: Colors.black,
                height: 220,
                alignment: Alignment.center,
                child: const Text(
                  '播放器已固定在悬浮窗',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            : PlayerView(controller: _controller),
        Container(
          padding: const EdgeInsets.all(8),
          color: AppTheme.surface,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _currentEpIdx >= 0 && _currentEpIdx < _episodes.length
                    ? _episodes[_currentEpIdx].title
                    : '—',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_playerMsg.isNotEmpty)
                Text(
                  _playerMsg,
                  style: const TextStyle(
                      color: AppTheme.accentSoft, fontSize: 12),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(() => _isFloating = !_isFloating),
                child: Text(_isFloating ? '⊠ 取消固定' : '⊡ 固定'),
              ),
              OutlinedButton(
                onPressed: _currentEpIdx >= _episodes.length - 1
                    ? null
                    : _playPrev,
                child: const Text('⏮ 上一集'),
              ),
              OutlinedButton(
                onPressed: _currentEpIdx <= 0 ? null : _playNext,
                child: const Text('下一集 ⏭'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SkipSettingsPanel(
          skip: _skip,
          onChange: _updateSkip,
          onMarkIntro: _markIntro,
          onMarkOutro: _markOutro,
        ),
      ],
    );
  }

  Widget _buildInfoArea(VideoDetail d) {
    final favs = context.watch<FavoritesStore>();
    final faved = favs.isFav(widget.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.cover.isNotEmpty)
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: d.cover,
                fit: BoxFit.cover,
                httpHeaders: const {
                  'Referer': 'https://www.olehdtv.com'
                },
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceAlt,
                  alignment: Alignment.center,
                  child: const Text('🎬',
                      style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
          )
        else
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('🎬', style: TextStyle(fontSize: 48)),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          d.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (d.score.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.score,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  d.score,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton(
              onPressed: () => favs.toggle(widget.id),
              child: Text(faved ? '❤️ 已喜欢' : '🤍 喜欢'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          d.desc.isNotEmpty ? d.desc : '暂无简介',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildEpisodes(VideoDetail d) {
    final eps = _episodes.map((e) => e.toEpisode()).toList();
    return EpisodeList(
      episodes: eps,
      currentIdx: _currentEpIdx,
      lastWatchedIdx: _lastWatchedIdx,
      onTap: _playEp,
    );
  }

  Widget _buildWide(VideoDetail d) {
    final pad = Responsive.horizontalPadding(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPlayerArea(),
                const SizedBox(height: 20),
                _buildEpisodes(d),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 280,
            child: _buildInfoArea(d),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrow(VideoDetail d) {
    final pad = Responsive.horizontalPadding(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlayerArea(),
          const SizedBox(height: 16),
          _buildEpisodes(d),
          const SizedBox(height: 20),
          _buildInfoArea(d),
        ],
      ),
    );
  }

  Widget _buildFloatingPlayer() {
    return Positioned(
      left: _floatOffset.dx,
      top: _floatOffset.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _floatOffset += d.delta;
          });
        },
        child: Material(
          color: Colors.black,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 28,
                    color: AppTheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '悬浮窗（可拖动）',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _isFloating = false),
                          child: const Icon(Icons.close,
                              size: 16, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  PlayerView(controller: _controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeView {
  final String title;
  final String url;
  _EpisodeView({required this.title, required this.url});

  Episode toEpisode() => Episode(title: title, url: url);
}
