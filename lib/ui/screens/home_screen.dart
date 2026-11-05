import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/split_sheet.dart';
import '../widgets/set_chip.dart' show FoilFace;
import '../widgets/store_scope.dart';

/// Home: pick a day and rotation (pre-selected from history, never forced) and start.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// null = follow the suggestion.
  String? _dayId;
  String? _rotationId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final suggested = store.suggestedDay;
    final days = store.days;
    final dayId = days.any((d) => d.id == _dayId) ? _dayId! : suggested.id;
    final rotations = store.rotationsOf(dayId);
    final rotation = rotations.where((r) => r.id == _rotationId).firstOrNull ?? store.suggestedRotation(dayId);
    final active = store.activeSession;

    final startLabel = rotation == null ? null : store.rotationLabel(rotation.dayId, rotation.id);
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
          children: [
            _HomeHeader(greeting: active != null ? 'Let’s finish this!' : 'Ready to train?'),
            const SizedBox(height: AppSpace.lg),
            Text(
              active != null
                  ? '${store.sessionTitle(active)} is still open'
                  : startLabel == null
                      ? '${store.dayById(dayId)?.name ?? suggested.name} is next'
                      : '$startLabel is next',
              style: AppText.display,
            ),
            const SizedBox(height: 6),
            Text(
              active != null
                  ? 'Pick up where you stopped.'
                  : dayId == suggested.id
                      ? 'Suggested from your last workout. Tap any day or rotation to switch.'
                      : 'You picked ${store.dayById(dayId)?.name}. ${suggested.name} is still suggested.',
              style: AppText.caption.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpace.lg),
            if (active != null)
              _ResumeCard(store: store, session: active)
            else ...[
              Row(children: [
                const Expanded(child: SectionLabel('Day')),
                OutlinedButton.icon(
                  onPressed: () => showSplitSwitcher(context, store),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(store.activeSplit.name),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpace.sm),
              _DaySwitcher(
                days: days,
                selectedId: dayId,
                suggestedId: suggested.id,
                lastDone: store.lastDoneAt,
                onSelect: (id) => setState(() {
                  _dayId = id;
                  _rotationId = null;
                }),
              ),
              const SizedBox(height: AppSpace.lg),
              const SectionLabel('Rotation'),
              _RotationPicker(
                rotations: rotations,
                selected: rotation,
                suggested: store.suggestedRotation(dayId),
                onSelect: (r) => setState(() => _rotationId = r.id),
              ),
              const SizedBox(height: AppSpace.lg),
              if (rotation != null) _PlanPreview(store: store, rotation: rotation),
              const SizedBox(height: AppSpace.md),
              _OneTimeCard(onTap: () => openSession(context, store.startOneTime())),
            ],
            const SizedBox(height: AppSpace.xl),
            _RecentRecords(store: store),
          ],
        ),
      ),
      if (active == null && rotation != null)
        _BottomAction(
          label: 'Start $startLabel',
          onPressed: () => openSession(context, store.startSession(rotation)),
        ),
    ]);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/logo.png', width: 40, height: 40),
      ),
      const SizedBox(width: AppSpace.md),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Formazilla',
            style: TextStyle(fontFamily: AppFonts.condensed, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
        Text(greeting, style: AppText.caption),
      ]),
    ]);
  }
}

/// The screen's main action, pinned in thumb reach above the tabs.
class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.card)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.md),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(label),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
        ),
      ),
    );
  }
}

class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.days,
    required this.selectedId,
    required this.suggestedId,
    required this.lastDone,
    required this.onSelect,
  });

  final List<Day> days;
  final String selectedId;
  final String suggestedId;
  final DateTime? Function(String dayId) lastDone;
  final ValueChanged<String> onSelect;

  String _subtitle(Day d) {
    if (d.id == suggestedId) return 'Suggested';
    final last = lastDone(d.id);
    if (last == null) return 'Not yet';
    final ago = formatAgo(last, DateTime.now());
    return ago == 'Yesterday' || ago == 'Today' ? '$ago ✓' : ago;
  }

  static const _height = 66.0;
  static const _gap = AppSpace.sm;

  /// Three layers: card backgrounds, a navy pill that slides to the selected
  /// day, then transparent tappable labels on top.
  @override
  Widget build(BuildContext context) {
    if (days.length > 3) {
      return _ScrollingDays(
        count: days.length,
        suggestedIndex: days.indexWhere((d) => d.id == suggestedId),
        height: _height,
        builder: (context, i) => _dayLabel(context, days[i]),
        isSelected: (i) => days[i].id == selectedId,
      );
    }
    final selectedIndex = days.indexWhere((d) => d.id == selectedId).clamp(0, days.length - 1);
    final radius = BorderRadius.circular(AppRadius.card);
    return SizedBox(
      height: _height,
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - _gap * (days.length - 1)) / days.length;
        return Stack(children: [
          Row(children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(child: DecoratedBox(decoration: BoxDecoration(color: AppColors.card, borderRadius: radius))),
            ],
          ]),
          AnimatedPositioned(
            duration: Motion.of(context, Motion.base),
            curve: Motion.pop,
            left: selectedIndex * (w + _gap),
            top: 0,
            bottom: 0,
            width: w,
            child: DecoratedBox(decoration: BoxDecoration(color: AppColors.accent, borderRadius: radius)),
          ),
          Row(children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(child: _dayLabel(context, days[i])),
            ],
          ]),
        ]);
      }),
    );
  }

  Widget _dayLabel(BuildContext context, Day d) {
    final selected = d.id == selectedId;
    final suggested = d.id == suggestedId;
    final fast = Motion.of(context, Motion.fast);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedDefaultTextStyle(
          duration: fast,
          style: AppText.cardTitle.copyWith(fontSize: 18, color: selected ? AppColors.onAccent : AppColors.text),
          child: Text(d.name),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: fast,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.small.copyWith(
            color: selected || suggested ? AppColors.accentLight : AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
          child: Text(_subtitle(d)),
        ),
      ]),
    );
    Widget box = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => onSelect(d.id),
        child: SizedBox.expand(child: content),
      ),
    );
    if (suggested && !selected) {
      box = DashedBorder(radius: AppRadius.card, color: AppColors.accentLight, child: box);
    }
    return Semantics(selected: selected, label: '${d.name}, ${_subtitle(d)}', child: box);
  }
}

/// 4+ days: a horizontal row of fixed-width day buttons that scrolls, with the
/// suggested day scrolled into view when Home opens.
class _ScrollingDays extends StatefulWidget {
  const _ScrollingDays({
    required this.count,
    required this.suggestedIndex,
    required this.height,
    required this.builder,
    required this.isSelected,
  });

  final int count;
  final int suggestedIndex;
  final double height;
  final IndexedWidgetBuilder builder;
  final bool Function(int) isSelected;

  static const itemWidth = 112.0;
  static const gap = AppSpace.sm;

  @override
  State<_ScrollingDays> createState() => _ScrollingDaysState();
}

class _ScrollingDaysState extends State<_ScrollingDays> {
  late final ScrollController _scroll = ScrollController(
    // Show the day before the suggested one too, so you see where you are in the cycle.
    initialScrollOffset:
        (widget.suggestedIndex - 1).clamp(0, widget.count).toDouble() * (_ScrollingDays.itemWidth + _ScrollingDays.gap),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemCount: widget.count,
        separatorBuilder: (_, __) => const SizedBox(width: _ScrollingDays.gap),
        itemBuilder: (context, i) => AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          width: _ScrollingDays.itemWidth,
          decoration: BoxDecoration(
            color: widget.isSelected(i) ? AppColors.accent : AppColors.card,
            borderRadius: radius,
          ),
          child: widget.builder(context, i),
        ),
      ),
    );
  }
}

class _RotationPicker extends StatelessWidget {
  const _RotationPicker({required this.rotations, required this.selected, required this.suggested, required this.onSelect});

  final List<Rotation> rotations;
  final Rotation? selected;
  final Rotation? suggested;
  final ValueChanged<Rotation> onSelect;

  @override
  Widget build(BuildContext context) {
    if (rotations.length <= 1) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Pill('One rotation · used every time', fill: AppColors.card, fontSize: 13),
      );
    }
    final index = rotations.indexWhere((r) => r.id == selected?.id);
    return Row(children: [
      Segmented(
        options: [for (final r in rotations) r.name.isEmpty ? '•' : r.name],
        selected: index < 0 ? 0 : index,
        onChanged: (i) => onSelect(rotations[i]),
      ),
      const SizedBox(width: AppSpace.md),
      if (suggested != null)
        Expanded(child: Text('${suggested!.name} is next', style: AppText.small, textAlign: TextAlign.right)),
    ]);
  }
}

/// What's in the picked rotation, with last time's top set for each.
class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.store, required this.rotation});

  final AppStore store;
  final Rotation rotation;

  @override
  Widget build(BuildContext context) {
    final shown = rotation.exercises.take(4).toList();
    final rest = rotation.exercises.skip(4).toList();
    if (rotation.exercises.isEmpty) {
      return const AppCard(child: Text('No exercises yet. Add them as you go.', style: AppText.caption));
    }
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(children: [
        SizedBox(
          height: 40,
          child: Row(children: [
            Expanded(child: Text('${rotation.exercises.length} exercises', style: AppText.caption)),
            const Text('Last top set', style: AppText.caption),
          ]),
        ),
        for (final name in shown) ...[
          const Divider(),
          SizedBox(
            height: 46,
            child: Row(children: [
              Expanded(child: Text(name, style: AppText.body, overflow: TextOverflow.ellipsis)),
              Text(_top(name), style: AppText.chip.copyWith(color: AppColors.text)),
            ]),
          ),
        ],
        if (rest.isNotEmpty) ...[
          const Divider(),
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Then ${rest.join(', ')}', style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ]),
    );
  }

  String _top(String name) {
    final last = store.lastTime(name, '');
    if (last.isEmpty) return '–';
    return formatWeight(last.reduce((a, b) => a > b ? a : b));
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.store, required this.session});

  final AppStore store;
  final Session session;

  @override
  Widget build(BuildContext context) {
    final label = store.sessionTitle(session);
    final mins = DateTime.now().difference(session.startedAt).inMinutes;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: AppColors.accent,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(child: Text(label, style: AppText.band)),
            Text('$mins min', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onBand)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${store.exercisesDone(session)} of ${session.exercises.length} exercises · ${session.setCount} sets logged',
                style: AppText.caption.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpace.lg),
            Row(children: [
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Discard this workout?'),
                        content: const Text('Logged sets in it will be deleted.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
                        ],
                      ),
                    );
                    if (ok == true) store.discardSession(session);
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.dangerOutline)),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () => openSession(context, session),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Resume $label', overflow: TextOverflow.ellipsis),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// Recent PRs as foil stickers, newest first.
class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final records = store.recentRecords();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recent PRs', style: AppText.section),
      const SizedBox(height: AppSpace.sm),
      if (records.isEmpty)
        AppCard(
          child: Row(children: [
            Image.asset('assets/mascot.png', width: 84, height: 67, fit: BoxFit.contain),
            const SizedBox(width: AppSpace.md),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your PR foils land here', style: AppText.cardTitle),
                SizedBox(height: 4),
                Text('Beat a previous best and its foil sticker shows up here.', style: AppText.caption),
              ]),
            ),
          ]),
        )
      else
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
            itemBuilder: (context, i) {
              final r = records[i];
              return EnterFromBelow(
                delay: Duration(milliseconds: 60 * i),
                child: Semantics(
                  button: true,
                  label: '${r.exercise}, new PR ${formatWeight(r.weight)}, up ${formatWeight(r.delta)}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => openExercise(context, r.exercise),
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 92,
                      child: Column(children: [
                        const SizedBox(height: 4),
                        Transform.rotate(
                          angle: (i.isEven ? -2 : 2) * 3.14159 / 180,
                          child: SizedBox(
                            width: 80,
                            height: 88,
                            child: FoilFace(
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                FittedBox(
                                  child: Text(formatWeight(r.weight),
                                      style: AppText.sticker.copyWith(fontSize: 30, color: AppColors.onAccent)),
                                ),
                                const SizedBox(height: 4),
                                Text('+${formatWeight(r.delta)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onBand)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(r.exercise,
                            style: const TextStyle(fontSize: 13, color: AppColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ]);
  }
}

/// Starts a one-time workout: outside the plan, affects nothing but History.
class _OneTimeCard extends StatelessWidget {
  const _OneTimeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: DashedBorder(
          radius: AppRadius.card,
          color: AppColors.line,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.bolt_outlined, color: AppColors.accentLight, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('One-time workout', style: AppText.cardTitle),
                  SizedBox(height: 2),
                  Text('Hotel gym, evening cardio, arms day… Doesn’t touch your plan.', style: AppText.small),
                ]),
              ),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}
