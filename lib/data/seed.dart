/// Starter data loaded on first launch. Everything here is editable in the app.
library;

import 'models.dart';

const starterDays = ['Push', 'Pull', 'Legs'];

/// day name -> rotation name -> exercises in order. A single rotation uses name "".
const starterRotations = <String, Map<String, List<String>>>{
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
};

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

class SeedData {
  final List<Day> days;
  final List<Rotation> rotations;
  final List<String> library;
  const SeedData(this.days, this.rotations, this.library);
}

SeedData buildSeed(String Function() newId) {
  final days = <Day>[];
  final rotations = <Rotation>[];
  final library = <String>[];

  for (var i = 0; i < starterDays.length; i++) {
    final day = Day(id: newId(), name: starterDays[i], position: i);
    days.add(day);
    var pos = 0;
    starterRotations[day.name]!.forEach((rotationName, exercises) {
      rotations.add(Rotation(
        id: newId(),
        dayId: day.id,
        name: rotationName,
        position: pos++,
        isStarter: true,
        exercises: [...exercises],
      ));
      for (final e in exercises) {
        if (!library.contains(e)) library.add(e);
      }
    });
  }
  library.addAll(extraLibrary.where((e) => !library.contains(e)));
  return SeedData(days, rotations, library);
}
