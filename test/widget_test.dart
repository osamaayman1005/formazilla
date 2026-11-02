import 'package:flutter_test/flutter_test.dart';
import 'package:formazilla/app.dart';
import 'package:formazilla/data/storage.dart';
import 'package:formazilla/state/app_store.dart';

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
    final a = s2.exercises.indexWhere((e) => e.name == 'Hip abduction');
    expect(s2.exercises[a + 1].supersetId, s2.exercises[a].supersetId);
    expect(s2.exercises[a].supersetId, isNotNull);

    store.unlinkSuperset(s2, s2.exercises[a].supersetId!, fromTemplate: true);
    expect(s2.exercises.every((e) => e.supersetId == null), isTrue);
    expect(legs.supersets, isEmpty);
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
}
