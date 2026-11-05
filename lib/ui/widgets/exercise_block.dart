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
import 'keypad_sheet.dart';
import 'motion.dart';
import 'set_chip.dart';

/// The cards of a workout: supersets share one card. See [exerciseGroups].
List<List<int>> groupExercises(Session s) => exerciseGroups([for (final e in s.exercises) e.supersetId]);

/// One exercise in its own card: the album row. The exercise you're on gets
/// the navy band; the others a quieter one.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.store,
    required this.session,
    required this.index,
    this.current = false,
    this.position,
    this.dragHandle,
  });

  final AppStore store;
  final Session session;
  final int index;

  /// The exercise being worked on now.
  final bool current;

  /// "3 of 6" on the band.
  final String? position;

  /// Visible handle to drag the card (drag-to-reorder).
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final ex = session.exercises[index];
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: current ? AppColors.accent : AppColors.chip,
          padding: EdgeInsets.fromLTRB(16, 4, dragHandle == null ? 16 : 0, 4),
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            Expanded(
              child: Text(ex.name,
                  style: AppText.band.copyWith(color: current ? AppColors.onAccent : AppColors.text)),
            ),
            if (position != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(position!,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: current ? AppColors.onBand : AppColors.muted)),
              ),
            if (dragHandle != null) dragHandle!,
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ExerciseBody(store: store, session: session, index: index, showHeader: false, showActions: true),
        ),
      ]),
    );
  }
}

/// Two or more exercises done alternately: A → B → A → B.
class SupersetCard extends StatelessWidget {
  const SupersetCard({super.key, required this.store, required this.session, required this.indexes, this.dragHandle});

  final AppStore store;
  final Session session;
  final List<int> indexes;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final counts = [for (final i in indexes) session.exercises[i].sets.length];
    final next = supersetNext(counts);
    final id = session.exercises[indexes.first].supersetId!;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Pill('Superset', fill: AppColors.chip, color: AppColors.accentLight),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text('Round ${supersetRound(counts)} · do A, then B', style: AppText.caption)),
          TextButton(onPressed: () => _unlink(context, id), child: const Text('Unlink')),
          if (dragHandle != null) dragHandle!,
        ]),
        for (var k = 0; k < indexes.length; k++) ...[
          if (k > 0) const Padding(padding: EdgeInsets.only(right: 12), child: Divider(height: 24)),
          ExerciseBody(
            store: store,
            session: session,
            index: indexes[k],
            letter: String.fromCharCode(65 + k),
            nextUp: k == next,
            showMenu: true,
          ),
        ],
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

/// Name (optional), last-time line, the sticker slots and, on a single
/// exercise, the visible actions.
class ExerciseBody extends StatelessWidget {
  const ExerciseBody({
    super.key,
    required this.store,
    required this.session,
    required this.index,
    this.letter,
    this.nextUp = false,
    this.showMenu = false,
    this.showHeader = true,
    this.showActions = false,
  });

  final AppStore store;
  final Session session;
  final int index;
  final String? letter;
  final bool nextUp;
  final bool showMenu;
  final bool showHeader;
  final bool showActions;

  SessionExercise get _ex => session.exercises[index];

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final best = store.recordBeforeIn(session, ex.name);
    final last = store.lastTimeIn(session, ex.name);
    final top = ex.sets.isEmpty ? null : ex.sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    final hitRecord = top != null && isNewRecord(top, best);
    final nextGhost = ex.sets.length < last.length ? last[ex.sets.length] : null;

    final lastLine = last.isNotEmpty
        ? 'Last time ${formatWeights(last)}${best != null ? ' · best ${formatWeight(best)}' : ''}'
        : ex.sets.isEmpty
            ? (session.oneTime ? 'Tap + to log' : 'First time. Tap + to log')
            : 'First time';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showHeader)
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
          if (showMenu)
            IconButton(
              tooltip: 'Options for ${ex.name}',
              icon: const Icon(Icons.more_horiz, color: AppColors.muted),
              onPressed: () => showExerciseOptions(context, store, session, index),
            )
          else
            const SizedBox(width: 12, height: 40),
        ]),
      Padding(
        padding: EdgeInsets.only(right: showHeader ? 12 : 0),
        child: Text(lastLine, style: AppText.caption.copyWith(fontSize: 14, fontFeatures: const [FontFeature.tabularFigures()])),
      ),
      const SizedBox(height: AppSpace.md),
      Padding(
        padding: EdgeInsets.only(right: showHeader ? 12 : 0),
        child: Wrap(spacing: 6, runSpacing: 8, children: [
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
              index: j,
              onTap: () => _logSame(context, last[j]),
            ),
          SetChip(
            key: const ValueKey('add'),
            kind: ChipKind.add,
            onTap: () => _addWithKeypad(context),
          ),
        ]),
      ),
      if (showActions) ...[
        if (nextGhost != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text('Tap ${formatWeight(nextGhost)} to repeat it, or + for a new weight', style: AppText.caption),
        ],
        if (hitRecord) ...[
          const SizedBox(height: AppSpace.sm),
          Pill(
            best == null ? 'New PR ${formatWeight(top!)}' : 'New PR · ${formatWeight(top!)} beats ${formatWeight(best)}',
            fill: AppColors.chip,
            color: AppColors.accentLight,
            fontSize: 14,
            leading: const Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.accentLight),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _addWithKeypad(context, dropSet: true),
              icon: const Icon(Icons.arrow_downward, size: 18),
              label: const Text('Drop set', maxLines: 1),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          if (ex.supersetId == null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showLinkSupersetSheet(context, store, session, index),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Superset', maxLines: 1),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showExerciseOptions(context, store, session, index),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit', maxLines: 1),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ),
        ]),
      ],
    ]);
  }

  /// The outlined slot: logs last time's weight in one tap, with Undo.
  void _logSame(BuildContext context, double weight) {
    HapticFeedback.lightImpact();
    final setIndex = _ex.sets.length;
    store.addSet(session, index, weight);
    showActionSnackBar(context, 'Set ${setIndex + 1} logged · ${formatWeight(weight)}',
        action: 'Undo', onAction: () => store.removeSet(session, index, setIndex));
  }

  /// "+" (and Drop set) always open a clean keypad: nothing prefilled, so a
  /// new number is typed without erasing. Last time is shown as a hint only.
  Future<void> _addWithKeypad(BuildContext context, {bool dropSet = false}) async {
    final ex = _ex;
    final n = ex.sets.length;
    final last = store.lastTimeIn(session, ex.name);
    final best = store.recordBeforeIn(session, ex.name);
    final hint = [
      if (n < last.length) 'Last time ${formatWeight(last[n])}',
      if (best != null) 'best ${formatWeight(best)}',
    ].join(' · ');
    final r = await showWeightKeypad(
      context,
      title: '${ex.name} · ${dropSet ? 'drop set' : 'set ${n + 1}'}',
      dropSet: dropSet,
      hint: hint.isEmpty ? null : hint,
    );
    if (r?.weight != null) store.addSet(session, index, r!.weight!, dropSet: r.dropSet);
  }

  /// A logged sticker: the keypad opens with its weight selected.
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

/// Exercise options: rename, move, superset, remove. Every option is a
/// labelled row; nothing hides behind a gesture.
Future<void> showExerciseOptions(BuildContext context, AppStore store, Session session, int index) {
  final ex = session.exercises[index];
  final groups = groupExercises(session);
  final g = groups.indexWhere((group) => group.contains(index));
  final template = session.oneTime ? null : store.rotationLabel(session.dayId, session.rotationId);

  Widget option(BuildContext c, IconData icon, String title, String subtitle, VoidCallback? onTap,
      {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.accentLight;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
      enabled: onTap != null,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: onTap == null ? AppColors.muted : color, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.text)),
      subtitle: Text(subtitle, style: AppText.caption),
      onTap: onTap == null
          ? null
          : () {
              Navigator.pop(c);
              onTap?.call();
            },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ex.name, style: AppText.title),
          if (template != null) ...[
            const SizedBox(height: 4),
            Text('Changes here also update the $template template.', style: AppText.caption),
          ],
          const SizedBox(height: AppSpace.sm),
          option(c, Icons.edit_outlined, 'Rename', 'Everywhere: templates, past workouts and PRs',
              () => showRenameExercise(context, store, session, index)),
          option(c, Icons.arrow_upward, 'Move up', 'Or drag the handle on the card',
              g > 0 ? () => store.moveExerciseGroup(session, g, g - 1) : null),
          option(c, Icons.arrow_downward, 'Move down', 'Up next order changes too',
              g >= 0 && g < groups.length - 1 ? () => store.moveExerciseGroup(session, g, g + 1) : null),
          if (ex.supersetId == null && !ex.cardio)
            option(c, Icons.link, 'Superset with…', 'Alternate it with another exercise',
                () => showLinkSupersetSheet(context, store, session, index)),
          option(c, Icons.delete_outline, 'Remove from workout', 'Its logged sets go too. Undo is offered.', () {
            final removed = session.exercises[index];
            store.removeExercise(session, index);
            showActionSnackBar(context, '${removed.name} removed',
                action: 'Undo', onAction: () => store.insertExercise(session, index, removed));
          }, danger: true),
        ]),
      ),
    ),
  );
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

/// Cardio: minutes only, no sets or PRs. One wide sticker shows the time;
/// tap it to type or change the minutes.
class CardioCard extends StatelessWidget {
  const CardioCard({super.key, required this.store, required this.session, required this.index, this.dragHandle});

  final AppStore store;
  final Session session;
  final int index;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final ex = session.exercises[index];
    final minutes = ex.minutes;
    return AppCard(
      padding: EdgeInsets.fromLTRB(16, 14, dragHandle == null ? 16 : 0, 14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(ex.name, style: AppText.cardTitle.copyWith(fontSize: 17)),
              const Pill('Cardio', fill: AppColors.chip, color: AppColors.accentLight, fontSize: 12),
            ]),
            const SizedBox(height: 6),
            Text(minutes == null ? 'Tap to type the minutes.' : 'Minutes only, no sets or PRs. Tap to change.',
                style: AppText.caption),
            TextButton.icon(
              onPressed: () => showExerciseOptions(context, store, session, index),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            ),
          ]),
        ),
        const SizedBox(width: AppSpace.md),
        Semantics(
          button: true,
          label: minutes == null ? 'Log ${ex.name} minutes' : '${ex.name}, ${formatWeight(minutes)} minutes. Change',
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sticker),
              onTap: () => _editTime(context),
              child: SizedBox(
                width: 72,
                height: 64,
                child: minutes == null
                    ? const DashedBorder(
                        radius: AppRadius.sticker,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add, color: AppColors.accentLight, size: 22),
                          Text('min', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        ]),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.sticker)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(formatWeight(minutes), style: AppText.sticker.copyWith(fontSize: 26)),
                          const SizedBox(height: 4),
                          const Text('min', style: TextStyle(fontSize: 11, color: AppColors.paperCaption)),
                        ]),
                      ),
              ),
            ),
          ),
        ),
        if (dragHandle != null) dragHandle!,
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
  var keep = !session.oneTime; // one-time workouts have no template

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
            if (!session.oneTime)
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
