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
    final done = store.exercisesDone(session);
    final elapsed = DateTime.now().difference(session.startedAt);
    final groups = groupExercises(session);
    final current = _currentIndex(session);

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
          ),
          Expanded(
            // Drag a card by its handle (or hold it) to move it. Supersets move as one card.
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
                final handle = ReorderableDragStartListener(
                  index: g,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.drag_indicator, color: AppColors.muted, semanticLabel: 'Drag to reorder'),
                  ),
                );
                return ReorderableDelayedDragStartListener(
                  key: ObjectKey(session.exercises[group.first]),
                  index: g,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.md),
                    child: group.length > 1
                        ? SupersetCard(store: store, session: session, indexes: group, dragHandle: handle)
                        : session.exercises[group.first].cardio
                            ? CardioCard(store: store, session: session, index: group.first, dragHandle: handle)
                            : ExerciseCard(
                                store: store,
                                session: session,
                                index: group.first,
                                current: group.first == current,
                                position: '${group.first + 1} of ${session.exercises.length}',
                                dragHandle: handle,
                              ),
                  ),
                );
              },
              footer: session.exercises.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text('Tap Add exercise to start logging.', style: AppText.caption, textAlign: TextAlign.center),
                    )
                  : null,
            ),
          ),
        ]),
      ),
      bottomNavigationBar: Material(
        color: AppColors.card,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.md),
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final pick = await showAddExerciseSheet(context, store, title: 'Add to ${store.sessionTitle(session)}');
                      if (pick != null) store.addExercise(session, pick.name, cardio: pick.cardio);
                    },
                    icon: const Icon(Icons.add, color: AppColors.accentLight),
                    label: const Text('Add exercise'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.chip, foregroundColor: AppColors.text),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                width: 124,
                height: 56,
                child: FilledButton(
                  onPressed: () => _finish(context, store, session),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
                  child: const Text('Finish'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// The exercise you're on: the one you logged most recently, else the first
  /// one with nothing logged yet.
  int _currentIndex(Session s) {
    if (s.current != null) {
      final key = exerciseKey(s.current!);
      final i = s.exercises.indexWhere((e) => exerciseKey(e.name) == key);
      if (i >= 0) return i;
    }
    final i = s.exercises.indexWhere((e) => !e.cardio && e.sets.isEmpty);
    return i < 0 ? 0 : i;
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
    this.onTitleTap,
  });

  final String title;
  final String subtitle;
  final List<Rotation> rotations;
  final String rotationId;
  final ValueChanged<Rotation> onRotation;
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
                  const Icon(Icons.edit_outlined, size: 18, color: AppColors.accentLight, semanticLabel: 'Rename'),
                ],
              ]),
            ),
            Text(subtitle, style: AppText.caption),
          ]),
        ),
        if (rotations.length > 1)
          Segmented(
            compact: true,
            options: [for (final r in rotations) r.name],
            selected: index < 0 ? 0 : index,
            onChanged: (i) => onRotation(rotations[i]),
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

/// Add an exercise or cardio. Type to search your history and the library;
/// any name you type can be added as new. Cardio is logged in minutes.
Future<({String name, bool cardio})?> showAddExerciseSheet(BuildContext context, AppStore store, {required String title}) {
  final controller = TextEditingController();
  return showModalBottomSheet<({String name, bool cardio})>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) {
        final query = controller.text.trim();
        final results = store.searchLibrary(query);
        final exact = results.any((r) => exerciseKey(r) == exerciseKey(query));
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.85),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppText.title),
                  const SizedBox(height: AppSpace.md),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.body.copyWith(fontSize: 17),
                    decoration: const InputDecoration(
                      hintText: 'Search exercises',
                      prefixIcon: Icon(Icons.search, color: AppColors.muted),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (v) {
                      final name = v.trim();
                      if (name.isNotEmpty) Navigator.pop(c, (name: name, cardio: store.isCardio(name)));
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                  for (final name in results)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(name, style: AppText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                      trailing: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: AppColors.accentLight),
                      ),
                      onTap: () => Navigator.pop(c, (name: name, cardio: store.isCardio(name))),
                    ),
                  if (query.isNotEmpty && !exact)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined, color: AppColors.accentLight),
                      title: Text('Add “$query” as a new exercise',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accentLight)),
                      onTap: () => Navigator.pop(c, (name: query, cardio: false)),
                    ),
                  const SizedBox(height: AppSpace.md),
                  const Text('Cardio', style: AppText.section),
                  const SizedBox(height: 2),
                  const Text('Logged in minutes, no sets.', style: AppText.caption),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final name in store.cardioNames)
                      ActionChip(
                        avatar: const Icon(Icons.timer_outlined, size: 18, color: AppColors.accentLight),
                        label: Text(name),
                        onPressed: () => Navigator.pop(c, (name: name, cardio: true)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18, color: AppColors.accentLight),
                      label: const Text('Custom'),
                      side: const BorderSide(color: AppColors.line, style: BorderStyle.solid),
                      onPressed: () async {
                        final name = await askText(c, title: 'New cardio', hint: 'Swimming');
                        final clean = name?.trim() ?? '';
                        if (clean.isNotEmpty && c.mounted) Navigator.pop(c, (name: clean, cardio: true));
                      },
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        );
      },
    ),
  );
}
