import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'storage.dart';

Storage defaultStorage() => WebStorage();

/// Saves the same JSON document in the browser's localStorage. The previous
/// copy is kept too, so a damaged save can fall back one step.
/// Safari is asked to keep the data ("persist") on the first save.
class WebStorage implements Storage {
  static const _key = 'formazilla.json';
  static const _previousKey = 'formazilla.previous.json';
  bool _askedToPersist = false;

  web.Storage get _ls => web.window.localStorage;

  @override
  Future<AppData?> load() async {
    final text = _ls.getItem(_key);
    if (text == null || text.isEmpty) {
      final previous = _ls.getItem(_previousKey);
      return previous == null || previous.isEmpty ? null : AppData.decode(previous);
    }
    try {
      return AppData.decode(text);
    } catch (_) {
      final previous = _ls.getItem(_previousKey);
      if (previous == null || previous.isEmpty) rethrow;
      return AppData.decode(previous);
    }
  }

  @override
  Future<void> save(AppData data) async {
    final current = _ls.getItem(_key);
    if (current != null && current.isNotEmpty) _ls.setItem(_previousKey, current);
    _ls.setItem(_key, data.encode());
    if (!_askedToPersist) {
      _askedToPersist = true;
      try {
        await web.window.navigator.storage.persist().toDart;
      } catch (_) {
        // Older browsers: nothing to do.
      }
    }
  }
}
