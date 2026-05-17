import '../../core/constants.dart';

bool isAd(String? url) {
  if (url == null || url.isEmpty) return true;
  for (final d in AppConstants.adDomains) {
    if (url.contains(d)) return true;
  }
  return false;
}
