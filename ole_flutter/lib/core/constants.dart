class AppConstants {
  static const String baseUrl = 'https://www.olehdtv.com';

  static const String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';

  static const List<String> adDomains = [
    '202807.net',
    'u68web7.ca',
    'cc88.win',
    'rbvisb.com',
    'dx55.com',
    'mk730.com',
    '0597b5.com',
    'blm8.app',
    '225.52.94',
  ];

  // 与 web 版相同：动漫第一，然后电影/连续剧/综艺
  static const List<String> categories = ['动漫', '电影', '连续剧', '综艺'];

  static const Map<String, int> categoryIds = {
    '电影': 1,
    '连续剧': 2,
    '综艺': 3,
    '动漫': 4,
  };

  static const int pageSize = 24;
  static const Duration httpTimeout = Duration(seconds: 12);
}
