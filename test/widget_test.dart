import 'package:flutter_test/flutter_test.dart';
import 'package:formazilla/app.dart';
import 'package:formazilla/data/models.dart';
import 'package:formazilla/data/storage.dart';
import 'package:formazilla/state/app_store.dart';
import 'package:formazilla/ui/widgets/exercise_block.dart' show groupExercises;

void main() {
  testWidgets('first launch shows Home with seeded days and starts a workout', (tester) async {
    final store = await AppStore.open(MemoryStorage());
    await tester.pumpWidget(FormazillaApp(store: store));

    expect(find.text('Ready to train?'), findsOneWidget);
    expect(find.text('Push'), findsWidgets);
    expect(find.text('Legs'), findsWidgets);

    // Legs has one rotation, so no A/B toggle.
    await tester.tap(find.text('Legs').first);
    await tester.pump();
    expect(find.text('One rotation · used every time'), findsOneWidget);
  });

  test('store logs sets, finishes, and detects a PR next time', () async {
    final store = await AppStore.open(MemoryStorage());
    final rotation = store.rotationsOf(store.days.first.id).first;

    final s1 = store.startSession(rotation);
    store.addSet(s1, 0, 40);
    store.addSet(s1, 0, 55);
    expect(store.finishSession(s1), isEmpty);

    final s2 = store.startSession(rotation);
    expect(store.lastTime(s2.exercises.first.name, s2.id), [40, 55]);
    store.addSet(s2, 0, 60);
    final prs = store.finishSession(s2);
    expect(prs.single.weight, 60);
    expect(prs.single.previous, 55);
  });

  test('superset links adjacent, survives into the next session via the template', () async {
    final store = await AppStore.open(MemoryStorage());
    final legs = store.rotationsOf(store.days.last.id).single;
    final s1 = store.startSession(legs);
    final abd = s1.exercises.indexWhere((e) => e.name == 'Hip abduction');
    final add = s1.exercises.indexWhere((e) => e.name == 'Hip adduction');
    store.linkSuperset(s1, abd, add, keepInTemplate: true);
    expect(s1.exercises[abd + 1].name, 'Hip adduction');
    expect(s1.exercises[abd].supersetId, isNotNull);
    expect(s1.exercises[abd].supersetId, s1.exercises[abd + 1].supersetId);
    store.addSet(s1, abd, 20);
    store.finishSession(s1);

    final s2 = store.startSession(legs);
    var a = s2.exercises.indexWhere((e) => e.name == 'Hip abduction');
    expect(s2.exercises[a + 1].supersetId, s2.exercises[a].supersetId);
    expect(s2.exercises[a].supersetId, isNotNull);

    // Dragging the superset card to the top moves both partners, still linked.
    final card = groupExercises(s2).indexWhere((g) => g.length == 2);
    store.moveExerciseGroup(s2, card, 0);
    expect(s2.exercises.take(2).map((e) => e.name), ['Hip abduction', 'Hip adduction']);
    expect(s2.exercises[0].supersetId, s2.exercises[1].supersetId);
    a = 0;

    store.unlinkSuperset(s2, s2.exercises[a].supersetId!, fromTemplate: true);
    expect(s2.exercises.every((e) => e.supersetId == null), isTrue);
    expect(legs.supersets, isEmpty);
  });

  test('renaming an exercise is permanent: sets, templates, history and PRs follow', () async {
    final store = await AppStore.open(MemoryStorage());
    final rotation = store.rotationsOf(store.days.first.id).first;
    final s1 = store.startSession(rotation);
    store.addSet(s1, 0, 60);
    store.finishSession(s1);

    final s2 = store.startSession(rotation);
    store.addSet(s2, 0, 65);
    store.renameExercise(s2, 0, 'Machine chest press');

    expect(s2.exercises.first.name, 'Machine chest press');
    expect(s2.exercises.first.sets.single.weight, 65);
    expect(rotation.exercises.first, 'Machine chest press');
    expect(store.record('Machine chest press'), 60); // old PR carried over
    expect(store.library, contains('Machine chest press'));
    expect(store.library, isNot(contains('Chest press')));
  });

  test('cardio logs time only, survives finish, and moves like any card', () async {
    final store = await AppStore.open(MemoryStorage());
    final rotation = store.rotationsOf(store.days.first.id).first;
    final s = store.startSession(rotation);
    store.addExercise(s, 'Hill sprints', cardio: true);
    final i = s.exercises.length - 1;
    expect(s.exercises[i].cardio, isTrue);
    expect(store.isCardio('hill sprints'), isTrue); // remembered for next time
    expect(rotation.exercises, isNot(contains('Hill sprints'))); // this workout only
    expect(s.hasLogs, isFalse);

    store.setCardioMinutes(s, i, 20);
    expect(s.hasLogs, isTrue);
    store.moveExerciseGroup(s, groupExercises(s).length - 1, 0); // drag to the top
    expect(s.exercises.first.name, 'Hill sprints');

    expect(store.finishSession(s), isEmpty); // no PRs from cardio
    expect(s.exercises.single.minutes, 20); // unlogged weights dropped, cardio kept
    expect(s.cardioMinutes, 20);
  });

  test('cardio in a template starts as cardio; old saves get the preset list', () async {
    final storage = MemoryStorage()
      ..saved = '{"days":[{"id":"d1","name":"Push","position":0}],'
          '"rotations":[{"id":"r1","dayId":"d1","name":"","position":0,"exercises":["Treadmill","Dips"]}],'
          '"sessions":[],"library":[]}';
    final store = await AppStore.open(storage);
    expect(store.isCardio('Treadmill'), isTrue);
    final s = store.startSession(store.rotationsOf(store.days.single.id).single);
    expect(s.exercises.map((e) => e.cardio), [true, false]);
  });

  test('a one-time workout affects nothing but History', () async {
    final store = await AppStore.open(MemoryStorage());
    final push = store.rotationsOf(store.days.first.id).first;
    final s1 = store.startSession(push);
    store.addSet(s1, 0, 60);
    store.finishSession(s1);
    expect(store.suggestedDay.name, 'Pull');

    final extra = store.startOneTime();
    expect(extra.exercises, isEmpty);
    expect(store.sessionTitle(extra), 'One-time workout');
    store.renameOneTime(extra, 'Hotel gym');
    store.addExercise(extra, 'Chest press');
    expect(store.lastTimeIn(extra, 'Chest press'), isEmpty); // no suggestions inside
    store.addSet(extra, 0, 100);
    expect(store.finishSession(extra), isEmpty); // no PR

    expect(store.suggestedDay.name, 'Pull'); // plan unchanged
    expect(store.record('Chest press'), 60);
    final s2 = store.startSession(push);
    expect(store.lastTimeIn(s2, 'Chest press'), [60]); // last plan workout, not the extra
    expect(store.history.map(store.sessionTitle), ['Hotel gym', 'Push A']);
  });

  test('backups saved before the rota → rotation rename still load', () {
    const v1 = '{"schemaVersion":1,"days":[{"id":"d","name":"Push","position":0}],'
        '"rotas":[{"id":"r","dayId":"d","name":"A","position":0,"exercises":["Fly"]}],'
        '"sessions":[{"id":"s","dayId":"d","rotaId":"r","startedAt":"2026-11-01T10:00:00.000",'
        '"finishedAt":"2026-11-01T11:00:00.000","exercises":[{"name":"Fly","sets":[{"w":60}]}]}],'
        '"library":["Fly"]}';
    final data = AppData.decode(v1);
    expect(data.rotations.single.name, 'A');
    expect(data.sessions.single.rotationId, 'r');
  });

  test('old saves without splits are put into one Push Pull Legs split', () async {
    final storage = MemoryStorage()
      ..saved = '{"days":[{"id":"d1","name":"Push","position":0},{"id":"d2","name":"Pull","position":1}],'
          '"rotations":[{"id":"r1","dayId":"d1","name":"","position":0,"exercises":[]},'
          '{"id":"r2","dayId":"d2","name":"","position":0,"exercises":[]}],"sessions":[],"library":[]}';
    final store = await AppStore.open(storage);
    expect(store.splits.single.name, 'Push Pull Legs');
    expect(store.days.map((d) => d.name), ['Push', 'Pull']);
  });

  test('switching splits keeps each split\'s own days and suggestion', () async {
    final store = await AppStore.open(MemoryStorage());
    final ppl = store.activeSplit;
    final push = store.days.first;
    store.finishSession(_logOne(store, store.rotationsOf(push.id).first));
    expect(store.suggestedDay.name, 'Pull');

    final ul = store.createSplit('Upper / Lower');
    expect(store.activeSplit.id, ul.id);
    expect(store.days.map((d) => d.name), ['Upper', 'Lower']);
    expect(store.suggestedDay.name, 'Upper'); // PPL history doesn't count here

    store.setActiveSplit(ppl);
    expect(store.suggestedDay.name, 'Pull');
  });

  test('days can be added, reordered and removed (but never the last one)', () async {
    final store = await AppStore.open(MemoryStorage());
    store.createSplit('Custom', name: 'Mine');
    expect(store.days.single.name, 'Day 1');
    store.addDay('Arms');
    store.reorderDays(1, 0);
    expect(store.days.map((d) => d.name), ['Arms', 'Day 1']);
    expect(store.archiveDay(store.days.last), isTrue);
    expect(store.archiveDay(store.days.single), isFalse);
  });
}

Session _logOne(AppStore store, Rotation rotation) {
  final s = store.startSession(rotation);
  store.addSet(s, 0, 10);
  return s;
}
