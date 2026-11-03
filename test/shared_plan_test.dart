import 'package:flutter_test/flutter_test.dart';
import 'package:formazilla/data/storage.dart';
import 'package:formazilla/domain/shared_plan.dart';
import 'package:formazilla/state/app_store.dart';

void main() {
  const pushA = SharedPlan(name: 'Push', isSplit: false, days: [
    SharedDay(name: 'Push', rotations: [
      SharedRotation(
        name: 'A',
        exercises: ['Chest press', 'Lateral raise', 'Dips'],
        supersets: [
          ['Lateral raise', 'Dips'],
        ],
        weights: {
          'Chest press': [60, 62.5],
        },
      ),
    ]),
  ]);

  group('plan code', () {
    test('survives a round trip inside a chat message', () {
      final message = planMessage(pushA, withCode: true);
      final forwarded = 'Ahmed: try this 💪\n$message\nsent from WhatsApp';
      final plan = readPlan(forwarded)!;
      expect(plan.title, 'Push A');
      expect(plan.isSplit, isFalse);
      expect(plan.rotation.exercises, ['Chest press', 'Lateral raise', 'Dips']);
      expect(plan.rotation.supersets.single, ['Lateral raise', 'Dips']);
      expect(plan.rotation.weights['Chest press'], [60, 62.5]);
    });

    test('readable text lists exercises and weights, without a code', () {
      final text = planMessage(pushA);
      expect(text, contains('Push A'));
      expect(text, contains('1. Chest press — 60 · 62.5'));
      expect(text, contains('3. Dips'));
      expect(readPlan(text), isNull);
    });

    test('nothing or a damaged code reads as no plan', () {
      expect(readPlan(null), isNull);
      expect(readPlan('just a message'), isNull);
      expect(readPlan('FZ1:bm90LWpzb24'), isNull);
      final code = planCode(pushA);
      expect(readPlan(code.substring(0, code.length ~/ 2)), isNull);
    });
  });

  group('store sharing', () {
    test('a whole split imports as an identical new split', () async {
      final store = await AppStore.open(MemoryStorage());
      final shared = readPlan(planMessage(store.planForSplit(), withCode: true))!;
      expect(shared.summary, '3 days · 5 rotations');

      final before = store.activeSplit;
      final split = store.importAsSplit(shared);
      expect(store.activeSplit.id, split.id);
      expect(store.days.map((d) => d.name), ['Push', 'Pull', 'Legs']);
      final push = store.days.first;
      expect(store.rotationsOf(push.id).map((r) => r.name), ['A', 'B']);
      expect(store.rotationsOf(push.id).first.exercises.first, 'Chest press');
      expect(store.splits.map((s) => s.id), contains(before.id)); // kept

      store.importAsSplit(shared, replace: true);
      expect(store.splits.map((s) => s.id), isNot(contains(split.id))); // archived
    });

    test('a single rotation joins a day as its next rotation', () async {
      final store = await AppStore.open(MemoryStorage());
      final legs = store.days.last;
      final shared = readPlan(planMessage(store.planForRotation(store.rotationsOf(store.days.first.id).first),
          withCode: true))!;
      final added = store.importIntoDay(shared, legs);
      expect(store.rotationsOf(legs.id).map((r) => r.name), ['A', 'B']);
      expect(added.exercises.first, 'Chest press');
    });

    test('cardio stays cardio when shared', () async {
      final store = await AppStore.open(MemoryStorage());
      final rotation = store.rotationsOf(store.days.first.id).first;
      store.addRotationExercise(rotation, 'Hill sprints', cardio: true);
      final message = planMessage(store.planForRotation(rotation), withCode: true);
      expect(message, contains('Hill sprints (cardio)'));

      final friend = await AppStore.open(MemoryStorage());
      expect(friend.isCardio('Hill sprints'), isFalse);
      friend.importIntoDay(readPlan(message)!, friend.days.first);
      expect(friend.isCardio('Hill sprints'), isTrue);
    });

    test('weights are only shared when asked', () async {
      final store = await AppStore.open(MemoryStorage());
      final rotation = store.rotationsOf(store.days.first.id).first;
      final s = store.startSession(rotation);
      store.addSet(s, 0, 70);
      store.finishSession(s);
      expect(store.planForRotation(rotation).rotation.weights, isEmpty);
      expect(store.planForRotation(rotation, weights: true).rotation.weights['Chest press'], [70]);
    });
  });
}
