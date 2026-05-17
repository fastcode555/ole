import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerView extends StatefulWidget {
  final VideoController controller;
  const PlayerView({super.key, required this.controller});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  /// 与 media_kit 的 AdaptiveVideoControls 默认空闲时长一致，
  /// 这样鼠标和底部控制条会同时隐藏/出现。
  static const _idleDelay = Duration(seconds: 3);

  Timer? _hideTimer;
  bool _hidden = false;
  bool _pointerInside = false;

  void _resetHide() {
    _pointerInside = true;
    if (_hidden) setState(() => _hidden = false);
    _hideTimer?.cancel();
    _hideTimer = Timer(_idleDelay, () {
      if (mounted && _pointerInside) setState(() => _hidden = true);
    });
  }

  void _cancelHide() {
    _pointerInside = false;
    _hideTimer?.cancel();
    if (_hidden) setState(() => _hidden = false);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 外层 MouseRegion 检测移动；内部 Stack 顶层在隐藏时放一个 opaque
    // MouseRegion 覆盖整个播放区，强行把光标设为 none——这能压住
    // media_kit 内部按钮自带的 click/text 光标决策。
    return MouseRegion(
      onEnter: (_) => _resetHide(),
      onHover: (_) => _resetHide(),
      onExit: (_) => _cancelHide(),
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: Video(
                  controller: widget.controller,
                  controls: AdaptiveVideoControls,
                ),
              ),
              if (_hidden)
                Positioned.fill(
                  child: MouseRegion(
                    opaque: true,
                    cursor: SystemMouseCursors.none,
                    onHover: (_) => _resetHide(),
                    onExit: (_) => _cancelHide(),
                    // 空 SizedBox 不拦截 click，只接管 cursor 与 hover。
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
