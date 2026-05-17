import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../data/storage/skip_store.dart';

class SkipSettingsPanel extends StatefulWidget {
  final SkipSettings skip;
  final ValueChanged<SkipSettings> onChange;
  final VoidCallback onMarkIntro;
  final VoidCallback onMarkOutro;

  const SkipSettingsPanel({
    super.key,
    required this.skip,
    required this.onChange,
    required this.onMarkIntro,
    required this.onMarkOutro,
  });

  @override
  State<SkipSettingsPanel> createState() => _SkipSettingsPanelState();
}

class _SkipSettingsPanelState extends State<SkipSettingsPanel> {
  late final TextEditingController _introCtrl;
  late final TextEditingController _outroCtrl;

  @override
  void initState() {
    super.initState();
    _introCtrl = TextEditingController(text: widget.skip.intro.toString());
    _outroCtrl = TextEditingController(text: widget.skip.outro.toString());
  }

  @override
  void didUpdateWidget(covariant SkipSettingsPanel old) {
    super.didUpdateWidget(old);
    if (old.skip.intro != widget.skip.intro) {
      _introCtrl.text = widget.skip.intro.toString();
    }
    if (old.skip.outro != widget.skip.outro) {
      _outroCtrl.text = widget.skip.outro.toString();
    }
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _outroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.skip;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('片头跳过',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              _ValuePill(
                  text: s.intro > 0 ? formatTime(s.intro) : '未设置'),
              OutlinedButton(
                onPressed: widget.onMarkIntro,
                child: const Text('▶ 标记片头结束'),
              ),
              const SizedBox(width: 8),
              const Text('片尾跳过',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              _ValuePill(
                  text: s.outro > 0 ? '${formatTime(s.outro)} 前' : '未设置'),
              OutlinedButton(
                onPressed: widget.onMarkOutro,
                child: const Text('⏹ 标记片尾开始'),
              ),
              TextButton(
                onPressed: () =>
                    widget.onChange(const SkipSettings(intro: 0, outro: 0)),
                child: const Text('清除'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('片头',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _introCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: 6),
              const Text('秒',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 16),
              const Text('片尾',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _outroCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: 6),
              const Text('秒',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final i = int.tryParse(_introCtrl.text) ?? 0;
                  final o = int.tryParse(_outroCtrl.text) ?? 0;
                  widget.onChange(SkipSettings(intro: i, outro: o));
                },
                child: const Text('应用'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  final String text;
  const _ValuePill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textPrimary)),
    );
  }
}
