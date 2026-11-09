/// "Ask your AI coach": builds the text the user shares to their own AI app
/// (ChatGPT, Claude, Gemini…). Pure Dart; nothing here talks to a network.
///
/// Only training facts leave the app: exercise and day names, weights, set
/// counts, minutes and short dates, at most [aiMaxWeeks] weeks back. No ids,
/// no notes.
library;

import '../core/format.dart';
import '../data/models.dart';
import 'shared_plan.dart';
import 'workout_logic.dart';

enum AiQuestion { review, newPlan, stuck, today, own }

/// Oldest data ever sent.
const aiMaxWeeks = 8;

/// Window for the summary and the lift list.
const aiSummaryWeeks = 4;

/// Soft cap on the prompt length; the lift list shrinks to fit.
const aiMaxChars = 6000;

/// The sheet's label for each question.
String aiQuestionLabel(AiQuestion q) => switch (q) {
      AiQuestion.review => 'Review my last 4 weeks',
      AiQuestion.newPlan => 'Build me a new plan',
      AiQuestion.stuck => 'I’m stuck on…',
      AiQuestion.today => 'Feedback on today’s workout',
      AiQuestion.own => 'My own question',
    };

/// The workout that finished today (newest), if any.
Session? finishedToday(Iterable<Session> sessions, DateTime now) {
  for (final s in finishedNewestFirst(sessions)) {
    final f = s.finishedAt!;
    if (f.year == now.year && f.month == now.month && f.day == now.day) return s;
    return null;
  }
  return null;
}

/// Builds the prompt.
///
/// [sessions] is every session (one-time ones included: they count for PRs
/// and the workout count, not for the lift list). Only the last [aiMaxWeeks]
/// weeks are read, so bests and PRs are "in the last 8 weeks". [plan] is the active split.
/// [labelOf] names a workout ("Push A"). [cardio] says whether a name is cardio.
String buildAiPrompt({
  required AiQuestion question,
  required Iterable<Session> sessions,
  required SharedPlan plan,
  required String Function(Session) labelOf,
  required bool Function(String) cardio,
  String? extra,
  String? exercise,
  String? own,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final maxCutoff = at.subtract(const Duration(days: 7 * aiMaxWeeks));
  final summaryCutoff = at.subtract(const Duration(days: 7 * aiSummaryWeeks));
  final finished = finishedNewestFirst(sessions).where((s) => s.finishedAt!.isAfter(maxCutoff)).toList();
  final recent = finished.where((s) => s.finishedAt!.isAfter(summaryCutoff)).toList();
  final planRecent = recent.where((s) => !s.oneTime).toList();

  String build(int liftLimit) {
    final b = StringBuffer()
      ..writeln('I use Formazilla, an offline gym logbook. Act as my strength coach.')
      ..writeln()
      ..writeln('MY QUESTION')
      ..writeln(_questionLine(question, exercise: exercise, own: own));
    final add = extra?.trim() ?? '';
    if (add.isNotEmpty) b.writeln('Anything to add: ${_oneLine(add, 300)}');

    b
      ..writeln()
      ..writeln('HOW I LOG')
      ..writeln('- Weights are the numbers on the machine or dumbbell, exactly as I log them.')
      ..writeln('  No units, no per-side math. Treat them as my numbers.');
    final order = plan.days.map((d) => d.name).join(' → ');
    if (order.isNotEmpty) b.writeln('- My split repeats in order: $order.');
    final alternating = [
      for (final d in plan.days)
        if (d.rotations.length > 1) '${d.name} alternates ${d.rotations.map((r) => r.name).join('/')}',
    ];
    if (alternating.isNotEmpty) b.writeln('- ${alternating.join('. ')}.');

    switch (question) {
      case AiQuestion.stuck:
        _writeStuck(b, exercise ?? '', finished.where((s) => !s.oneTime), finished, labelOf);
      case AiQuestion.today:
        _writeToday(b, finishedToday(sessions, at), finished, labelOf);
        _writePlan(b, plan);
      case AiQuestion.review:
      case AiQuestion.newPlan:
      case AiQuestion.own:
        // PRs are judged against all history; only PRs set inside the window are written.
        _writeSummary(b, recent, sessions, labelOf, summaryCutoff);
        _writePlan(b, plan);
        _writeLifts(b, planRecent, finished, cardio, liftLimit);
        if (question != AiQuestion.newPlan) _writeCardio(b, planRecent);
    }

    _writeHowToAnswer(b, alwaysPlan: question == AiQuestion.newPlan);
    return b.toString().trimRight();
  }

  var limit = 25;
  var text = build(limit);
  while (text.length > aiMaxChars && limit > 5) {
    limit -= 5;
    text = build(limit);
  }
  return text;
}

String _questionLine(AiQuestion q, {String? exercise, String? own}) => switch (q) {
      AiQuestion.review => 'Review my last 4 weeks. What’s going well, and what should I change?',
      AiQuestion.newPlan => 'Build me a new split.',
      AiQuestion.stuck => 'My ${exercise ?? 'lift'} has stalled. Why, and what should I try?',
      AiQuestion.today => 'Give me feedback on today’s workout.',
      AiQuestion.own => _oneLine(own?.trim().isNotEmpty == true ? own! : 'Look at my training and tell me what to improve.', 500),
    };

String _oneLine(String s, int max) {
  final flat = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= max ? flat : '${flat.substring(0, max)}…';
}

int _minutes(Session s) => s.finishedAt!.difference(s.startedAt).inMinutes;

void _writeSummary(
  StringBuffer b,
  List<Session> recent,
  Iterable<Session> all,
  String Function(Session) labelOf,
  DateTime cutoff,
) {
  b
    ..writeln()
    ..writeln('LAST 4 WEEKS');
  if (recent.isEmpty) {
    b.writeln('- No finished workouts yet.');
    return;
  }
  final counts = <String, int>{};
  for (final s in recent.reversed) {
    final l = labelOf(s);
    counts[l] = (counts[l] ?? 0) + 1;
  }
  final avg = (recent.fold<int>(0, (a, s) => a + _minutes(s)) / recent.length).round();
  final n = recent.length;
  b.writeln('- $n workout${n == 1 ? '' : 's'}: ${counts.entries.map((e) => '${e.key} ${e.value}').join(', ')}. '
      'Average $avg min.');
  final prs = recentRecords(all, limit: 50).where((r) => r.date.isAfter(cutoff)).toList();
  if (prs.isNotEmpty) {
    b.writeln('- New PRs: ${prs.take(10).map((r) => '${r.exercise} ${formatWeight(r.weight)}').join(', ')}.');
  }
}

void _writePlan(StringBuffer b, SharedPlan plan) {
  b
    ..writeln()
    ..writeln('MY PLAN NOW');
  for (final d in plan.days) {
    for (final r in d.rotations) {
      final names = [for (final e in r.exercises) r.cardio.contains(e) ? '$e (cardio)' : e];
      b.writeln('- ${rotationTitle(d.name, r.name)}: ${names.isEmpty ? '(empty)' : names.join(', ')}');
      for (final p in r.supersets) {
        b.writeln('  superset: ${p.join(' + ')}');
      }
    }
  }
}

double _top(Iterable<SetLog> sets) => sets.map((x) => x.weight).reduce((a, b) => a > b ? a : b);

void _writeLifts(
  StringBuffer b,
  List<Session> planRecent,
  Iterable<Session> all,
  bool Function(String) cardio,
  int limit,
) {
  // Top set per session, newest first, per exercise.
  final tops = <String, List<double>>{};
  final names = <String, String>{};
  for (final s in planRecent) {
    for (final e in s.exercises) {
      if (e.cardio || cardio(e.name) || e.sets.isEmpty) continue;
      final key = exerciseKey(e.name);
      names.putIfAbsent(key, () => e.name);
      (tops[key] ??= []).add(_top(e.sets));
    }
  }
  if (tops.isEmpty) return;
  final keys = tops.keys.toList()..sort((a, b) => tops[b]!.length.compareTo(tops[a]!.length));
  b
    ..writeln()
    ..writeln('MY LIFTS (top set of each of the last 4 sessions, oldest → newest; best in the last $aiMaxWeeks weeks)');
  for (final k in keys.take(limit)) {
    final last4 = tops[k]!.take(4).toList().reversed;
    final best = personalRecord(names[k]!, all);
    b.writeln('- ${names[k]}: ${formatWeights(last4)}${best == null ? '' : ' (best ${formatWeight(best)})'}');
  }
  if (keys.length > limit) b.writeln('- …and ${keys.length - limit} more, left out to keep this short.');
}

void _writeCardio(StringBuffer b, List<Session> planRecent) {
  final times = <String, List<double>>{};
  for (final s in planRecent) {
    for (final e in s.exercises) {
      if (e.cardio && e.minutes != null) (times[e.name] ??= []).add(e.minutes!);
    }
  }
  if (times.isEmpty) return;
  final parts = times.entries.map((e) {
    final avg = (e.value.reduce((a, b) => a + b) / e.value.length).round();
    return '${e.key}, ${e.value.length} time${e.value.length == 1 ? '' : 's'}, about $avg min';
  });
  b
    ..writeln()
    ..writeln('CARDIO: ${parts.join(' · ')}');
}

void _writeStuck(
  StringBuffer b,
  String exercise,
  Iterable<Session> planWindow,
  Iterable<Session> all,
  String Function(Session) labelOf,
) {
  final key = exerciseKey(exercise);
  b
    ..writeln()
    ..writeln('$exercise: MY LAST SESSIONS (oldest → newest, every set)');
  final rows = <String>[];
  for (final s in planWindow) {
    final sets = [
      for (final e in s.exercises)
        if (exerciseKey(e.name) == key) ...e.sets,
    ];
    if (sets.isEmpty) continue;
    final text = sets.map((x) => x.dropSet ? '${formatWeight(x.weight)} (drop)' : formatWeight(x.weight)).join(' · ');
    rows.add('- ${formatShortDate(s.finishedAt!)} (${labelOf(s)}): $text');
    if (rows.length == 8) break;
  }
  if (rows.isEmpty) {
    b.writeln('- Not logged in the last $aiMaxWeeks weeks.');
  } else {
    rows.reversed.forEach(b.writeln);
  }
  final best = personalRecord(exercise, all);
  if (best != null) b.writeln('- Best in the last $aiMaxWeeks weeks: ${formatWeight(best)}');
}

void _writeToday(StringBuffer b, Session? today, Iterable<Session> all, String Function(Session) labelOf) {
  b.writeln();
  if (today == null) {
    b
      ..writeln('TODAY')
      ..writeln('- No workout finished today.');
    return;
  }
  b.writeln('TODAY: ${labelOf(today)}, ${_minutes(today)} min (today → last time)');
  final plan = planWorkouts(all);
  for (final e in today.exercises) {
    if (e.cardio) {
      if (e.minutes != null) b.writeln('- ${e.name}: ${formatWeight(e.minutes!)} min');
      continue;
    }
    if (e.sets.isEmpty) {
      b.writeln('- ${e.name}: skipped');
      continue;
    }
    final last = lastTimeWeights(e.name, plan, excludeSessionId: today.id);
    final now = e.sets.map((x) => x.dropSet ? '${formatWeight(x.weight)} (drop)' : formatWeight(x.weight)).join(' · ');
    b.writeln('- ${e.name}: $now → ${last.isEmpty ? 'first time' : formatWeights(last)}');
  }
}

void _writeHowToAnswer(StringBuffer b, {required bool alwaysPlan}) {
  b
    ..writeln()
    ..writeln('HOW TO ANSWER')
    ..writeln('1. Keep it short: 5–8 bullet points in plain words.')
    ..writeln('2. Don’t suggest weight jumps bigger than about 10% at once.')
    ..writeln(alwaysPlan
        ? '3. End your answer with this block, filled in, so my app can import it:'
        : '3. Only if you suggest a new or changed plan, end your answer with this block,\n'
            '   filled in, so my app can import it:')
    ..writeln()
    ..writeln('```formazilla')
    ..writeln('{"v":1,"n":"PLAN NAME","split":true,')
    ..writeln(' "d":[{"n":"DAY NAME","r":[{"n":"A",')
    ..writeln('   "e":["Exercise 1","Exercise 2"],')
    ..writeln('   "s":[["Exercise 1","Exercise 2"]],')
    ..writeln('   "c":["Treadmill"],')
    ..writeln('   "w":{"Exercise 1":[40,45,50]}}]}]}')
    ..writeln('```')
    ..writeln('   - "split": true for a whole split, false for one workout (one day, one rotation).')
    ..writeln('   - "e": exercises in order. "s": supersets (optional). "c": cardio (optional).')
    ..writeln('     "w": suggested weights per set (optional).')
    ..writeln('   - Use my exercise names when it’s the same exercise.');
  if (!alwaysPlan) b.writeln('4. If my plan is fine, leave the block out.');
}
