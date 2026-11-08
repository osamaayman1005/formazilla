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

enum ShareFormat { qr, image, plan, text }

/// Pick what (this rotation / whole split) and how (image / plan / text).
/// Without a [rotation] it shares the whole split.
Future<void> showShareSheet(BuildContext context, AppStore store, {Rotation? rotation}) {
  var wholeSplit = rotation == null;
  var format = ShareFormat.qr;
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
              title: 'QR code',
              subtitle: 'Friend next to you scans it',
              selected: format == ShareFormat.qr,
              onTap: () => setState(() => format = ShareFormat.qr),
            ),
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
            if (format == ShareFormat.image || format == ShareFormat.text)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: weights,
                onChanged: (v) => setState(() => weights = v),
                title: const Text('Include my last weights', style: AppText.body),
              ),
            const SizedBox(height: AppSpace.sm),
            PrimaryButton(format == ShareFormat.qr ? 'Show QR' : 'Share', onPressed: () {
              final withWeights = weights && (format == ShareFormat.image || format == ShareFormat.text);
              final plan = wholeSplit || rotation == null
                  ? store.planForSplit(weights: withWeights)
                  : store.planForRotation(rotation, weights: withWeights);
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
    case ShareFormat.qr:
      await openPlanQr(context, plan);
    case ShareFormat.image:
      await openPlanCard(context, plan);
    case ShareFormat.plan:
      await SharePlus.instance.share(ShareParams(text: planMessage(plan, withCode: true)));
    case ShareFormat.text:
      await SharePlus.instance.share(ShareParams(text: planMessage(plan)));
  }
}

/// Import plan: scan a friend's QR, or paste a copied Formazilla message.
Future<void> showImportOptions(BuildContext context, AppStore store) async {
  final how = await showModalBottomSheet<String>(
    context: context,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Import plan', style: AppText.title),
          const SizedBox(height: AppSpace.md),
          _Choice(
            title: 'Scan QR code',
            subtitle: 'From a friend’s screen',
            icon: Icons.qr_code_scanner,
            onTap: () => Navigator.pop(c, 'scan'),
          ),
          _Choice(
            title: 'Paste from chat',
            subtitle: 'You copied a Formazilla message',
            icon: Icons.content_paste,
            onTap: () => Navigator.pop(c, 'paste'),
          ),
        ]),
      ),
    ),
  );
  if (how == null || !context.mounted) return;
  if (how == 'scan') {
    final text = await scanPlanQr(context);
    if (text == null || !context.mounted) return;
    await importSharedPlan(context, store, readPlan(text));
  } else {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    await importSharedPlan(context, store, readPlan(data?.text));
  }
}

/// Asks where a shared plan goes, then adds it. True when it was added.
Future<bool> importSharedPlan(BuildContext context, AppStore store, SharedPlan? plan) async {
  if (plan == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('No plan found. Copy the whole Formazilla message from the chat, then tap Import.'),
    ));
    return false;
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
  if (result == null || !context.mounted) return false;

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
  return true;
}

/// A radio-style option card (or, with [icon], a plain tappable row).
class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.subtitle, this.selected = false, required this.onTap, this.icon});

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
            icon ?? (selected ? Icons.radio_button_checked : Icons.radio_button_off),
            color: selected || icon != null ? AppColors.accentLight : AppColors.muted,
            size: icon != null ? 24 : 20,
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
