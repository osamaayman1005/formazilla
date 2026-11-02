/// Pure rules of the app: next-session suggestion, PRs, last-time values.
/// No Flutter imports, so everything here is unit-testable.
library;

import '../core/format.dart';
import '../data/models.dart';

/// Finished sessions, newest first.
List<Session> finishedNewestFirst(Iterable<Session> sessions) {
  final list = sessions.where((s) => s.isFinished).toList()
    ..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));
  return list;
}

/// Rotas of a day, in display order.
List<Rota> rotasForDay(String dayId, Iterable<Rota> rotas) =>
    rotas.where((r) => r.dayId == dayId).toList()..sort((a, b) => a.position.compareTo(b.position));

/// The day after the last finished session's day. First day when no history.
Day suggestDay(List<Day> days, Iterable<Session> sessions) {
  final ordered = [...days]..sort((a, b) => a.position.compareTo(b.position));
  final history = finishedNewestFirst(sessions);
  if (history.isEmpty) return ordered.first;
  final lastIndex = ordered.indexWhere((d) => d.id == history.first.dayId);
  if (lastIndex < 0) return ordered.first;
  return ordered[(lastIndex + 1) % ordered.length];
}

/// For a day: its only rota, or the one after the rota used last time.
Rota? suggestRota(String dayId, Iterable<Rota> rotas, Iterable<Session> sessions) {
  final dayRotas = rotasForDay(dayId, rotas);
  if (dayRotas.isEmpty) return null;
  if (dayRotas.length == 1) return dayRotas.first;
  final last = finishedNewestFirst(sessions).where((s) => s.dayId == dayId).firstOrNull;
  if (last == null) return dayRotas.first;
  final i = dayRotas.indexWhere((r) => r.id == last.rotaId);
  if (i < 0) return dayRotas.first;
  return dayRotas[(i + 1) % dayRotas.length];
}

/// When a day was last trained, or null.
DateTime? lastDoneAt(String dayId, Iterable<Session> sessions) =>
    finishedNewestFirst(sessions).where((s) => s.dayId == dayId).firstOrNull?.finishedAt;

/// Best single set ever for an exercise across finished sessions.
/// [excludeSessionId] lets the live session compare against history only.
double? personalRecord(String exercise, Iterable<Session> sessions, {String? excludeSessionId}) {
  final key = exerciseKey(exercise);
  double? best;
  for (final s in sessions) {
    if (!s.isFinished || s.id == excludeSessionId) continue;
    for (final e in s.exercises) {
      if (exerciseKey(e.name) != key) continue;
      for (final set in e.sets) {
        if (best == null || set.weight > best) best = set.weight;
      }
    }
  }
  return best;
}

/// A weight is a new PR only when it beats an existing record (ties don't count).
bool isNewRecord(double weight, double? previousBest) => previousBest != null && weight > previousBest;

/// Sets from the most recent finished session that contains this exercise.
List<double> lastTimeWeights(String exercise, Iterable<Session> sessions, {String? excludeSessionId}) {
  final key = exerciseKey(exercise);
  for (final s in finishedNewestFirst(sessions)) {
    if (s.id == excludeSessionId) continue;
    for (final e in s.exercises) {
      if (exerciseKey(e.name) == key && e.sets.isNotEmpty) {
        return e.sets.map((x) => x.weight).toList();
      }
    }
  }
  return const [];
}

/// One point per finished session: the top set for this exercise, oldest first.
class TopSet {
  final DateTime date;
  final double weight;
  final List<double> allSets;
  final bool wasRecord;
  const TopSet(this.date, this.weight, this.allSets, this.wasRecord);
}

List<TopSet> topSetHistory(String exercise, Iterable<Session> sessions) {
  final key = exerciseKey(exercise);
  final oldestFirst = finishedNewestFirst(sessions).reversed;
  final out = <TopSet>[];
  double? best;
  for (final s in oldestFirst) {
    final sets = <double>[];
    for (final e in s.exercises) {
      if (exerciseKey(e.name) == key) sets.addAll(e.sets.map((x) => x.weight));
    }
    if (sets.isEmpty) continue;
    final top = sets.reduce((a, b) => a > b ? a : b);
    final record = isNewRecord(top, best);
    if (best == null || top > best) best = top;
    out.add(TopSet(s.finishedAt!, top, sets, record));
  }
  return out;
}

/// A PR achieved in a finished session.
class RecordEvent {
  final String exercise;
  final double weight;
  final double previous;
  final DateTime date;
  const RecordEvent(this.exercise, this.weight, this.previous, this.date);
  double get delta => weight - previous;
}

/// Newest PR events across all exercises.
List<RecordEvent> recentRecords(Iterable<Session> sessions, {int limit = 5}) {
  final best = <String, double>{};
  final names = <String, String>{};
  final events = <RecordEvent>[];
  for (final s in finishedNewestFirst(sessions).reversed) {
    for (final e in s.exercises) {
      if (e.sets.isEmpty) continue;
      final key = exerciseKey(e.name);
      names[key] = e.name;
      final top = e.sets.map((x) => x.weight).reduce((a, b) => a > b ? a : b);
      final prev = best[key];
      if (isNewRecord(top, prev)) events.add(RecordEvent(e.name, top, prev!, s.finishedAt!));
      if (prev == null || top > prev) best[key] = top;
    }
  }
  return events.reversed.take(limit).toList();
}

/// Every exercise name that has logged sets, with its PR, most recently used first.
class ExerciseSummary {
  final String name;
  final double record;
  final DateTime lastUsed;
  const ExerciseSummary(this.name, this.record, this.lastUsed);
}

List<ExerciseSummary> exerciseSummaries(Iterable<Session> sessions) {
  final map = <String, ExerciseSummary>{};
  for (final s in finishedNewestFirst(sessions).reversed) {
    for (final e in s.exercises) {
      if (e.sets.isEmpty) continue;
      final key = exerciseKey(e.name);
      final top = e.sets.map((x) => x.weight).reduce((a, b) => a > b ? a : b);
      final old = map[key];
      final record = old == null || top > old.record ? top : old.record;
      map[key] = ExerciseSummary(e.name, record, s.finishedAt!);
    }
  }
  return map.values.toList()..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
}

/// Name for a new rota on a day: "B" after "A", etc.
String nextRotaName(List<Rota> dayRotas) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final used = dayRotas.map((r) => r.name).toSet();
  for (final c in letters.split('')) {
    if (!used.contains(c)) return c;
  }
  return '${dayRotas.length + 1}';
}

/// Autocomplete: prefix matches first, then contains, without duplicates.
List<String> searchExercises(String query, List<String> library, {int limit = 8}) {
  final q = exerciseKey(query);
  if (q.isEmpty) return const [];
  final prefix = library.where((n) => exerciseKey(n).startsWith(q));
  final contains = library.where((n) => !exerciseKey(n).startsWith(q) && exerciseKey(n).contains(q));
  return [...prefix, ...contains].take(limit).toList();
}

// ---------- Supersets ----------

/// Which member of a superset to do next: the one with the fewest sets so far
/// (the first one wins ties), so A → B → A → B.
int supersetNext(List<int> setCounts) {
  var best = 0;
  for (var i = 1; i < setCounts.length; i++) {
    if (setCounts[i] < setCounts[best]) best = i;
  }
  return best;
}

/// Current round, 1-based: full rounds completed + 1.
int supersetRound(List<int> setCounts) =>
    setCounts.isEmpty ? 1 : setCounts.reduce((a, b) => a < b ? a : b) + 1;

// ---------- PR share card ----------

/// Everything the PR share card shows for one exercise.
class RecordCardData {
  final String exercise;
  final double record;
  final double gain;
  final DateTime since;
  final List<double> recentTops;
  const RecordCardData(this.exercise, this.record, this.gain, this.since, this.recentTops);
}

RecordCardData? recordCardData(String exercise, Iterable<Session> sessions, {int bars = 7}) {
  final history = topSetHistory(exercise, sessions);
  if (history.isEmpty) return null;
  final record = history.map((p) => p.weight).reduce((a, b) => a > b ? a : b);
  final tops = history.map((p) => p.weight).toList();
  return RecordCardData(
    exercise,
    record,
    record - history.first.weight,
    history.first.date,
    tops.length > bars ? tops.sublist(tops.length - bars) : tops,
  );
}
