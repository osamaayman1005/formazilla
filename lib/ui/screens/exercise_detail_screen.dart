import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/workout_logic.dart' show TopSet;
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/store_scope.dart';

/// One exercise: all-time PR, gain since start, top-set chart and history.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final history = store.topSets(name);
    final record = store.record(name);
    final gain = history.isEmpty ? 0.0 : history.last.weight - history.first.weight;
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
                  Expanded(child: _Metric(label: 'All-time PR', value: formatWeight(record ?? 0), accent: true)),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: _Metric(label: 'Since start', value: gainText),
                  ),
                ]),
                const SizedBox(height: AppSpace.lg),
                AppCard(child: _TopSetChart(points: history.length > 12 ? history.sublist(history.length - 12) : history)),
                const SizedBox(height: AppSpace.xl),
                const Text('History', style: AppText.section),
                const SizedBox(height: AppSpace.sm),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: [
                    for (final p in history.reversed)
                      ListTile(
                        dense: true,
                        leading: Text(formatShortDate(p.date), style: AppText.caption),
                        title: Text(formatWeights(p.allSets), style: AppText.body, textAlign: TextAlign.right),
                        trailing: p.wasRecord
                            ? const Pill('PR', fill: AppColors.accent, color: AppColors.onAccent, fontSize: 11)
                            : const SizedBox(width: 34),
                      ),
                  ]),
                ),
              ],
            ),
    );
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
    final max = points.map((p) => p.weight).reduce((a, b) => a > b ? a : b);
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
                      tween: Tween(begin: 0, end: max <= 0 ? 0.04 : (points[i].weight / max).clamp(0.04, 1.0)),
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
