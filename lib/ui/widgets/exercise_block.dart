/// Exercise cards inside the session logger: a single exercise, or a superset
/// (two or more exercises done alternately in one card).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/workout_logic.dart' show exerciseGroups, isNewRecord, supersetNext, supersetRound;
import '../../state/app_store.dart';
import 'common.dart';
import 'kaiju.dart';
import 'keypad_sheet.dart';
import 'motion.dart';
import 'set_chip.dart';

/// The cards of a workout: supersets share one card. See [exerciseGroups].
List<List<int>> groupExercises(Session s) => exerciseGroups([for (final e in s.exercises) e.supersetId]);

/// One exercise in its own card.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.store, required this.session, required this.index});

  final AppStore store;
  final Session session;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
      child: ExerciseBody(store: store, session: session, index: index, showMenu: true),
    );
  }
}

/// Two or more exercises done alternately: A → B → A → B.
class SupersetCard extends StatelessWidget {
  const SupersetCard({super.key, required this.store, required this.session, required this.indexes});

  final AppStore store;
  final Session session;
  final List<int> indexes;

  @override
  Widget build(BuildContext context) {
    final counts = [for (final i in indexes) session.exercises[i].sets.length];
    final next = supersetNext(counts);
    final id = session.exercises[indexes.first].supersetId!;
    return AppCard(
      borderColor: AppColors.accentLight,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Pill('Superset', fill: AppColors.accent, color: AppColors.onAccent),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text('Round ${supersetRound(counts)}', style: AppText.caption)),
          TextButton(
            onPressed: () => _unlink(context, id),
            child: const Text('Unlink', style: TextStyle(color: AppColors.accentLight)),
          ),
        ]),
        for (var k = 0; k < indexes.length; k++) ...[
          if (k > 0) const Divider(color: AppColors.line, height: 20, endIndent: 12),
          ExerciseBody(
            store: store,
            session: session,
            index: indexes[k],
            letter: String.fromCharCode(65 + k),
            nextUp: k == next,
            showMenu: true,
          ),
        ],
        const SizedBox(height: AppSpace.xs),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Text('Log A, then B. "Next up" moves on its own.', style: AppText.small),
        ),
      ]),
    );
  }

  Future<void> _unlink(BuildContext context, String id) async {
    var fromTemplate = false;
    if (store.isTemplatePair(session, id)) {
      final choice = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Unlink superset'),
          content: const Text('This pair is saved in the template too.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, 'today'), child: const Text('Just today')),
            TextButton(onPressed: () => Navigator.pop(c, 'always'), child: const Text('Also template')),
          ],
        ),
      );
      if (choice == null) return;
      fromTemplate = choice == 'always';
    }
    store.unlinkSuperset(session, id, fromTemplate: fromTemplate);
  }
}

/// Name, PR badge, last-time line and set chips for one exercise.
class ExerciseBody extends StatelessWidget {
  const ExerciseBody({
    super.key,
    required this.store,
    required this.session,
    required this.index,
    this.letter,
    this.nextUp = false,
    this.showMenu = false,
  });

  final AppStore store;
  final Session session;
  final int index;
  final String? letter;
  final bool nextUp;
  final bool showMenu;

  SessionExercise get _ex => session.exercises[index];

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final best = store.recordBefore(ex.name, session.id);
    final last = store.lastTime(ex.name, session.id);
    final top = ex.sets.isEmpty ? null : ex.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    final hitRecord = top != null && isNewRecord(top, best);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (letter != null) ...[
          _LetterBadge(letter!, active: nextUp),
          const SizedBox(width: AppSpace.sm),
        ],
        Expanded(child: Text(ex.name, style: AppText.cardTitle)),
        if (letter != null)
          _SlideSwap(
            child: nextUp
                ? const Padding(
                    key: ValueKey('next'),
                    padding: EdgeInsets.only(right: 6),
                    child: Pill('Next up', color: AppColors.accentLight, outline: AppColors.accentLight, fontSize: 11),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        _SlideSwap(
          child: hitRecord
              ? Pill('New PR ${formatWeight(top)}',
                  key: ValueKey('pr-$top'),
                  fill: AppColors.accent,
                  color: AppColors.onAccent,
                  leading: const ClawMark(size: 12))
              : best != null
                  ? Text('PR ${formatWeight(best)}',
                      key: const ValueKey('pr-old'), style: AppText.small.copyWith(fontWeight: FontWeight.w500))
                  : const SizedBox.shrink(key: ValueKey('pr-none')),
        ),
        if (showMenu) _menu(context) else const SizedBox(width: 12, height: 40),
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
              key: ValueKey('slot-$i'),
              popIn: store.justLogged(session, index, i),
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
              key: ValueKey('slot-$j'),
              kind: ChipKind.ghost,
              weight: last[j],
              onTap: () {
                HapticFeedback.lightImpact();
                store.addSet(session, index, last[j]);
              },
            ),
          SetChip(
            key: const ValueKey('add'),
            kind: ChipKind.add,
            onTap: () => _addWithKeypad(context),
          ),
        ]),
      ),
    ]);
  }

  Widget _menu(BuildContext context) {
    final inSuperset = _ex.supersetId != null;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
      color: AppColors.chip,
      onSelected: (v) {
        switch (v) {
          case 'rename':
            showRenameExercise(context, store, session, index);
          case 'superset':
            showLinkSupersetSheet(context, store, session, index);
          case 'remove':
            final removed = _ex;
            store.removeExercise(session, index);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${removed.name} removed'),
              action: SnackBarAction(label: 'Undo', onPressed: () => store.insertExercise(session, index, removed)),
            ));
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        if (!inSuperset) const PopupMenuItem(value: 'superset', child: Text('Superset with…')),
        const PopupMenuItem(value: 'remove', child: Text('Remove from workout')),
      ],
    );
  }

  /// "+" always opens an empty keypad; the dashed ghost chips are the
  /// one-tap "same as last time" option.
  Future<void> _addWithKeypad(BuildContext context) async {
    final r = await showWeightKeypad(context, title: '${_ex.name} · set ${_ex.sets.length + 1}');
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

/// Swaps its child with a short fade + slide from the right.
class _SlideSwap extends StatelessWidget {
  const _SlideSwap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.base),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.4, 0), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge(this.letter, {required this.active});

  final String letter;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.of(context, Motion.base),
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.accentLight : AppColors.chip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(letter,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.bg : AppColors.text)),
    );
  }
}

/// Permanent rename (templates and history too); logged sets stay as they are.
Future<void> showRenameExercise(BuildContext context, AppStore store, Session session, int index) async {
  final controller = TextEditingController(text: session.exercises[index].name);
  final name = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Rename exercise'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Machine chest press'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        const SizedBox(height: AppSpace.sm),
        const Text('Changes it everywhere: templates, past workouts and PRs.', style: AppText.small),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, controller.text), child: const Text('Save')),
      ],
    ),
  );
  if (name != null) store.renameExercise(session, index, name);
}

/// Cardio: one time button. Tap it to type minutes (or change them).
class CardioCard extends StatelessWidget {
  const CardioCard({super.key, required this.store, required this.session, required this.index});

  final AppStore store;
  final Session session;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ex = session.exercises[index];
    final minutes = ex.minutes;
    return AppCard(
      borderColor: AppColors.accentLight,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monitor_heart_outlined, color: AppColors.accentLight, size: 22),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text(ex.name, style: AppText.cardTitle)),
          const Pill('Cardio', fill: AppColors.accent, color: AppColors.onAccent, fontSize: 11),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.muted, size: 20),
            color: AppColors.chip,
            onSelected: (v) {
              switch (v) {
                case 'rename':
                  showRenameExercise(context, store, session, index);
                case 'remove':
                  final removed = ex;
                  store.removeExercise(session, index);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${removed.name} removed'),
                    action: SnackBarAction(label: 'Undo', onPressed: () => store.insertExercise(session, index, removed)),
                  ));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'remove', child: Text('Remove from workout')),
            ],
          ),
        ]),
        const SizedBox(height: AppSpace.sm),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: minutes == null ? AppColors.chip : AppColors.accent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              onTap: () => _editTime(context),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: Center(
                  child: Text(
                    minutes == null ? 'Add time' : '${formatWeight(minutes)} min',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: minutes == null ? AppColors.accentLight : AppColors.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _editTime(BuildContext context) async {
    final ex = session.exercises[index];
    final r = await showMinutesKeypad(context, title: '${ex.name} · minutes', initial: ex.minutes);
    if (r == null) return;
    HapticFeedback.lightImpact();
    store.setCardioMinutes(session, index, r.deleted ? null : r.weight);
  }
}

/// Pick a cardio (or type your own). Returns the name, or null.
Future<String?> showCardioPicker(BuildContext context, AppStore store) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add cardio', style: AppText.title),
            const SizedBox(height: AppSpace.md),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final name in store.cardioNames)
                ActionChip(
                  avatar: const Icon(Icons.monitor_heart_outlined, size: 16, color: AppColors.accentLight),
                  label: Text(name),
                  onPressed: () => Navigator.pop(c, name),
                ),
            ]),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Or type your own, e.g. Hill sprints'),
              onSubmitted: (v) => Navigator.pop(c, v.trim().isEmpty ? null : v.trim()),
            ),
            const SizedBox(height: AppSpace.md),
            PrimaryButton('Add', onPressed: () {
              final v = controller.text.trim();
              Navigator.pop(c, v.isEmpty ? null : v);
            }),
          ]),
        ),
      ),
    ),
  );
}

/// The small "Cardio" pill that sits beside the add-exercise field.
class CardioAddButton extends StatelessWidget {
  const CardioAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.monitor_heart_outlined, size: 16, color: AppColors.accentLight),
      label: const Text('Cardio', style: TextStyle(color: AppColors.accentLight, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
      ),
    );
  }
}

/// Bottom sheet: pick the exercise to alternate with, optionally save to the template.
Future<void> showLinkSupersetSheet(BuildContext context, AppStore store, Session session, int index) {
  final candidates = [
    for (var i = 0; i < session.exercises.length; i++)
      if (i != index && session.exercises[i].supersetId == null && !session.exercises[i].cardio) i,
  ];
  int? chosen = candidates.isEmpty ? null : candidates.firstWhere((i) => i > index, orElse: () => candidates.first);
  var keep = true;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Superset with…', style: AppText.title),
            const SizedBox(height: 4),
            Text('${session.exercises[index].name} will alternate with:', style: AppText.caption),
            const SizedBox(height: AppSpace.md),
            if (candidates.isEmpty)
              const Text('Add another exercise to this workout first.', style: AppText.body)
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.4),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(AppRadius.card)),
                  child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 4), children: [
                    for (final i in candidates)
                      ListTile(
                        title: Text(session.exercises[i].name, style: AppText.body),
                        trailing: Icon(
                          chosen == i ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: chosen == i ? AppColors.accentLight : AppColors.muted,
                        ),
                        onTap: () => setState(() => chosen = i),
                      ),
                  ]),
                ),
              ),
            const SizedBox(height: AppSpace.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: keep,
              onChanged: (v) => setState(() => keep = v),
              title: Text('Keep linked in the ${store.rotationLabel(session.dayId, session.rotationId)} template',
                  style: AppText.body),
            ),
            const SizedBox(height: AppSpace.sm),
            PrimaryButton(
              'Link as superset',
              onPressed: chosen == null
                  ? null
                  : () {
                      store.linkSuperset(session, index, chosen!, keepInTemplate: keep);
                      HapticFeedback.mediumImpact();
                      Navigator.pop(c);
                    },
            ),
          ]),
        ),
      ),
    ),
  );
}
