/// Share a rotation or the whole split, and import a plan a friend shared.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/shared_plan.dart';
import '../../state/app_store.dart';
import '../navigation.dart';
import 'common.dart';

enum ShareFormat { image, plan, text }

/// Pick what (this rotation / whole split) and how (image / plan / text).
/// Without a [rotation] it shares the whole split.
Future<void> showShareSheet(BuildContext context, AppStore store, {Rotation? rotation}) {
  var wholeSplit = rotation == null;
  var format = ShareFormat.image;
  var weights = false;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Share', style: AppText.title),
            const SizedBox(height: AppSpace.md),
            if (rotation != null) ...[
              const SectionLabel('What'),
              SizedBox(
                width: double.infinity,
                child: Segmented(
                  options: [store.rotationLabel(rotation.dayId, rotation.id), 'Whole split'],
                  selected: wholeSplit ? 1 : 0,
                  onChanged: (i) => setState(() => wholeSplit = i == 1),
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
            const SectionLabel('How'),
            _Choice(
              title: 'Image card',
              subtitle: 'For stories and the gym group',
              selected: format == ShareFormat.image,
              onTap: () => setState(() => format = ShareFormat.image),
            ),
            _Choice(
              title: 'Formazilla plan',
              subtitle: 'A friend imports it in one tap',
              selected: format == ShareFormat.plan,
              onTap: () => setState(() => format = ShareFormat.plan),
            ),
            _Choice(
              title: 'Plain text',
              subtitle: 'A readable list for WhatsApp',
              selected: format == ShareFormat.text,
              onTap: () => setState(() => format = ShareFormat.text),
            ),
            if (format != ShareFormat.plan)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: weights,
                onChanged: (v) => setState(() => weights = v),
                title: const Text('Include my last weights', style: AppText.body),
              ),
            const SizedBox(height: AppSpace.sm),
            PrimaryButton('Share', onPressed: () {
              final plan = wholeSplit || rotation == null
                  ? store.planForSplit(weights: weights && format != ShareFormat.plan)
                  : store.planForRotation(rotation, weights: weights && format != ShareFormat.plan);
              Navigator.pop(c);
              _share(context, plan, format);
            }),
          ]),
        ),
      ),
    ),
  );
}

Future<void> _share(BuildContext context, SharedPlan plan, ShareFormat format) async {
  switch (format) {
    case ShareFormat.image:
      await openPlanCard(context, plan);
    case ShareFormat.plan:
      await SharePlus.instance.share(ShareParams(text: planMessage(plan, withCode: true)));
    case ShareFormat.text:
      await SharePlus.instance.share(ShareParams(text: planMessage(plan)));
  }
}

/// Reads a shared plan from the clipboard and asks where to add it.
Future<void> importPlanFromClipboard(BuildContext context, AppStore store) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final plan = readPlan(data?.text);
  if (!context.mounted) return;
  if (plan == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('No plan found. Copy the whole Formazilla message from the chat, then tap Import.'),
    ));
    return;
  }

  // Where a single rotation can go: a day with the same name first.
  final days = store.days;
  final sameName = plan.isSplit
      ? null
      : days.where((d) => d.name.toLowerCase() == plan.days.first.name.toLowerCase()).firstOrNull;
  // Choice: a Day, 'split' (new split) or 'replace' (new split, archive current).
  Object choice = plan.isSplit ? 'split' : (sameName ?? 'split');

  final result = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Import plan', style: AppText.title),
            const SizedBox(height: AppSpace.md),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan.title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(plan.summary, style: AppText.caption),
                const SizedBox(height: 6),
                Text(
                  plan.isSplit
                      ? plan.days.map((d) => d.name).join(' · ')
                      : plan.rotation.exercises.take(4).join(', ') +
                          (plan.rotation.exercises.length > 4 ? ' +${plan.rotation.exercises.length - 4}' : ''),
                  style: AppText.small,
                ),
              ]),
            ),
            const SizedBox(height: AppSpace.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.4),
              child: SingleChildScrollView(
                child: Column(children: [
                  if (!plan.isSplit)
                    for (final d in days)
                      _Choice(
                        title: 'Add to my ${d.name} day',
                        subtitle: 'As a new rotation next to the ones you have',
                        selected: choice == d,
                        onTap: () => setState(() => choice = d),
                      ),
                  _Choice(
                    title: 'Add as a new split',
                    subtitle: 'Switches to it; your current split stays',
                    selected: choice == 'split',
                    onTap: () => setState(() => choice = 'split'),
                  ),
                  if (plan.isSplit)
                    _Choice(
                      title: 'Replace ${store.activeSplit.name}',
                      subtitle: 'Your workouts and PRs stay in History',
                      selected: choice == 'replace',
                      onTap: () => setState(() => choice = 'replace'),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            PrimaryButton('Import', onPressed: () => Navigator.pop(c, choice)),
          ]),
        ),
      ),
    ),
  );
  if (result == null || !context.mounted) return;

  final String message;
  if (result is Day) {
    final r = store.importIntoDay(plan, result);
    message = '${plan.title} added as ${store.rotationLabel(result.id, r.id)}';
  } else {
    final split = store.importAsSplit(plan, replace: result == 'replace');
    message = '${split.name} added and active';
  }
  HapticFeedback.mediumImpact();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// A radio-style option card.
class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.subtitle, required this.selected, required this.onTap});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? AppColors.accentLight : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.accentLight : AppColors.muted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppText.small),
            ]),
          ),
        ]),
      ),
    );
  }
}
