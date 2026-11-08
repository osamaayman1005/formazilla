/// Sharing plans between phones without a server: a plan travels as a normal
/// chat message with a short code line (`FZ1:…`) the app can read back.
library;

import 'dart:convert';
import 'dart:io' show gzip;

import '../core/format.dart';

class SharedRotation {
  final String name; // "A", "B" … or "" for a day's only rotation
  final List<String> exercises;
  final List<List<String>> supersets;

  /// Which of [exercises] are cardio (logged as time).
  final List<String> cardio;

  /// Optional last-time weights per exercise (only when the sender chose to).
  final Map<String, List<double>> weights;

  const SharedRotation({
    required this.name,
    required this.exercises,
    this.supersets = const [],
    this.cardio = const [],
    this.weights = const {},
  });

  Map<String, dynamic> toJson() => {
        'n': name,
        'e': exercises,
        if (supersets.isNotEmpty) 's': supersets,
        if (cardio.isNotEmpty) 'c': cardio,
        if (weights.isNotEmpty) 'w': weights,
      };

  factory SharedRotation.fromJson(Map<String, dynamic> j) => SharedRotation(
        name: (j['n'] as String?) ?? '',
        exercises: (j['e'] as List).cast<String>().toList(),
        supersets: ((j['s'] as List?) ?? const []).map((p) => (p as List).cast<String>().toList()).toList(),
        cardio: ((j['c'] as List?) ?? const []).cast<String>().toList(),
        weights: ((j['w'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as List).map((x) => (x as num).toDouble()).toList()),
        ),
      );
}

class SharedDay {
  final String name;
  final List<SharedRotation> rotations;
  const SharedDay({required this.name, required this.rotations});

  Map<String, dynamic> toJson() => {'n': name, 'r': rotations.map((r) => r.toJson()).toList()};

  factory SharedDay.fromJson(Map<String, dynamic> j) => SharedDay(
        name: j['n'] as String,
        rotations: (j['r'] as List).map((r) => SharedRotation.fromJson(r as Map<String, dynamic>)).toList(),
      );
}

/// A whole split, or a single rotation (one day holding one rotation).
class SharedPlan {
  final String name; // split name, e.g. "Push Pull Legs"
  final bool isSplit;
  final List<SharedDay> days;

  const SharedPlan({required this.name, required this.isSplit, required this.days});

  /// Single rotation shared on its own.
  SharedRotation get rotation => days.first.rotations.first;

  /// "Push Pull Legs", or "Push A" / "Legs" for one rotation.
  String get title => isSplit ? name : rotationTitle(days.first.name, rotation.name);

  int get rotationCount => days.fold(0, (n, d) => n + d.rotations.length);
  int get exerciseCount => days.fold(0, (n, d) => n + d.rotations.fold(0, (m, r) => m + r.exercises.length));

  /// "3 days · 5 rotations" or "7 exercises".
  String get summary {
    if (!isSplit) return '${rotation.exercises.length} exercise${rotation.exercises.length == 1 ? '' : 's'}';
    final d = days.length, r = rotationCount;
    return '$d day${d == 1 ? '' : 's'} · $r rotation${r == 1 ? '' : 's'}';
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'n': name,
        'split': isSplit,
        'd': days.map((d) => d.toJson()).toList(),
      };

  factory SharedPlan.fromJson(Map<String, dynamic> j) => SharedPlan(
        name: j['n'] as String,
        isSplit: j['split'] as bool,
        days: (j['d'] as List).map((d) => SharedDay.fromJson(d as Map<String, dynamic>)).toList(),
      );
}

String rotationTitle(String day, String rotation) => rotation.isEmpty ? day : '$day $rotation';

/// FZ2 = gzipped JSON (about half the size, so a whole split fits an easy
/// QR). FZ1 = plain JSON from the first share version; still readable.
const planCodePrefix = 'FZ2:';

/// The code line (and QR content) the app reads back.
String planCode(SharedPlan plan) =>
    planCodePrefix + base64Url.encode(gzip.encode(utf8.encode(jsonEncode(plan.toJson()))));

/// Finds a plan anywhere in [text] (a pasted chat message, a scanned QR, or
/// an AI's answer). Null when there is none or it's damaged.
///
/// Reads, in order: an `FZ2:`/`FZ1:` code, then the last fenced
/// ```` ```formazilla ```` block (or a ```` ```json ```` block that looks like
/// a plan). Plans outside [checkPlan]'s limits are rejected.
SharedPlan? readPlan(String? text) {
  if (text == null) return null;
  final match = RegExp(r'FZ([12]):([A-Za-z0-9_\-]+=*)').firstMatch(text);
  if (match != null) {
    try {
      final bytes = base64Url.decode(match.group(2)!);
      final raw = match.group(1) == '2' ? gzip.decode(bytes) : bytes;
      final json = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
      // Codes come from Formazilla itself: same rules as always.
      final plan = SharedPlan.fromJson(json);
      if (plan.days.isNotEmpty && plan.days.every((d) => d.rotations.isNotEmpty)) return plan;
    } catch (_) {
      // Fall through: an AI answer may still hold a fenced block.
    }
  }
  final block = _lastPlanBlock(text);
  if (block == null) return null;
  try {
    final json = jsonDecode(block.json) as Map<String, dynamic>;
    // AIs sometimes drop the optional-looking keys.
    final days = json['d'] as List;
    json['n'] ??= 'New split';
    json['split'] ??= days.length > 1 || ((days.first as Map)['r'] as List).length > 1;
    return checkPlan(SharedPlan.fromJson(json));
  } catch (_) {
    return null;
  }
}

/// True when [text] has a plan block or code, even a broken one: the reply
/// screen then says "couldn't be read" instead of "no plan".
bool hasPlanBlock(String text) =>
    _lastPlanBlock(text) != null || RegExp(r'FZ[12]:[A-Za-z0-9_\-]{8,}').hasMatch(text);

/// [text] without its plan block (for showing an AI's answer).
String stripPlanBlock(String text) {
  final block = _lastPlanBlock(text);
  if (block == null) return text.trim();
  return (text.substring(0, block.start) + text.substring(block.end)).trim();
}

final _fence = RegExp(r'```[ \t]*([A-Za-z]*)[ \t]*\r?\n([\s\S]*?)```');

({String json, int start, int end})? _lastPlanBlock(String text) {
  ({String json, int start, int end})? found;
  for (final m in _fence.allMatches(text)) {
    final lang = m.group(1)!.toLowerCase();
    final body = m.group(2)!.trim();
    final looksLikePlan = body.startsWith('{') && body.contains('"d"');
    if (lang == 'formazilla' || ((lang == 'json' || lang.isEmpty) && looksLikePlan && body.contains('"v"'))) {
      found = (json: body, start: m.start, end: m.end);
    }
  }
  return found;
}

/// Limits for a plan that came from outside the app. Names are trimmed and
/// capped; supersets and cardio that name exercises not in the list are
/// dropped. Null when the plan is empty or too big.
SharedPlan? checkPlan(SharedPlan plan) {
  final control = RegExp(r'[\x00-\x1F\x7F]');
  String? clean(String s) {
    final t = s.replaceAll(control, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty || t.length > 60 ? null : t;
  }

  if (plan.days.isEmpty || plan.days.length > 10) return null;
  final name = clean(plan.name) ?? (plan.isSplit ? 'New split' : 'Workout');
  final days = <SharedDay>[];
  for (final d in plan.days) {
    final dayName = clean(d.name);
    if (dayName == null || d.rotations.isEmpty || d.rotations.length > 6) return null;
    final rotations = <SharedRotation>[];
    for (final r in d.rotations) {
      if (r.exercises.isEmpty || r.exercises.length > 15) return null;
      final exercises = <String>[];
      for (final e in r.exercises) {
        final c = clean(e);
        if (c == null) return null;
        if (!exercises.contains(c)) exercises.add(c);
      }
      final weights = <String, List<double>>{};
      for (final entry in r.weights.entries) {
        final c = clean(entry.key);
        if (c == null || !exercises.contains(c)) continue;
        if (entry.value.length > 10 || entry.value.any((w) => w.isNaN || w < 0 || w > 9999)) return null;
        weights[c] = entry.value;
      }
      rotations.add(SharedRotation(
        name: clean(r.name) ?? '',
        exercises: exercises,
        supersets: [
          for (final p in r.supersets)
            if (p.length >= 2 && p.every((x) => exercises.contains(clean(x)))) [for (final x in p) clean(x)!],
        ],
        cardio: [
          for (final x in r.cardio)
            if (exercises.contains(clean(x))) clean(x)!,
        ],
        weights: weights,
      ));
    }
    days.add(SharedDay(name: dayName, rotations: rotations));
  }
  return SharedPlan(name: name, isSplit: plan.isSplit, days: days);
}

/// Maps each exercise to the spelling the user already has when it's the
/// same name ignoring case, so PRs and history connect.
SharedPlan matchExerciseNames(SharedPlan plan, Iterable<String> known) {
  final byKey = {for (final k in known) exerciseKey(k): k};
  String map(String n) => byKey[exerciseKey(n)] ?? n;
  return SharedPlan(name: plan.name, isSplit: plan.isSplit, days: [
    for (final d in plan.days)
      SharedDay(name: d.name, rotations: [
        for (final r in d.rotations)
          SharedRotation(
            name: r.name,
            exercises: r.exercises.map(map).toList(),
            supersets: [for (final p in r.supersets) p.map(map).toList()],
            cardio: r.cardio.map(map).toList(),
            weights: {for (final e in r.weights.entries) map(e.key): e.value},
          ),
      ]),
  ]);
}

/// A readable message. With [withCode] it ends with the import line.
String planMessage(SharedPlan plan, {bool withCode = false}) {
  final b = StringBuffer();
  if (plan.isSplit) {
    b.writeln('${plan.title} (${plan.summary})');
    for (final day in plan.days) {
      for (final r in day.rotations) {
        b
          ..writeln()
          ..writeln(rotationTitle(day.name, r.name));
        _writeExercises(b, r);
      }
    }
  } else {
    b.writeln(plan.title);
    _writeExercises(b, plan.rotation);
  }
  if (withCode) {
    b
      ..writeln()
      ..writeln('To add it: copy this whole message, then open Formazilla → Templates → Import plan.')
      ..write(planCode(plan));
  }
  return b.toString().trimRight();
}

void _writeExercises(StringBuffer b, SharedRotation r) {
  for (var i = 0; i < r.exercises.length; i++) {
    final name = r.exercises[i];
    final w = r.weights[name];
    final tag = r.cardio.contains(name) ? ' (cardio)' : '';
    b.writeln('${i + 1}. $name$tag${w == null || w.isEmpty ? '' : ' — ${formatWeights(w)}'}');
  }
}
