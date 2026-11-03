/// Persistence. The whole app state is one small JSON document saved on the
/// device. Swap [FileStorage] for a database later without touching the UI.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';
import 'seed.dart' show cardioPresets;

/// v2 renamed "rota" to "rotation"; v3 added splits; v4 added cardio. Older
/// files still load (the store migrates them on open).
const schemaVersion = 4;

/// Everything the app stores.
class AppData {
  List<Split> splits;
  String? activeSplitId;
  List<Day> days;
  List<Rotation> rotations;
  List<Session> sessions;
  List<String> library;

  /// Names logged as time (cardio) rather than weight.
  List<String> cardio;

  AppData({
    List<Split>? splits,
    this.activeSplitId,
    required this.days,
    required this.rotations,
    required this.sessions,
    required this.library,
    List<String>? cardio,
  })  : splits = splits ?? [],
        cardio = cardio ?? [...cardioPresets];

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'splits': splits.map((x) => x.toJson()).toList(),
        'activeSplitId': activeSplitId,
        'days': days.map((d) => d.toJson()).toList(),
        'rotations': rotations.map((r) => r.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'library': library,
        'cardio': cardio,
      };

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        splits: ((j['splits'] as List?) ?? const []).map((e) => Split.fromJson(e as Map<String, dynamic>)).toList(),
        activeSplitId: j['activeSplitId'] as String?,
        days: (j['days'] as List).map((e) => Day.fromJson(e as Map<String, dynamic>)).toList(),
        rotations: ((j['rotations'] ?? j['rotas']) as List) // 'rotas' = schema v1
            .map((e) => Rotation.fromJson(e as Map<String, dynamic>))
            .toList(),
        sessions: (j['sessions'] as List).map((e) => Session.fromJson(e as Map<String, dynamic>)).toList(),
        library: (j['library'] as List).cast<String>().toList(),
        cardio: (j['cardio'] as List?)?.cast<String>().toList(), // null before v4 → presets
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
