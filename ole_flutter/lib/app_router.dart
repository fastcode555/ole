import 'package:go_router/go_router.dart';

import 'features/category/category_page.dart';
import 'features/detail/detail_page.dart';
import 'features/home/home_page.dart';
import 'features/search/search_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: '/category',
      builder: (_, state) {
        final type = state.uri.queryParameters['type'] ?? '电影';
        final page = int.tryParse(
                state.uri.queryParameters['page'] ?? '1') ??
            1;
        return CategoryPage(type: type, page: page);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (_, state) {
        final q = state.uri.queryParameters['q'] ?? '';
        final page = int.tryParse(
                state.uri.queryParameters['page'] ?? '1') ??
            1;
        return SearchPage(q: q, page: page);
      },
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        return DetailPage(id: id);
      },
    ),
  ],
);
