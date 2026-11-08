import 'package:flutter_test/flutter_test.dart';
import 'package:formazilla/data/storage.dart';
import 'package:formazilla/domain/ai_context.dart';
import 'package:formazilla/domain/shared_plan.dart';
import 'package:formazilla/state/app_store.dart';

void main() {
  final now = DateTime(2026, 11, 8, 18);

  /// Logs a finished workout of the first rotation [daysAgo] days before [now].
  Future<void> log(AppStore store, int daysAgo, List<double> firstLift, {int rotation = 0}) async {
    final r = store.rotationsOf(store.days.first.id)[rotation];
    final s = store.startSession(r);
    for (final w in firstLift) {
      store.addSet(s, 0, w);
    }
    store.finishSession(s);
    s.startedAt = now.subtract(Duration(days: daysAgo, minutes: 50));
    s.finishedAt = now.subtract(Duration(days: daysAgo));
  }

  test('review prompt holds the question, plan, lifts and the import format', () async {
    final store = await AppStore.open(MemoryStorage());
    await log(store, 9, [60, 65]);
    await log(store, 2, [60, 70]);
    final first = store.rotationsOf(store.days.first.id).first.exercises.first;

    final p = store.aiPrompt(AiQuestion.review, extra: '4 days, home gym', now: now);
    expect(p, contains('Review my last 4 weeks'));
    expect(p, contains('Anything to add: 4 days, home gym'));
    expect(p, contains('MY PLAN NOW'));
    expect(p, contains('$first: 65 · 70 (best 70)'));
    expect(p, contains('Average 50 min'));
    expect(p, contains('```formazilla'));
    expect(p, contains('4. If my plan is fine, leave the block out.'));
  });

  test('nothing older than 8 weeks is sent', () async {
    final store = await AppStore.open(MemoryStorage());
    await log(store, 70, [987.5]);
    await log(store, 3, [50]);
    for (final q in AiQuestion.values) {
      final first = store.rotationsOf(store.days.first.id).first.exercises.first;
      expect(store.aiPrompt(q, exercise: first, now: now), isNot(contains('987.5')), reason: q.name);
    }
  });

  test('new plan always asks for the block', () async {
    final store = await AppStore.open(MemoryStorage());
    final p = store.aiPrompt(AiQuestion.newPlan, now: now);
    expect(p, contains('Build me a new split.'));
    expect(p, contains('3. End your answer with this block'));
    expect(p, isNot(contains('leave the block out')));
    expect(p, contains('No finished workouts yet.'));
  });

  test('stuck prompt only has that lift, every set', () async {
    final store = await AppStore.open(MemoryStorage());
    final r = store.rotationsOf(store.days.first.id).first;
    final s = store.startSession(r);
    store.addSet(s, 0, 40);
    store.addSet(s, 0, 30, dropSet: true);
    store.addSet(s, 1, 22.5);
    store.finishSession(s);
    s.finishedAt = now.subtract(const Duration(days: 1));

    final lift = r.exercises.first;
    final p = store.aiPrompt(AiQuestion.stuck, exercise: lift, now: now);
    expect(p, contains('My $lift has stalled'));
    expect(p, contains('40 · 30 (drop)'));
    expect(p, isNot(contains('22.5')));
    expect(p, isNot(contains('MY PLAN NOW')));
  });

  test('today prompt compares against last time', () async {
    final store = await AppStore.open(MemoryStorage());
    await log(store, 5, [55, 60]);
    await log(store, 0, [60, 65]);
    final lift = store.rotationsOf(store.days.first.id).first.exercises.first;
    final p = store.aiPrompt(AiQuestion.today, now: now);
    expect(p, contains('$lift: 60 · 65 → 55 · 60'));
  });

  test('own question is used and flattened to one line', () async {
    final store = await AppStore.open(MemoryStorage());
    final p = store.aiPrompt(AiQuestion.own, own: 'Legs twice\na week?', now: now);
    expect(p, contains('Legs twice a week?'));
  });

  test('prompt is capped in length', () async {
    final store = await AppStore.open(MemoryStorage());
    final p = store.aiPrompt(AiQuestion.review, extra: 'x' * 5000, now: now);
    expect(p.length, lessThan(aiMaxChars + 1000));
    expect(p, isNot(contains('x' * 301)));
  });

  test('the template block in the prompt is itself a readable plan', () async {
    final store = await AppStore.open(MemoryStorage());
    final plan = readPlan(store.aiPrompt(AiQuestion.newPlan, now: now));
    expect(plan, isNotNull);
    expect(plan!.days.single.rotations.single.weights['Exercise 1'], [40, 45, 50]);
  });
}
