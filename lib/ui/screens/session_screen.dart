import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/workout_logic.dart' show RecordEvent, isNewRecord;
import '../../state/app_store.dart';
import '../widgets/common.dart';
import '../widgets/exercise_input.dart';
import '../widgets/keypad_sheet.dart';
import '../widgets/set_chip.dart';
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
                for (var i = 0; i < session.exercises.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: _ExerciseCard(
                      key: ObjectKey(session.exercises[i]),
                      store: store,
                      session: session,
                      index: i,
                    ),
                  ),
                ExerciseInput(
                  search: store.searchLibrary,
                  onSubmit: (name) => store.addExercise(session, name),
                ),
                const SizedBox(height: AppSpace.md),
                const Text(
                  'Tap dashed = same as last time · Tap + to repeat · Long-press a set = drop set',
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
    final records = store.finishSession(session);
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => _SummaryDialog(duration: duration, sets: sets, records: records),
    );
    if (context.mounted) Navigator.of(context).pop();
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

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({super.key, required this.store, required this.session, required this.index});

  final AppStore store;
  final Session session;
  final int index;

  SessionExercise get _ex => session.exercises[index];

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final best = store.recordBefore(ex.name, session.id);
    final last = store.lastTime(ex.name, session.id);
    final top = ex.sets.isEmpty ? null : ex.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    final hitRecord = top != null && isNewRecord(top, best);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(ex.name, style: AppText.cardTitle)),
          if (hitRecord)
            Pill('New PR ${formatWeight(top!)}', fill: AppColors.accent, color: AppColors.onAccent)
          else if (best != null)
            Text('PR ${formatWeight(best)}', style: AppText.small.copyWith(fontWeight: FontWeight.w500)),
          _menu(context),
        ]),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(
            last.isEmpty ? 'First time — tap + to log' : 'Last   ${formatWeights(last)}',
            style: AppText.caption,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < ex.sets.length; i++)
              SetChip(
                kind: isNewRecord(ex.sets[i].weight, best) ? ChipKind.record : ChipKind.done,
                weight: ex.sets[i].weight,
                dropSet: ex.sets[i].dropSet,
                index: i,
                onTap: () => _edit(context, i),
                onLongPress: () {
                  HapticFeedback.selectionClick();
                  store.toggleDropSet(session, index, i);
                },
              ),
            for (var j = ex.sets.length; j < last.length; j++)
              SetChip(
                kind: ChipKind.ghost,
                weight: last[j],
                onTap: () {
                  HapticFeedback.lightImpact();
                  store.addSet(session, index, last[j]);
                },
              ),
            SetChip(
              kind: ChipKind.add,
              onTap: () => _quickAdd(context, last),
              onLongPress: () => _addWithKeypad(context),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
      color: AppColors.chip,
      onSelected: (v) {
        switch (v) {
          case 'up':
            store.moveExercise(session, index, index - 1);
          case 'down':
            store.moveExercise(session, index, index + 1);
          case 'remove':
            final removed = _ex;
            store.removeExercise(session, index);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${removed.name} removed'),
              action: SnackBarAction(label: 'Undo', onPressed: () => store.insertExercise(session, index, removed)),
            ));
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'up', child: Text('Move up')),
        PopupMenuItem(value: 'down', child: Text('Move down')),
        PopupMenuItem(value: 'remove', child: Text('Remove from workout')),
      ],
    );
  }

  /// "+" logs the previous set again, or last time's first set, or opens the keypad.
  void _quickAdd(BuildContext context, List<double> last) {
    final sets = _ex.sets;
    final weight = sets.isNotEmpty ? sets.last.weight : (last.isNotEmpty ? last.first : null);
    if (weight == null) {
      _addWithKeypad(context);
      return;
    }
    HapticFeedback.lightImpact();
    store.addSet(session, index, weight);
  }

  Future<void> _addWithKeypad(BuildContext context) async {
    final sets = _ex.sets;
    final r = await showWeightKeypad(
      context,
      title: '${_ex.name} · set ${sets.length + 1}',
      initial: sets.isNotEmpty ? sets.last.weight : null,
    );
    if (r?.weight != null) store.addSet(session, index, r!.weight!, dropSet: r.dropSet);
  }

  Future<void> _edit(BuildContext context, int setIndex) async {
    final set = _ex.sets[setIndex];
    final r = await showWeightKeypad(
      context,
      title: '${_ex.name} · set ${setIndex + 1}',
      initial: set.weight,
      dropSet: set.dropSet,
      allowDelete: true,
    );
    if (r == null) return;
    if (r.deleted) {
      store.removeSet(session, index, setIndex);
    } else if (r.weight != null) {
      store.updateSet(session, index, setIndex, r.weight!, r.dropSet);
    }
  }
}

class _SummaryDialog extends StatelessWidget {
  const _SummaryDialog({required this.duration, required this.sets, required this.records});

  final Duration duration;
  final int sets;
  final List<RecordEvent> records;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(records.isEmpty ? 'Workout saved' : 'Workout saved · ${records.length} PR${records.length == 1 ? '' : 's'}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${formatDuration(duration)} · $sets sets', style: AppText.caption),
        const SizedBox(height: AppSpace.md),
        for (final r in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(child: Text(r.exercise, style: AppText.body)),
              Text('${formatWeight(r.previous)} → ', style: AppText.caption),
              Text(formatWeight(r.weight),
                  style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: AppColors.accentLight)),
            ]),
          ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
    );
  }
}
