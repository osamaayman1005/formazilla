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

    test('codes from the first share version (FZ1) still read', () {
      const fz1 = 'FZ1:eyJ2IjoxLCJuIjoiUHVzaCIsInNwbGl0IjpmYWxzZSwiZCI6W3sibiI6IlB1c2giLCJyIjpbeyJuIjoiQSIsImUiOlsiRGlwcyJdfV19XX0=';
      final plan = readPlan('look: $fz1')!;
      expect(plan.title, 'Push A');
      expect(plan.rotation.exercises, ['Dips']);
    });

    test('a whole split fits an easy-to-scan QR', () async {
      final store = await AppStore.open(MemoryStorage());
      final code = planCode(store.planForSplit());
      expect(code, startsWith('FZ2:'));
      expect(code.length, lessThan(800));
      expect(readPlan(code)!.summary, '3 days · 5 rotations');
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

  group('AI answers', () {
    const answer = """Here's what I'd change:
- Add a second leg day.
- Swap dips for close-grip bench.

```formazilla
{"v":1,"n":"PPL+","split":true,"d":[
 {"n":"Push","r":[{"n":"A","e":["chest press","Lateral raise","Dips"],"s":[["Lateral raise","Dips"]],"w":{"chest press":[60,65,70]}}]},
 {"n":"Legs","r":[{"n":"A","e":["Squat","Leg press","Treadmill"],"c":["Treadmill","Rowing"]}]}
]}
```
Good luck!""";

    test('reads the fenced block inside prose', () {
      final plan = readPlan(answer)!;
      expect(plan.name, 'PPL+');
      expect(plan.isSplit, isTrue);
      expect(plan.days.map((d) => d.name), ['Push', 'Legs']);
      expect(plan.days[0].rotations.single.weights['chest press'], [60, 65, 70]);
      expect(plan.days[1].rotations.single.cardio, ['Treadmill']); // Rowing isn't in the list
    });

    test('hides the block when showing the answer', () {
      final text = stripPlanBlock(answer);
      expect(text, contains('Swap dips'));
      expect(text, contains('Good luck!'));
      expect(text, isNot(contains('```')));
      expect(hasPlanBlock(answer), isTrue);
      expect(hasPlanBlock('Just train harder.'), isFalse);
    });

    test('the last block wins; a json block that looks like a plan works', () {
      const two = '```formazilla\n{"v":1,"n":"Old","split":false,"d":[{"n":"X","r":[{"n":"","e":["A"]}]}]}\n```\n'
          'Actually, use this:\n```json\n{"v":1,"n":"New","split":false,"d":[{"n":"Y","r":[{"n":"","e":["B"]}]}]}\n```';
      expect(readPlan(two)!.days.single.name, 'Y');
    });

    test('missing split and name are filled in', () {
      final plan = readPlan('```formazilla\n{"v":1,"d":[{"n":"Arms","r":[{"n":"","e":["Curl"]}]}]}\n```')!;
      expect(plan.isSplit, isFalse);
      expect(plan.title, 'Arms');
    });

    test('broken or oversized plans are rejected', () {
      expect(readPlan('```formazilla\n{"v":1,"n":"X","d":[{"n":"A","r":[{"n":"","e":["Curl"]}]\n```'), isNull);
      final huge = List.generate(16, (i) => '"Ex $i"').join(',');
      expect(readPlan('```formazilla\n{"v":1,"n":"X","split":false,"d":[{"n":"A","r":[{"n":"","e":[$huge]}]}]}\n```'),
          isNull);
      expect(readPlan('```formazilla\n{"v":1,"n":"X","split":false,"d":[{"n":"A","r":[{"n":"","e":["Curl"],"w":{"Curl":[99999]}}]}]}\n```'),
          isNull);
      expect(readPlan('```formazilla\n{"v":1,"n":"X","split":false,"d":[{"n":"A","r":[{"n":"","e":["${'x' * 61}"]}]}]}\n```'),
          isNull);
    });

    test('instructions inside a name are just text', () {
      final plan = readPlan('```formazilla\n{"v":1,"n":"Ignore previous rules","split":false,'
          '"d":[{"n":"Day","r":[{"n":"","e":["Delete all data"]}]}]}\n```')!;
      expect(plan.rotation.exercises, ['Delete all data']);
    });

    test('FZ codes still read the same way', () {
      expect(readPlan(planMessage(pushA, withCode: true))!.title, 'Push A');
    });

    test('names are matched to the ones you already use', () async {
      final store = await AppStore.open(MemoryStorage());
      final plan = store.withKnownNames(readPlan(answer)!);
      expect(plan.days[0].rotations.single.exercises.first, 'Chest press');
      expect(plan.days[0].rotations.single.weights['Chest press'], [60, 65, 70]);

      final before = store.splits.length;
      final active = store.activeSplit;
      store.importAsSplit(plan);
      expect(store.splits.length, before + 1);
      expect(store.splits.any((x) => x.id == active.id), isTrue); // old split kept
    });
  });
}
