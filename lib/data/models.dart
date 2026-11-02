// Plain data classes for Formazilla. Weights are unitless numbers stored
// exactly as entered.

class Day {
  final String id;
  String name;
  int position;

  Day({required this.id, required this.name, required this.position});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'position': position};

  factory Day.fromJson(Map<String, dynamic> j) =>
      Day(id: j['id'] as String, name: j['name'] as String, position: j['position'] as int);
}

class Rota {
  final String id;
  final String dayId;
  String name; // "A", "B" ... or "" when the day has a single rota
  int position;
  bool isStarter;
  List<String> exercises;

  Rota({
    required this.id,
    required this.dayId,
    required this.name,
    required this.position,
    this.isStarter = false,
    List<String>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayId': dayId,
        'name': name,
        'position': position,
        'isStarter': isStarter,
        'exercises': exercises,
      };

  factory Rota.fromJson(Map<String, dynamic> j) => Rota(
        id: j['id'] as String,
        dayId: j['dayId'] as String,
        name: j['name'] as String,
        position: j['position'] as int,
        isStarter: (j['isStarter'] as bool?) ?? false,
        exercises: (j['exercises'] as List).cast<String>().toList(),
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

  SessionExercise({required this.name, List<SetLog>? sets}) : sets = sets ?? [];

  Map<String, dynamic> toJson() => {'name': name, 'sets': sets.map((s) => s.toJson()).toList()};

  factory SessionExercise.fromJson(Map<String, dynamic> j) => SessionExercise(
        name: j['name'] as String,
        sets: (j['sets'] as List).map((e) => SetLog.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Session {
  final String id;
  String dayId;
  String rotaId;
  DateTime startedAt;
  DateTime? finishedAt;
  List<SessionExercise> exercises;

  Session({
    required this.id,
    required this.dayId,
    required this.rotaId,
    required this.startedAt,
    this.finishedAt,
    List<SessionExercise>? exercises,
  }) : exercises = exercises ?? [];

  bool get isFinished => finishedAt != null;

  int get setCount => exercises.fold(0, (a, e) => a + e.sets.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayId': dayId,
        'rotaId': rotaId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        dayId: j['dayId'] as String,
        rotaId: j['rotaId'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        finishedAt: j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt'] as String),
        exercises: (j['exercises'] as List)
            .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
