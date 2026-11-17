import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/workout_logic.dart' show TopSet;
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/store_scope.dart';

/// One exercise: PR, gain since start, top-set chart and history.
/// "Reset PR" starts this exercise's PR over from its latest workout.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final history = store.topSets(name);
    final record = store.record(name);
    final resetAt = store.recordResetAt(name);
    // Chart and "since start" only use workouts that count for the PR.
    final counted = history.where((p) => !p.beforeReset).toList();
    final chart = counted.isEmpty ? history : counted;
    final gain = chart.isEmpty ? 0.0 : chart.last.weight - chart.first.weight;
    final gainText = '${gain >= 0 ? '+' : ''}${formatWeight(gain)}';

    return Scaffold(
      appBar: AppBar(title: Text(name), actions: [
        if (history.isNotEmpty)
          IconButton(
            tooltip: 'Share PR card',
            icon: const Icon(Icons.ios_share),
            onPressed: () => openRecordCard(context, name),
          ),
      ]),
      body: history.isEmpty
          ? const EmptyState(title: 'No sets yet', body: 'Log this exercise in a workout to see progress.')
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
              children: [
                Row(children: [
                  Expanded(
                    child: _Metric(
                      label: resetAt == null ? 'All-time PR' : 'PR since ${formatShortDate(resetAt)}',
                      value: formatWeight(record ?? 0),
                      accent: true,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: _Metric(label: resetAt == null ? 'Since start' : 'Since reset', value: gainText),
                  ),
                ]),
                const SizedBox(height: AppSpace.sm),
                Row(children: [
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt, size: 20),
                    label: const Text('Reset PR'),
                  ),
                  if (resetAt != null) ...[
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: TextButton(
                        onPressed: () => store.restoreRecordReset(name, null),
                        child: const Text('Count all history again', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: AppSpace.md),
                AppCard(child: _TopSetChart(points: chart.length > 12 ? chart.sublist(chart.length - 12) : chart)),
                const SizedBox(height: AppSpace.xl),
                const Text('History', style: AppText.section),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    for (final (i, p) in history.reversed.indexed) ...[
                      // One label where the counted workouts end.
                      if (p.beforeReset && (i == 0 || !history.reversed.elementAt(i - 1).beforeReset))
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 10, 16, 2),
                          child: Row(children: [
                            Icon(Icons.restart_alt, size: 16, color: AppColors.muted),
                            SizedBox(width: 6),
                            Text('Before PR reset: kept, not counted', style: AppText.small),
                          ]),
                        ),
                      ListTile(
                        dense: true,
                        leading: Text(formatShortDate(p.date), style: AppText.caption),
                        title: Text(formatWeights(p.allSets),
                            style: p.beforeReset ? AppText.body.copyWith(color: AppColors.muted) : AppText.body,
                            textAlign: TextAlign.right),
                        trailing: p.wasRecord
                            ? const Pill('PR', fill: AppColors.accent, color: AppColors.onAccent, fontSize: 11)
                            : const SizedBox(width: 34),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final store = StoreScope.of(context);
    final latest = store.latestTop(name);
    if (latest == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Reset $name PR?'),
        content: Text(
          'Your PR becomes ${formatWeight(latest.weight)}, the best set of your last workout '
          '(${formatShortDate(latest.date)}). Older workouts stay in History but stop counting for PRs. '
          'Other exercises keep their PRs.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset PR')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final previous = store.resetRecord(name);
    showActionSnackBar(context, '$name PR is now ${formatWeight(latest.weight)}',
        action: 'Undo', onAction: () => store.restoreRecordReset(name, previous));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: accent ? AppColors.accent : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption.copyWith(color: accent ? AppColors.accentLight : AppColors.muted)),
        const SizedBox(height: 4),
        Text(value, style: AppText.display.copyWith(fontSize: 30, color: accent ? AppColors.onAccent : AppColors.text)),
      ]),
    );
  }
}

/// Simple bar chart: one bar per session, latest highlighted. No chart package needed.
class _TopSetChart extends StatelessWidget {
  const _TopSetChart({required this.points});

  final List<TopSet> points;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Top weight per session', style: AppText.caption),
      const SizedBox(height: AppSpace.md),
      SizedBox(
        height: 150,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  label: '${formatShortDate(points[i].date)}: ${formatWeight(points[i].weight)}',
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(formatWeight(points[i].weight), style: AppText.small.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    // Bars grow one after another when the screen opens.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: barFraction(points[i].weight, points.map((p) => p.weight))),
                      duration: Motion.of(context, Motion.slow + Duration(milliseconds: 60 * i)),
                      curve: Curves.easeOutCubic,
                      builder: (_, f, __) => Container(
                        height: 120 * f,
                        decoration: BoxDecoration(
                          color: i == points.length - 1 ? AppColors.accentLight : AppColors.chip,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: AppSpace.sm),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(formatShortDate(points.first.date), style: AppText.small),
        Text(formatShortDate(points.last.date), style: AppText.small),
      ]),
    ]);
  }
}
