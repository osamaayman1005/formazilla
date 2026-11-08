/// Shows an AI's answer that was shared or pasted back. A plan in it is only
/// previewed: nothing changes until the user taps Add.
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/shared_plan.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart' show importSharedPlan;
import '../widgets/store_scope.dart';

class AiReplyScreen extends StatelessWidget {
  const AiReplyScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final found = readPlan(text);
    final plan = found == null ? null : store.withKnownNames(found);
    final broken = plan == null && hasPlanBlock(text);
    final body = stripPlanBlock(text);

    return Scaffold(
      appBar: AppBar(title: const Text('Your AI’s answer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
        children: [
          AppCard(
            child: SelectableText(body.isEmpty ? '(The answer only held a plan.)' : body,
                style: AppText.body.copyWith(height: 1.45)),
          ),
          const SizedBox(height: AppSpace.lg),
          if (plan != null)
            _PlanPreview(plan: plan)
          else
            Row(children: [
              Icon(broken ? Icons.error_outline : Icons.info_outline,
                  size: 20, color: broken ? AppColors.danger : AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  broken
                      ? 'The plan in this reply couldn’t be read. Ask your AI to resend just the formazilla block.'
                      : 'No plan in this reply.',
                  style: AppText.caption.copyWith(fontSize: 14),
                ),
              ),
            ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.md),
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(plan == null ? 'Done' : 'Dismiss'),
                ),
              ),
            ),
            if (plan != null) ...[
              const SizedBox(width: AppSpace.sm),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final added = await importSharedPlan(context, store, plan);
                      if (added && context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add this plan'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.plan});

  final SharedPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.accentLight,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome_outlined, size: 20, color: AppColors.accentLight),
          const SizedBox(width: 8),
          Expanded(child: Text('Plan in this answer', style: AppText.caption.copyWith(color: AppColors.accentLight))),
        ]),
        const SizedBox(height: 6),
        Text(plan.title, style: AppText.title),
        Text(plan.summary, style: AppText.caption),
        for (final d in plan.days)
          for (final r in d.rotations) ...[
            const SizedBox(height: AppSpace.md),
            Text(rotationTitle(d.name, r.name), style: AppText.section),
            const SizedBox(height: 4),
            for (final (i, e) in r.exercises.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 22, child: Text('${i + 1}', style: AppText.small)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        r.cardio.contains(e) ? '$e · cardio' : e,
                        style: AppText.body,
                      ),
                      if (r.weights[e]?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Pill('AI suggests ${formatWeights(r.weights[e]!)}',
                              outline: AppColors.line, color: AppColors.muted),
                        ),
                    ]),
                  ),
                ]),
              ),
            for (final p in r.supersets)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Superset: ${p.join(' + ')}', style: AppText.small.copyWith(color: AppColors.accentLight)),
              ),
          ],
        const SizedBox(height: AppSpace.md),
        const Text('Suggested weights are never logged. Your current split, history and PRs stay as they are.',
            style: AppText.small),
      ]),
    );
  }
}
