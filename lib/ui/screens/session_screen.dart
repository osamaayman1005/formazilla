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
import '../widgets/split_sheet.dart' show askText;
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
    final rotations = store.rotationsOf(session.dayId);
    final done = session.exercises.where((e) => e.logged).length;
    final elapsed = DateTime.now().difference(session.startedAt);
    final groups = groupExercises(session);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _Header(
            title: store.sessionTitle(session),
            onTitleTap: session.oneTime
                ? () async {
                    final name = await askText(context, title: 'Name this workout', initial: session.title, hint: 'Hotel gym');
                    if (name != null) store.renameOneTime(session, name);
                  }
                : null,
            subtitle: session.oneTime
                ? '${formatDuration(elapsed)} · One-time'
                : '${formatDuration(elapsed)} · $done of ${session.exercises.length} done',
            rotations: rotations,
            rotationId: session.rotationId,
            onRotation: (r) => store.switchRotation(session, r),
            onFinish: () => _finish(context, store, session),
          ),
          Expanded(
            // Hold a card, then drag it up or down. Supersets move as one card.
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              buildDefaultDragHandles: false,
              itemCount: groups.length,
              onReorderStart: (_) => HapticFeedback.mediumImpact(),
              onReorderItem: (from, to) => store.moveExerciseGroup(session, from, to),
              proxyDecorator: (child, _, animation) => AnimatedBuilder(
                animation: animation,
                builder: (_, child) => Transform.scale(
                  scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
                  child: Material(type: MaterialType.transparency, child: child),
                ),
                child: child,
              ),
              itemBuilder: (context, g) {
                final group = groups[g];
                return ReorderableDelayedDragStartListener(
                  key: ObjectKey(session.exercises[group.first]),
                  index: g,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: group.length > 1
                        ? SupersetCard(store: store, session: session, indexes: group)
                        : session.exercises[group.first].cardio
                            ? CardioCard(store: store, session: session, index: group.first)
                            : ExerciseCard(store: store, session: session, index: group.first),
                  ),
                );
              },
              footer: Column(children: [
                Row(children: [
                  Expanded(
                    child: ExerciseInput(
                      search: store.searchLibrary,
                      onSubmit: (name) => store.addExercise(session, name),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  CardioAddButton(onPressed: () async {
                    final name = await showCardioPicker(context, store);
                    if (name != null) store.addExercise(session, name, cardio: true);
                  }),
                ]),
                const SizedBox(height: AppSpace.md),
                const Text(
                  'Tap dashed = same as last time · + = type a weight · Hold a card to move it · '
                  'Long-press a set = drop set · ⋮ = superset',
                  style: AppText.small,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _finish(BuildContext context, AppStore store, Session session) async {
    if (!session.hasLogs) {
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
    final cardio = session.cardioMinutes;
    final label = store.sessionTitle(session);
    final records = store.finishSession(session);
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    final share = await showDialog<RecordEvent>(
      context: context,
      builder: (c) => _SummaryDialog(duration: duration, sets: sets, cardio: cardio, records: records),
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
    required this.rotations,
    required this.rotationId,
    required this.onRotation,
    required this.onFinish,
    this.onTitleTap,
  });

  final String title;
  final String subtitle;
  final List<Rotation> rotations;
  final String rotationId;
  final ValueChanged<Rotation> onRotation;
  final VoidCallback onFinish;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final index = rotations.indexWhere((r) => r.id == rotationId);
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
            GestureDetector(
              onTap: onTitleTap,
              child: Row(children: [
                Flexible(child: Text(title, style: AppText.title.copyWith(fontSize: 22), overflow: TextOverflow.ellipsis)),
                if (onTitleTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
                ],
              ]),
            ),
            Text(subtitle, style: AppText.caption),
          ]),
        ),
        if (rotations.length > 1) ...[
          Segmented(
            compact: true,
            options: [for (final r in rotations) r.name],
            selected: index < 0 ? 0 : index,
            onChanged: (i) => onRotation(rotations[i]),
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
  const _SummaryDialog({required this.duration, required this.sets, required this.cardio, required this.records});

  final Duration duration;
  final int sets;
  final double cardio;
  final List<RecordEvent> records;

  @override
  Widget build(BuildContext context) {
    final best = records.isEmpty ? null : (records.toList()..sort((a, b) => b.delta.compareTo(a.delta))).first;
    return AlertDialog(
      title: Text(records.isEmpty ? 'Workout saved' : 'Workout saved · ${records.length} PR${records.length == 1 ? '' : 's'}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${formatDuration(duration)} · $sets sets${cardio > 0 ? ' · ${formatWeight(cardio)} min cardio' : ''}',
            style: AppText.caption),
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
