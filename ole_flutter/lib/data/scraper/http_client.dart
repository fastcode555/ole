import 'package:dio/dio.dart';

import '../../core/constants.dart';

class HttpClient {
  static final HttpClient instance = HttpClient._();

  late final Dio dio;

  HttpClient._() {
    dio = Dio(BaseOptions(
      connectTimeout: AppConstants.httpTimeout,
      receiveTimeout: AppConstants.httpTimeout,
      sendTimeout: AppConstants.httpTimeout,
      headers: {
        'User-Agent': AppConstants.userAgent,
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        'Referer': AppConstants.baseUrl,
      },
      responseType: ResponseType.plain,
      followRedirects: true,
    ));
  }

  Future<String> getHtml(String url) async {
    final res = await dio.get<String>(url);
    return res.data ?? '';
  }
}
