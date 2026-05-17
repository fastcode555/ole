import 'package:flutter/material.dart';

import '../core/theme.dart';

class StatusView extends StatelessWidget {
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  const StatusView({
    super.key,
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            if (loading) const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ],
        ),
      ),
    );
  }
}
