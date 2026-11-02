import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/workout_logic.dart' show RecordEvent;
import '../../state/app_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/exercise_block.dart';
import '../widgets/exercise_input.dart';
import '../widgets/motion.dart';
import '../widgets/store_scope.dart';

/// Full-screen workout logger. Everything autosaves; leaving keeps the session
/// open so it can be resumed from Home.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final session = store.sessionById(widget.sessionId);
    if (session == null || session.isFinished) {
      return const Scaffold(body: Center(child: Text('Workout closed', style: AppText.caption)));
    }
    final rotas = store.rotasOf(session.dayId);
    final done = session.exercises.where((e) => e.sets.isNotEmpty).length;
    final elapsed = DateTime.now().difference(session.startedAt);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _Header(
            title: store.rotaLabel(session.dayId, session.rotaId),
            subtitle: '${formatDuration(elapsed)} · $done of ${session.exercises.length} done',
            rotas: rotas,
            rotaId: session.rotaId,
            onRota: (r) => store.switchRota(session, r),
            onFinish: () => _finish(context, store, session),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                for (final group in groupExercises(session))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: group.length > 1
                        ? SupersetCard(
                            key: ObjectKey(session.exercises[group.first]),
                            store: store,
                            session: session,
                            indexes: group,
                          )
                        : ExerciseCard(
                            key: ObjectKey(session.exercises[group.first]),
                            store: store,
                            session: session,
                            index: group.first,
                          ),
                  ),
                ExerciseInput(
                  search: store.searchLibrary,
                  onSubmit: (name) => store.addExercise(session, name),
                ),
                const SizedBox(height: AppSpace.md),
                const Text(
                  'Tap dashed = same as last time · Tap + to repeat · Long-press a set = drop set · ⋮ = superset',
                  style: AppText.small,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _finish(BuildContext context, AppStore store, Session session) async {
    if (session.setCount == 0) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Nothing logged yet'),
          content: const Text('Discard this workout?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
          ],
        ),
      );
      if (discard == true) {
        store.discardSession(session);
        if (context.mounted) Navigator.of(context).pop();
      }
      return;
    }
    final duration = DateTime.now().difference(session.startedAt);
    final sets = session.setCount;
    final label = store.rotaLabel(session.dayId, session.rotaId);
    final records = store.finishSession(session);
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    final share = await showDialog<RecordEvent>(
      context: context,
      builder: (c) => _SummaryDialog(duration: duration, sets: sets, records: records),
    );
    if (!context.mounted) return;
    if (share != null) {
      openRecordCard(context, share.exercise, subtitle: label, prsToday: records.length, replace: true);
    } else {
      Navigator.of(context).pop();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.rotas,
    required this.rotaId,
    required this.onRota,
    required this.onFinish,
  });

  final String title;
  final String subtitle;
  final List<Rota> rotas;
  final String rotaId;
  final ValueChanged<Rota> onRota;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final index = rotas.indexWhere((r) => r.id == rotaId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpace.sm, AppSpace.screen, AppSpace.md),
      child: Row(children: [
        IconButton(
          tooltip: 'Back (workout stays open)',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.title.copyWith(fontSize: 22), overflow: TextOverflow.ellipsis),
            Text(subtitle, style: AppText.caption),
          ]),
        ),
        if (rotas.length > 1) ...[
          Segmented(
            compact: true,
            options: [for (final r in rotas) r.name],
            selected: index < 0 ? 0 : index,
            onChanged: (i) => onRota(rotas[i]),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
        FilledButton(
          onPressed: onFinish,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            shape: const StadiumBorder(),
          ),
          child: const Text('Finish'),
        ),
      ]),
    );
  }
}

/// Workout summary. Returns the PR to share, or null for "Done".
class _SummaryDialog extends StatelessWidget {
  const _SummaryDialog({required this.duration, required this.sets, required this.records});

  final Duration duration;
  final int sets;
  final List<RecordEvent> records;

  @override
  Widget build(BuildContext context) {
    final best = records.isEmpty ? null : (records.toList()..sort((a, b) => b.delta.compareTo(a.delta))).first;
    return AlertDialog(
      title: Text(records.isEmpty ? 'Workout saved' : 'Workout saved · ${records.length} PR${records.length == 1 ? '' : 's'}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${formatDuration(duration)} · $sets sets', style: AppText.caption),
        const SizedBox(height: AppSpace.md),
        // PR rows arrive one by one; each new number counts up from the old one.
        for (final (i, r) in records.indexed)
          EnterFromBelow(
            delay: Duration(milliseconds: 150 + 120 * i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(r.exercise, style: AppText.body)),
                Text('${formatWeight(r.previous)} → ', style: AppText.caption),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: r.previous, end: r.weight),
                  duration: Motion.of(context, Motion.slow + Duration(milliseconds: 120 * i)),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    formatWeight(v == r.weight ? v : (v * 2).round() / 2),
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentLight),
                  ),
                ),
              ]),
            ),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        if (best != null)
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, best),
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Share PR'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
          ),
      ],
    );
  }
}
