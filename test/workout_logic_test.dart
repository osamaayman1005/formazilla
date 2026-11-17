import 'package:flutter_test/flutter_test.dart';
import 'package:formazilla/core/format.dart';
import 'package:formazilla/data/models.dart';
import 'package:formazilla/domain/workout_logic.dart';

final push = Day(id: 'push', name: 'Push', position: 0);
final pull = Day(id: 'pull', name: 'Pull', position: 1);
final legs = Day(id: 'legs', name: 'Legs', position: 2);
final days = [push, pull, legs];

final pushA = Rotation(id: 'pa', dayId: 'push', name: 'A', position: 0);
final pushB = Rotation(id: 'pb', dayId: 'push', name: 'B', position: 1);
final pullA = Rotation(id: 'la', dayId: 'pull', name: 'A', position: 0);
final pullB = Rotation(id: 'lb', dayId: 'pull', name: 'B', position: 1);
final legsOnly = Rotation(id: 'lg', dayId: 'legs', name: '', position: 0);
final rotations = [pushA, pushB, pullA, pullB, legsOnly];

int _n = 0;
Session done(Rotation r, int day, [Map<String, List<double>> sets = const {}]) => Session(
      id: 's${_n++}',
      dayId: r.dayId,
      rotationId: r.id,
      startedAt: DateTime(2026, 11, day, 10),
      finishedAt: DateTime(2026, 11, day, 11),
      exercises: [
        for (final e in sets.entries)
          SessionExercise(name: e.key, sets: e.value.map((w) => SetLog(weight: w)).toList()),
      ],
    );

void main() {
  group('next session suggestion', () {
    test('no history suggests the first day and first rotation', () {
      expect(suggestDay(days, []).id, 'push');
      expect(suggestRotation('push', rotations, [])!.id, 'pa');
    });

    test('day after the last workout', () {
      expect(suggestDay(days, [done(pushA, 1)]).id, 'pull');
      expect(suggestDay(days, [done(pushA, 1), done(pullA, 2)]).id, 'legs');
      expect(suggestDay(days, [done(legsOnly, 3)]).id, 'push');
    });

    test('rotation alternates A -> B -> A', () {
      expect(suggestRotation('pull', rotations, [done(pullA, 1)])!.id, 'lb');
      expect(suggestRotation('pull', rotations, [done(pullA, 1), done(pullB, 4)])!.id, 'la');
    });

    test('single rotation is always used', () {
      expect(suggestRotation('legs', rotations, [done(legsOnly, 1)])!.id, 'lg');
    });

    test('skipping the suggestion moves the cycle on from what was done', () {
      // Suggested Pull, but user did Legs: next is Push.
      expect(suggestDay(days, [done(pushA, 1), done(legsOnly, 2)]).id, 'push');
    });

    test('only workouts from the active split count', () {
      final upper = Rotation(id: 'up', dayId: 'upper', name: '', position: 0);
      // Last workout was in another split: PPL starts from its own history.
      expect(suggestDay(days, [done(pushA, 1), done(upper, 2)]).id, 'pull');
      expect(suggestDay(days, [done(upper, 2)]).id, 'push');
    });

    test('works for any number of days', () {
      final five = [for (var i = 0; i < 5; i++) Day(id: 'd$i', name: 'D$i', position: i)];
      final r4 = Rotation(id: 'r4', dayId: 'd4', name: '', position: 0);
      final r2 = Rotation(id: 'r2', dayId: 'd2', name: '', position: 0);
      expect(suggestDay(five, [done(r2, 1)]).id, 'd3');
      expect(suggestDay(five, [done(r4, 1)]).id, 'd0');
    });

    test('unfinished sessions are ignored', () {
      final open = Session(id: 'x', dayId: 'pull', rotationId: 'la', startedAt: DateTime(2026, 11, 5));
      expect(suggestDay(days, [done(pushA, 1), open]).id, 'pull');
    });
  });

  group('records', () {
    test('PR is the best set across finished sessions', () {
      final h = [done(pushA, 1, {'Fly': [120, 140, 160]}), done(pushA, 4, {'fly': [150, 200]})];
      expect(personalRecord('Fly', h), 200);
    });

    test('ties are not new records and the first ever set is not either', () {
      expect(isNewRecord(200, 200), isFalse);
      expect(isNewRecord(201, 200), isTrue);
      expect(isNewRecord(50, null), isFalse);
    });

    test('recent records list deltas, newest first', () {
      final h = [
        done(pushA, 1, {'Fly': [160]}),
        done(pushA, 4, {'Fly': [200]}),
        done(pushA, 7, {'Fly': [180]}),
      ];
      final r = recentRecords(h);
      expect(r, hasLength(1));
      expect(r.first.weight, 200);
      expect(r.first.delta, 40);
    });

    test('top set history marks record sessions', () {
      final h = [done(pushA, 1, {'Fly': [160]}), done(pushA, 4, {'Fly': [150]}), done(pushA, 7, {'Fly': [170]})];
      expect(topSetHistory('Fly', h).map((p) => p.wasRecord), [false, false, true]);
    });
  });

  group('last time values', () {
    test('come from the latest finished session with that exercise', () {
      final h = [
        done(pushA, 1, {'Chest press': [40, 55]}),
        done(pushB, 4, {'Chest press': [45, 60, 70]}),
        done(pullA, 5, {'Lat pulldown': [50]}),
      ];
      expect(lastTimeWeights('chest press', h), [45, 60, 70]);
      expect(lastTimeWeights('Squat', h), isEmpty);
    });

    test('a tired day keeps the sets it didn\'t reach', () {
      final h = [
        done(pushA, 1, {'Low pull': [55, 85, 120]}),
        done(pushA, 4, {'Low pull': [60]}), // only one set today
      ];
      expect(lastTimeWeights('Low pull', h), [60, 85, 120]);
    });

    test('a full workout replaces everything; more sets than before are kept', () {
      final h = [
        done(pushA, 1, {'Row': [50, 65, 90]}),
        done(pushA, 4, {'Row': [55, 70, 95, 100]}),
      ];
      expect(lastTimeWeights('Row', h), [55, 70, 95, 100]);
    });

    test('several short days in a row still keep the full list', () {
      final h = [
        done(pushA, 1, {'Row': [50, 65, 90]}),
        done(pushA, 3, {'Row': [52]}),
        done(pushA, 5, {'Row': [54, 66]}),
      ];
      expect(lastTimeWeights('Row', h), [54, 66, 90]);
    });

    test('a skipped exercise changes nothing; lookback is limited', () {
      final h = [
        done(pushA, 1, {'Row': [50, 65, 90, 100]}),
        for (var d = 2; d <= 6; d++) done(pushA, d, {'Row': [50]}),
        done(pushA, 7, {'Fly': [20]}),
      ];
      // Five 1-set days are the lookback, so the old 4-set day no longer fills in.
      expect(lastTimeWeights('Row', h), [50]);
      expect(lastTimeWeights('Row', h.take(3)), [50, 65, 90, 100]);
    });
  });

  group('helpers', () {
    test('next rotation name', () {
      expect(nextRotationName([pushA]), 'B');
      expect(nextRotationName([pushA, pushB]), 'C');
    });

    test('search puts prefix matches first', () {
      final lib = ['Overhead triceps extension', 'Triceps rope pushdown', 'Squat'];
      expect(searchExercises('tri', lib), ['Triceps rope pushdown', 'Overhead triceps extension']);
      expect(searchExercises('', lib), isEmpty);
    });

    test('weight formatting', () {
      expect(formatWeight(60), '60');
      expect(formatWeight(22.5), '22.5');
      expect(formatWeight(12.25), '12.25');
      expect(formatWeight(-25), '\u221225');
      expect(formatWeight(-17.5), '\u221217.5');
      expect(formatWeight(0), '0');
    });

    test('assisted (negative) weights: less help is a PR, bars grow with less help', () {
      expect(isNewRecord(-15, -20), isTrue);
      expect(isNewRecord(-25, -20), isFalse);
      expect(isNewRecord(10, -5), isTrue); // assisted -> weighted
      // Positive-only bars scale from zero exactly as before.
      expect(barFraction(50, [50, 100]), 0.5);
      expect(barFraction(0, [0, 0]), 0.04);
      // With negatives: lowest is the floor, highest is full height.
      expect(barFraction(-30, [-30, -20, -10]), 0.04);
      expect(barFraction(-10, [-30, -20, -10]), 1.0);
      expect(barFraction(-20, [-30, -20, -10]), closeTo(0.52, 0.001));
    });
  });

  group('supersets', () {
    test('next member alternates A, B, A', () {
      expect(supersetNext([0, 0]), 0);
      expect(supersetNext([1, 0]), 1);
      expect(supersetNext([1, 1]), 0);
      expect(supersetNext([2, 1]), 1);
    });

    test('round counts completed pairs', () {
      expect(supersetRound([0, 0]), 1);
      expect(supersetRound([1, 0]), 1);
      expect(supersetRound([2, 2]), 3);
    });
  });

  group('reordering cards', () {
    test('a superset is one card', () {
      expect(exerciseGroups([null, 's', 's', null]), [
        [0],
        [1, 2],
        [3],
      ]);
    });

    test('moving a superset keeps its partners together', () {
      final items = ['Squat', 'Abduction', 'Adduction', 'Calf'];
      final groups = exerciseGroups([null, 's', 's', null]);
      expect(moveGroup(items, groups, 1, 0), ['Abduction', 'Adduction', 'Squat', 'Calf']);
      expect(moveGroup(items, groups, 0, 2), ['Abduction', 'Adduction', 'Calf', 'Squat']);
      expect(moveGroup(items, groups, 2, 1), ['Squat', 'Calf', 'Abduction', 'Adduction']);
    });
  });

  group('record card', () {
    test('gain is measured from the first session', () {
      final h = [done(pushA, 1, {'Fly': [120]}), done(pushA, 4, {'Fly': [200]}), done(pushA, 7, {'Fly': [180]})];
      final d = recordCardData('Fly', h)!;
      expect(d.record, 200);
      expect(d.gain, 80);
      expect(d.recentTops, [120, 200, 180]);
      expect(recordCardData('Squat', h), isNull);
    });
  });
}
