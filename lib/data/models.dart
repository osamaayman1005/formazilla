// Plain data classes for Formazilla. Weights are unitless numbers stored
// exactly as entered.

/// The cycle you follow, e.g. "Push Pull Legs" or "Upper Lower".
/// One split is active at a time; switching never deletes anything.
class Split {
  final String id;
  String name;
  int position;
  bool archived;

  Split({required this.id, required this.name, required this.position, this.archived = false});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'position': position, 'archived': archived};

  factory Split.fromJson(Map<String, dynamic> j) => Split(
        id: j['id'] as String,
        name: j['name'] as String,
        position: j['position'] as int,
        archived: (j['archived'] as bool?) ?? false,
      );
}

/// One step in a split's cycle (Push, Upper, Chest…). Archived days are hidden
/// but kept so past workouts still show their name.
class Day {
  final String id;
  String splitId;
  String name;
  int position;
  bool archived;

  Day({required this.id, required this.name, required this.position, this.splitId = '', this.archived = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'splitId': splitId, 'name': name, 'position': position, 'archived': archived};

  factory Day.fromJson(Map<String, dynamic> j) => Day(
        id: j['id'] as String,
        splitId: (j['splitId'] as String?) ?? '', // '' = schema v2, set by migration
        name: j['name'] as String,
        position: j['position'] as int,
        archived: (j['archived'] as bool?) ?? false,
      );
}

class Rotation {
  final String id;
  final String dayId;
  String name; // "A", "B" ... or "" when the day has a single rotation
  int position;
  bool isStarter;
  List<String> exercises;

  /// Pairs of exercise names that are always done as a superset.
  List<List<String>> supersets;

  Rotation({
    required this.id,
    required this.dayId,
    required this.name,
    required this.position,
    this.isStarter = false,
    List<String>? exercises,
    List<List<String>>? supersets,
  })  : exercises = exercises ?? [],
        supersets = supersets ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayId': dayId,
        'name': name,
        'position': position,
        'isStarter': isStarter,
        'exercises': exercises,
        'supersets': supersets,
      };

  factory Rotation.fromJson(Map<String, dynamic> j) => Rotation(
        id: j['id'] as String,
        dayId: j['dayId'] as String,
        name: j['name'] as String,
        position: j['position'] as int,
        isStarter: (j['isStarter'] as bool?) ?? false,
        exercises: (j['exercises'] as List).cast<String>().toList(),
        supersets: ((j['supersets'] as List?) ?? const [])
            .map((p) => (p as List).cast<String>().toList())
            .toList(),
      );
}

class SetLog {
  double weight;
  bool dropSet;

  SetLog({required this.weight, this.dropSet = false});

  Map<String, dynamic> toJson() => {'w': weight, 'ds': dropSet};

  factory SetLog.fromJson(Map<String, dynamic> j) =>
      SetLog(weight: (j['w'] as num).toDouble(), dropSet: (j['ds'] as bool?) ?? false);
}

class SessionExercise {
  String name;
  List<SetLog> sets;

  /// Exercises sharing the same id are done as a superset (alternating).
  String? supersetId;

  /// Cardio is logged as time (minutes) instead of weight sets.
  bool cardio;
  double? minutes;

  SessionExercise({required this.name, List<SetLog>? sets, this.supersetId, this.cardio = false, this.minutes})
      : sets = sets ?? [];

  /// Something was logged: a set, or cardio time.
  bool get logged => cardio ? minutes != null : sets.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets.map((s) => s.toJson()).toList(),
        if (supersetId != null) 'ss': supersetId,
        if (cardio) 'c': true,
        if (minutes != null) 'min': minutes,
      };

  factory SessionExercise.fromJson(Map<String, dynamic> j) => SessionExercise(
        name: j['name'] as String,
        supersetId: j['ss'] as String?,
        cardio: (j['c'] as bool?) ?? false,
        minutes: (j['min'] as num?)?.toDouble(),
        sets: (j['sets'] as List).map((e) => SetLog.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Session {
  final String id;
  String dayId;
  String rotationId;
  DateTime startedAt;
  DateTime? finishedAt;
  List<SessionExercise> exercises;

  /// A one-time workout: outside any plan (empty dayId/rotationId). It counts
  /// for PRs and History only — no suggestion, last-time values or Progress.
  bool oneTime;
  String? title;

  /// The exercise you're on (the one you logged most recently).
  String? current;

  Session({
    required this.id,
    required this.dayId,
    required this.rotationId,
    required this.startedAt,
    this.finishedAt,
    List<SessionExercise>? exercises,
    this.oneTime = false,
    this.title,
    this.current,
  }) : exercises = exercises ?? [];

  bool get isFinished => finishedAt != null;

  int get setCount => exercises.fold(0, (a, e) => a + e.sets.length);

  /// Total cardio minutes logged.
  double get cardioMinutes => exercises.fold(0.0, (a, e) => a + (e.minutes ?? 0));

  /// Anything logged at all (sets or cardio time).
  bool get hasLogs => exercises.any((e) => e.logged);

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayId': dayId,
        'rotationId': rotationId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        if (oneTime) 'oneTime': true,
        if (title != null) 'title': title,
        if (current != null) 'cur': current,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        dayId: j['dayId'] as String,
        rotationId: (j['rotationId'] ?? j['rotaId']) as String, // 'rotaId' = schema v1
        startedAt: DateTime.parse(j['startedAt'] as String),
        finishedAt: j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt'] as String),
        oneTime: (j['oneTime'] as bool?) ?? false,
        title: j['title'] as String?,
        current: j['cur'] as String?,
        exercises: (j['exercises'] as List)
            .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
