/// App state: owns the data, exposes read helpers, and is the only place that
/// changes data. Every change notifies listeners and saves.
library;

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../data/storage.dart';
import '../domain/workout_logic.dart' as logic;

class AppStore extends ChangeNotifier {
  AppStore._(this._storage, this._data);

  final Storage _storage;
  AppData _data;
  int _idCounter = 0;

  static Future<AppStore> open(Storage storage) async {
    var data = await storage.load();
    final store = AppStore._(storage, data ?? AppData(days: [], rotas: [], sessions: [], library: []));
    if (data == null) {
      final seed = buildSeed(store._newId);
      store._data = AppData(days: seed.days, rotas: seed.rotas, sessions: [], library: seed.library);
      await storage.save(store._data);
    }
    return store;
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  void _commit() {
    notifyListeners();
    _storage.save(_data);
  }

  // ---------- Reads ----------

  List<Day> get days => [..._data.days]..sort((a, b) => a.position.compareTo(b.position));
  List<Session> get sessions => _data.sessions;
  List<String> get library => _data.library;

  Day? dayById(String id) => _data.days.where((d) => d.id == id).firstOrNull;
  Rota? rotaById(String id) => _data.rotas.where((r) => r.id == id).firstOrNull;
  Session? sessionById(String id) => _data.sessions.where((s) => s.id == id).firstOrNull;

  List<Rota> rotasOf(String dayId) => logic.rotasForDay(dayId, _data.rotas);

  /// "Push A", or "Legs" for a single-rota day.
  String rotaLabel(String dayId, String rotaId) {
    final day = dayById(dayId)?.name ?? 'Workout';
    final rota = rotaById(rotaId);
    if (rota == null || rota.name.isEmpty) return day;
    return '$day ${rota.name}';
  }

  Session? get activeSession => _data.sessions.where((s) => !s.isFinished).firstOrNull;
  List<Session> get history => logic.finishedNewestFirst(_data.sessions);

  Day get suggestedDay => logic.suggestDay(days, _data.sessions);
  Rota? suggestedRota(String dayId) => logic.suggestRota(dayId, _data.rotas, _data.sessions);
  DateTime? lastDoneAt(String dayId) => logic.lastDoneAt(dayId, _data.sessions);

  double? recordBefore(String exercise, String sessionId) =>
      logic.personalRecord(exercise, _data.sessions, excludeSessionId: sessionId);
  double? record(String exercise) => logic.personalRecord(exercise, _data.sessions);
  List<double> lastTime(String exercise, String sessionId) =>
      logic.lastTimeWeights(exercise, _data.sessions, excludeSessionId: sessionId);

  List<logic.RecordEvent> recentRecords({int limit = 5}) => logic.recentRecords(_data.sessions, limit: limit);
  List<logic.TopSet> topSets(String exercise) => logic.topSetHistory(exercise, _data.sessions);
  List<logic.ExerciseSummary> exerciseSummaries() => logic.exerciseSummaries(_data.sessions);
  List<String> searchLibrary(String q) => logic.searchExercises(q, _data.library);
  logic.RecordCardData? recordCard(String exercise) => logic.recordCardData(exercise, _data.sessions);

  // ---------- Library ----------

  void _learn(String name) {
    final key = exerciseKey(name);
    if (!_data.library.any((n) => exerciseKey(n) == key)) _data.library.insert(0, name.trim());
  }

  // ---------- Sessions ----------

  Session startSession(Rota rota) {
    final existing = activeSession;
    if (existing != null) return existing;
    final s = Session(
      id: _newId(),
      dayId: rota.dayId,
      rotaId: rota.id,
      startedAt: DateTime.now(),
      exercises: rota.exercises.map((n) => SessionExercise(name: n)).toList(),
    );
    for (final pair in rota.supersets) {
      _applySuperset(s, pair);
    }
    _data.sessions.add(s);
    _commit();
    return s;
  }

  /// Swap the rota mid-session: keeps logged exercises, adds missing ones.
  void switchRota(Session s, Rota rota) {
    s.rotaId = rota.id;
    s.dayId = rota.dayId;
    s.exercises.removeWhere((e) => e.sets.isEmpty && !rota.exercises.any((n) => exerciseKey(n) == exerciseKey(e.name)));
    for (final n in rota.exercises) {
      if (!s.exercises.any((e) => exerciseKey(e.name) == exerciseKey(n))) {
        s.exercises.add(SessionExercise(name: n));
      }
    }
    _commit();
  }

  void addExercise(Session s, String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _learn(clean);
    s.exercises.add(SessionExercise(name: clean));
    _commit();
  }

  void removeExercise(Session s, int index) {
    final removed = s.exercises.removeAt(index);
    _dissolve(s, removed.supersetId);
    _commit();
  }

  void insertExercise(Session s, int index, SessionExercise e) {
    s.exercises.insert(index.clamp(0, s.exercises.length), e);
    _commit();
  }

  void moveExercise(Session s, int from, int to) {
    if (to < 0 || to >= s.exercises.length) return;
    // Moving breaks the pairing; unlink first so partners never end up apart.
    _dissolve(s, s.exercises[from].supersetId);
    _dissolve(s, s.exercises[to].supersetId);
    final e = s.exercises.removeAt(from);
    s.exercises.insert(to, e);
    _commit();
  }

  // ---------- Supersets ----------

  /// Links exercise [a] with [b]: [b] moves right after [a] and they alternate.
  /// [keepInTemplate] also saves the pair to the session's rota.
  void linkSuperset(Session s, int a, int b, {bool keepInTemplate = false}) {
    if (a == b) return;
    final first = s.exercises[a];
    final second = s.exercises[b];
    _dissolve(s, first.supersetId);
    _dissolve(s, second.supersetId);
    s.exercises.remove(second);
    s.exercises.insert(s.exercises.indexOf(first) + 1, second);
    final id = _newId();
    first.supersetId = id;
    second.supersetId = id;
    if (keepInTemplate) {
      final rota = rotaById(s.rotaId);
      if (rota != null) {
        _removeTemplatePairsWith(rota, first.name);
        _removeTemplatePairsWith(rota, second.name);
        rota.supersets.add([first.name, second.name]);
        _learn(first.name);
        _learn(second.name);
      }
    }
    _commit();
  }

  /// Unlinks a superset in this session, and from the rota if [fromTemplate].
  void unlinkSuperset(Session s, String supersetId, {bool fromTemplate = false}) {
    if (fromTemplate) {
      final rota = rotaById(s.rotaId);
      if (rota != null) {
        for (final e in s.exercises.where((e) => e.supersetId == supersetId)) {
          _removeTemplatePairsWith(rota, e.name);
        }
      }
    }
    _dissolve(s, supersetId);
    _commit();
  }

  bool isTemplatePair(Session s, String supersetId) {
    final rota = rotaById(s.rotaId);
    if (rota == null) return false;
    final names = s.exercises.where((e) => e.supersetId == supersetId).map((e) => exerciseKey(e.name)).toSet();
    return rota.supersets.any((p) => p.map(exerciseKey).toSet().containsAll(names));
  }

  void _applySuperset(Session s, List<String> pair) {
    if (pair.length != 2) return;
    final a = s.exercises.indexWhere((e) => exerciseKey(e.name) == exerciseKey(pair[0]) && e.supersetId == null);
    final b = s.exercises.indexWhere((e) => exerciseKey(e.name) == exerciseKey(pair[1]) && e.supersetId == null);
    if (a < 0 || b < 0) return;
    final first = s.exercises[a];
    final second = s.exercises[b];
    s.exercises.remove(second);
    s.exercises.insert(s.exercises.indexOf(first) + 1, second);
    first.supersetId = second.supersetId = _newId();
  }

  void _dissolve(Session s, String? supersetId) {
    if (supersetId == null) return;
    for (final e in s.exercises) {
      if (e.supersetId == supersetId) e.supersetId = null;
    }
  }

  void _removeTemplatePairsWith(Rota rota, String name) =>
      rota.supersets.removeWhere((p) => p.any((n) => exerciseKey(n) == exerciseKey(name)));

  // ---------- Sets ----------

  void addSet(Session s, int exIndex, double weight, {bool dropSet = false}) {
    s.exercises[exIndex].sets.add(SetLog(weight: weight, dropSet: dropSet));
    _commit();
  }

  void updateSet(Session s, int exIndex, int setIndex, double weight, bool dropSet) {
    final set = s.exercises[exIndex].sets[setIndex];
    set.weight = weight;
    set.dropSet = dropSet;
    _commit();
  }

  void removeSet(Session s, int exIndex, int setIndex) {
    s.exercises[exIndex].sets.removeAt(setIndex);
    _commit();
  }

  void toggleDropSet(Session s, int exIndex, int setIndex) {
    final set = s.exercises[exIndex].sets[setIndex];
    set.dropSet = !set.dropSet;
    _commit();
  }

  /// Finishes the session and returns the PRs hit in it.
  List<logic.RecordEvent> finishSession(Session s) {
    final records = <logic.RecordEvent>[];
    s.exercises.removeWhere((e) => e.sets.isEmpty);
    for (final e in s.exercises) {
      final before = recordBefore(e.name, s.id);
      final top = e.sets.map((x) => x.weight).reduce((a, b) => a > b ? a : b);
      if (logic.isNewRecord(top, before)) records.add(logic.RecordEvent(e.name, top, before!, DateTime.now()));
    }
    s.finishedAt = DateTime.now();
    _commit();
    return records;
  }

  void discardSession(Session s) {
    _data.sessions.remove(s);
    _commit();
  }

  void deleteSession(String id) {
    _data.sessions.removeWhere((s) => s.id == id);
    _commit();
  }

  // ---------- Templates (rotas) ----------

  Rota addRota(String dayId) {
    final dayRotas = rotasOf(dayId);
    if (dayRotas.length == 1 && dayRotas.first.name.isEmpty) dayRotas.first.name = 'A';
    final rota = Rota(
      id: _newId(),
      dayId: dayId,
      name: logic.nextRotaName(rotasOf(dayId)),
      position: dayRotas.length,
    );
    _data.rotas.add(rota);
    _commit();
    return rota;
  }

  Rota duplicateRota(Rota source) {
    final copy = addRota(source.dayId);
    copy.exercises = [...source.exercises];
    _commit();
    return copy;
  }

  void renameRota(Rota rota, String name) {
    rota.name = name.trim();
    _commit();
  }

  /// A day always keeps at least one rota. Returns false when refused.
  bool deleteRota(Rota rota) {
    final dayRotas = rotasOf(rota.dayId);
    if (dayRotas.length <= 1) return false;
    _data.rotas.remove(rota);
    final left = rotasOf(rota.dayId);
    for (var i = 0; i < left.length; i++) {
      left[i].position = i;
    }
    if (left.length == 1 && left.first.name.length == 1) left.first.name = '';
    _commit();
    return true;
  }

  void addRotaExercise(Rota rota, String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _learn(clean);
    rota.exercises.add(clean);
    _commit();
  }

  void removeRotaExercise(Rota rota, int index) {
    rota.exercises.removeAt(index);
    _commit();
  }

  void reorderRotaExercise(Rota rota, int from, int to) {
    final name = rota.exercises.removeAt(from);
    rota.exercises.insert(to > from ? to - 1 : to, name);
    _commit();
  }

  // ---------- Backup ----------

  String exportJson() => _data.encode();

  /// Replaces all data. Throws FormatException on bad input.
  void importJson(String text) {
    try {
      _data = AppData.decode(text);
    } catch (e) {
      throw FormatException('Not a Formazilla backup: $e');
    }
    _commit();
  }
}
