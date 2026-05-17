import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/responsive.dart';
import '../core/theme.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? activeCategory;
  final String? initialQuery;

  const AppHeader({super.key, this.activeCategory, this.initialQuery});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  late final TextEditingController _searchCtrl =
      TextEditingController(text: widget.initialQuery ?? '');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _doSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    context.go('/search?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final phone = Responsive.typeOf(context) == DeviceType.phone;
    final loc = GoRouterState.of(context).matchedLocation;
    final showBack = loc != '/';

    return AppBar(
      titleSpacing: 12,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              tooltip: '返回首页',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/'),
            )
          : null,
      title: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: const Text(
              '🎬 影视',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
          ),
          if (!phone) const SizedBox(width: 24),
          if (!phone)
            Expanded(
              child: Wrap(
                spacing: 4,
                children: [
                  for (final c in AppConstants.categories)
                    _NavChip(
                      label: c,
                      active: widget.activeCategory == c,
                      onTap: () => context.go(
                          '/category?type=${Uri.encodeComponent(c)}'),
                    ),
                ],
              ),
            )
          else
            const Spacer(),
          SizedBox(
            width: phone ? 160 : 240,
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _doSearch(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索...',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.send, size: 16),
                  onPressed: _doSearch,
                ),
              ),
            ),
          ),
        ],
      ),
      bottom: phone
          ? PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    for (final c in AppConstants.categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _NavChip(
                          label: c,
                          active: widget.activeCategory == c,
                          onTap: () => context.go(
                              '/category?type=${Uri.encodeComponent(c)}'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: active ? AppTheme.accent : AppTheme.textPrimary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
