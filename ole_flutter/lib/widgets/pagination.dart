import 'package:flutter/material.dart';

import '../core/theme.dart';

class Pagination extends StatelessWidget {
  final int current;
  final int? totalPages;
  final ValueChanged<int> onChange;

  const Pagination({
    super.key,
    required this.current,
    required this.onChange,
    this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final hasNext = totalPages == null || current < totalPages!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (current > 1)
            _btn('上一页', onTap: () => onChange(current - 1)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$current',
                style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          if (hasNext) _btn('下一页', onTap: () => onChange(current + 1)),
        ],
      ),
    );
  }

  Widget _btn(String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: const TextStyle(color: AppTheme.textPrimary)),
      ),
    );
  }
}
