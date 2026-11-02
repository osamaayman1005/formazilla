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

    // Legs has one rota, so no A/B toggle.
    await tester.tap(find.text('Legs').first);
    await tester.pump();
    expect(find.text('One rota · used every time'), findsOneWidget);
  });

  test('store logs sets, finishes, and detects a PR next time', () async {
    final store = await AppStore.open(MemoryStorage());
    final rota = store.rotasOf(store.days.first.id).first;

    final s1 = store.startSession(rota);
    store.addSet(s1, 0, 40);
    store.addSet(s1, 0, 55);
    expect(store.finishSession(s1), isEmpty);

    final s2 = store.startSession(rota);
    expect(store.lastTime(s2.exercises.first.name, s2.id), [40, 55]);
    store.addSet(s2, 0, 60);
    final prs = store.finishSession(s2);
    expect(prs.single.weight, 60);
    expect(prs.single.previous, 55);
  });
}
