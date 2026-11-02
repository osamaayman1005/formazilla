/// Persistence. The whole app state is one small JSON document saved on the
/// device. Swap [FileStorage] for a database later without touching the UI.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

const schemaVersion = 1;

/// Everything the app stores.
class AppData {
  List<Day> days;
  List<Rota> rotas;
  List<Session> sessions;
  List<String> library;

  AppData({required this.days, required this.rotas, required this.sessions, required this.library});

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'days': days.map((d) => d.toJson()).toList(),
        'rotas': rotas.map((r) => r.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'library': library,
      };

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        days: (j['days'] as List).map((e) => Day.fromJson(e as Map<String, dynamic>)).toList(),
        rotas: (j['rotas'] as List).map((e) => Rota.fromJson(e as Map<String, dynamic>)).toList(),
        sessions: (j['sessions'] as List).map((e) => Session.fromJson(e as Map<String, dynamic>)).toList(),
        library: (j['library'] as List).cast<String>().toList(),
      );

  String encode() => jsonEncode(toJson());

  static AppData decode(String text) => AppData.fromJson(jsonDecode(text) as Map<String, dynamic>);
}

abstract class Storage {
  /// Returns null when nothing has been saved yet.
  Future<AppData?> load();
  Future<void> save(AppData data);
}

/// Saves to `formazilla.json` in the app documents folder.
/// Writes go to a temp file first, then rename, so a crash never corrupts data.
class FileStorage implements Storage {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/formazilla.json');
  }

  @override
  Future<AppData?> load() async {
    final f = await _file();
    if (!await f.exists()) return null;
    return AppData.decode(await f.readAsString());
  }

  Future<void> _pending = Future.value();

  @override
  Future<void> save(AppData data) {
    final text = data.encode();
    // Chain writes so they never overlap.
    _pending = _pending.then((_) async {
      final f = await _file();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(text, flush: true);
      await tmp.rename(f.path);
    });
    return _pending;
  }
}

/// In-memory storage for tests.
class MemoryStorage implements Storage {
  String? saved;

  @override
  Future<AppData?> load() async => saved == null ? null : AppData.decode(saved!);

  @override
  Future<void> save(AppData data) async => saved = data.encode();
}
