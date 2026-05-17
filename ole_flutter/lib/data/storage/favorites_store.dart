import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'prefs.dart';

class FavoritesStore extends ChangeNotifier {
  static const _key = 'favorites';

  Set<String> _ids = {};

  FavoritesStore() {
    _load();
  }

  void _load() {
    final raw = Prefs.instance.getString(_key);
    if (raw == null || raw.isEmpty) {
      _ids = {};
      return;
    }
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      _ids = list.toSet();
    } catch (_) {
      _ids = {};
    }
  }

  Set<String> get all => Set.unmodifiable(_ids);
  bool isFav(String? id) => id != null && _ids.contains(id);

  Future<bool> toggle(String id) async {
    final nowFaved = !_ids.contains(id);
    if (nowFaved) {
      _ids.add(id);
    } else {
      _ids.remove(id);
    }
    await Prefs.instance.setString(_key, jsonEncode(_ids.toList()));
    notifyListeners();
    return nowFaved;
  }
}
