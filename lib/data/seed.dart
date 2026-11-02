/// Starter data loaded on first launch. Everything here is editable in the app.
library;

import 'models.dart';

/// Ready-made splits: split name -> day name -> rotation name -> exercises.
/// A day with a single rotation uses rotation name "".
const splitPresets = <String, Map<String, Map<String, List<String>>>>{
  'Push Pull Legs': {
    'Push': {
      'A': [
        'Chest press',
        'Incline dumbbell press',
        'Pec deck fly',
        'Shoulder press machine',
        'Lateral raise',
        'Triceps rope pushdown',
        'Dips',
      ],
      'B': [
        'Incline chest press',
        'Flat bench press',
        'Cable crossover',
        'Overhead press',
        'Lateral raise',
        'Overhead triceps extension',
      ],
    },
    'Pull': {
      'A': [
        'Lat pulldown',
        'Seated cable row',
        'Barbell row',
        'Face pull',
        'Rear delt fly',
        'Barbell curl',
        'Hammer curl',
      ],
      'B': [
        'Pull-ups',
        'T-bar row',
        'One-arm dumbbell row',
        'Straight-arm pulldown',
        'Shrugs',
        'Preacher curl',
      ],
    },
    'Legs': {
      '': [
        'Squat',
        'Leg press',
        'Leg extension',
        'Lying leg curl',
        'Hip abduction',
        'Hip adduction',
        'Calf raise',
      ],
    },
  },
  'Upper / Lower': {
    'Upper': {
      'A': ['Flat bench press', 'Lat pulldown', 'Overhead press', 'Seated cable row', 'Lateral raise', 'Triceps rope pushdown', 'Barbell curl'],
      'B': ['Incline dumbbell press', 'Pull-ups', 'Arnold press', 'T-bar row', 'Cable crossover', 'Hammer curl'],
    },
    'Lower': {
      'A': ['Squat', 'Romanian deadlift', 'Leg press', 'Lying leg curl', 'Calf raise'],
      'B': ['Hack squat', 'Hip thrust', 'Leg extension', 'Seated leg curl', 'Seated calf raise'],
    },
  },
  'Full body': {
    'Full body': {
      'A': ['Squat', 'Flat bench press', 'Seated cable row', 'Overhead press', 'Lying leg curl'],
      'B': ['Romanian deadlift', 'Incline dumbbell press', 'Lat pulldown', 'Lateral raise', 'Leg extension'],
      'C': ['Leg press', 'Chest press', 'T-bar row', 'Arnold press', 'Calf raise'],
    },
  },
  'Bro split': {
    'Chest': {'': ['Flat bench press', 'Incline dumbbell press', 'Pec deck fly', 'Cable crossover', 'Dips']},
    'Back': {'': ['Pull-ups', 'Lat pulldown', 'Barbell row', 'Seated cable row', 'Straight-arm pulldown']},
    'Shoulders': {'': ['Overhead press', 'Lateral raise', 'Front raise', 'Rear delt fly', 'Shrugs']},
    'Arms': {'': ['Barbell curl', 'Triceps rope pushdown', 'Hammer curl', 'Skull crusher', 'Preacher curl']},
    'Legs': {'': ['Squat', 'Leg press', 'Leg extension', 'Lying leg curl', 'Calf raise']},
  },
  'Arnold': {
    'Chest + Back': {'': ['Flat bench press', 'Pull-ups', 'Incline dumbbell press', 'Barbell row', 'Pec deck fly', 'Seated cable row']},
    'Shoulders + Arms': {'': ['Overhead press', 'Lateral raise', 'Rear delt fly', 'Barbell curl', 'Triceps rope pushdown', 'Hammer curl']},
    'Legs': {'': ['Squat', 'Leg press', 'Romanian deadlift', 'Leg extension', 'Lying leg curl', 'Calf raise']},
  },
};

/// Shown as the preset's subtitle in the picker.
String presetSummary(String preset) => (splitPresets[preset]?.keys ?? const <String>[]).join(' · ');

const defaultSplit = 'Push Pull Legs';

/// Extra names offered by autocomplete.
const extraLibrary = [
  'Flat dumbbell press', 'Decline chest press', 'Smith machine bench press', 'Cable fly (low to high)',
  'Arnold press', 'Front raise', 'Cable lateral raise', 'Upright row', 'Skull crusher', 'Triceps machine',
  'Close-grip bench press', 'Rear delt rope pull', 'Chest-supported row', 'Machine row',
  'Wide-grip lat pulldown', 'Close-grip lat pulldown', 'Back extension', 'Deadlift', 'Rack pull',
  'Dumbbell curl', 'Incline dumbbell curl', 'Cable curl', 'Biceps machine', 'EZ-bar curl',
  'Concentration curl', 'Romanian deadlift', 'Hack squat', 'Bulgarian split squat', 'Walking lunge',
  'Goblet squat', 'Seated leg curl', 'Hip thrust', 'Glute kickback', 'Seated calf raise',
  'Standing calf raise', 'Leg press calf raise', 'Cable crunch', 'Hanging leg raise', 'Ab machine', 'Plank',
];

/// A split with its days and rotations, ready to add to the store.
class SplitBundle {
  final Split split;
  final List<Day> days;
  final List<Rotation> rotations;
  const SplitBundle(this.split, this.days, this.rotations);

  Iterable<String> get exerciseNames => rotations.expand((r) => r.exercises);
}

/// Builds a split from a preset name. Unknown names (e.g. "Custom") give one
/// empty day so the split can be started right away.
SplitBundle buildSplit(String preset, String Function() newId, {String? name, int position = 0}) {
  final split = Split(id: newId(), name: name ?? preset, position: position);
  final days = <Day>[];
  final rotations = <Rotation>[];
  final plan = splitPresets[preset] ?? const {'Day 1': {'': <String>[]}};
  var dayPos = 0;
  plan.forEach((dayName, rotationsByName) {
    final day = Day(id: newId(), splitId: split.id, name: dayName, position: dayPos++);
    days.add(day);
    var pos = 0;
    rotationsByName.forEach((rotationName, exercises) {
      rotations.add(Rotation(
        id: newId(),
        dayId: day.id,
        name: rotationName,
        position: pos++,
        isStarter: splitPresets.containsKey(preset),
        exercises: [...exercises],
      ));
    });
  });
  return SplitBundle(split, days, rotations);
}

/// First-launch data: the default split plus the exercise library.
class SeedData {
  final SplitBundle split;
  final List<String> library;
  const SeedData(this.split, this.library);
}

SeedData buildSeed(String Function() newId) {
  final bundle = buildSplit(defaultSplit, newId);
  final library = <String>[];
  for (final e in [...splitPresets.values.expand((d) => d.values.expand((r) => r.values.expand((x) => x))), ...extraLibrary]) {
    if (!library.contains(e)) library.add(e);
  }
  return SeedData(bundle, library);
}
