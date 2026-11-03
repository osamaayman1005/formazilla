import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/shared_plan.dart';

/// Image card for a shared rotation or split. 360 logical pixels wide (1080px
/// at 3×); as tall as the plan needs, never shorter than a story.
class PlanShareCard extends StatelessWidget {
  const PlanShareCard({super.key, required this.plan});

  static const width = 360.0;

  final SharedPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 640),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/logo.png', width: 32, height: 32),
          ),
          const SizedBox(width: 10),
          const Text('FORMAZILLA',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2.4, color: AppColors.text)),
        ]),
        const SizedBox(height: 28),
        Text(plan.isSplit ? 'MY SPLIT' : 'MY WORKOUT',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.accentLight)),
        const SizedBox(height: 4),
        Text(plan.title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(plan.summary, style: AppText.caption),
        const SizedBox(height: 20),
        if (plan.isSplit)
          for (final day in plan.days)
            for (final r in day.rotations) _RotationBlock(title: rotationTitle(day.name, r.name), rotation: r)
        else
          _ExerciseList(rotation: plan.rotation),
        const SizedBox(height: 16),
        const Center(child: Text('Built with Formazilla', style: AppText.small)),
      ]),
    );
  }
}

/// Numbered list for a single shared rotation.
class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.rotation});

  final SharedRotation rotation;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < rotation.exercises.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.chip))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 26,
              child: Text('${i + 1}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentLight)),
            ),
            Expanded(
              child: Text(rotation.exercises[i],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text)),
            ),
            if (rotation.weights[rotation.exercises[i]] case final w? when w.isNotEmpty)
              Text(formatWeights(w), style: AppText.caption),
          ]),
        ),
    ]);
  }
}

/// One rotation of a shared split: title plus its exercises in a compact line.
class _RotationBlock extends StatelessWidget {
  const _RotationBlock({required this.title, required this.rotation});

  final String title;
  final SharedRotation rotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(
          rotation.exercises.isEmpty ? 'No exercises yet' : rotation.exercises.join(' · '),
          style: AppText.caption.copyWith(height: 1.5),
        ),
      ]),
    );
  }
}
