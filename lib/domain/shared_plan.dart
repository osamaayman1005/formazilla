/// Sharing plans between phones without a server: a plan travels as a normal
/// chat message with a short code line (`FZ1:…`) the app can read back.
library;

import 'dart:convert';

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

const planCodePrefix = 'FZ1:';

/// The code line the app reads back.
String planCode(SharedPlan plan) => planCodePrefix + base64Url.encode(utf8.encode(jsonEncode(plan.toJson())));

/// Finds a plan code anywhere in [text] (e.g. a whole pasted chat message).
/// Null when there is none or it's damaged.
SharedPlan? readPlan(String? text) {
  if (text == null) return null;
  final match = RegExp(r'FZ1:([A-Za-z0-9_\-]+=*)').firstMatch(text);
  if (match == null) return null;
  try {
    final json = jsonDecode(utf8.decode(base64Url.decode(match.group(1)!))) as Map<String, dynamic>;
    final plan = SharedPlan.fromJson(json);
    if (plan.days.isEmpty || plan.days.any((d) => d.rotations.isEmpty)) return null;
    return plan;
  } catch (_) {
    return null;
  }
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
