/// Bottom sheets to switch the active split or create a new one from a preset.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/seed.dart';
import '../../state/app_store.dart';
import 'common.dart';

/// Lists your splits; tap one to make it active. "+ New split" opens presets.
Future<void> showSplitSwitcher(BuildContext context, AppStore store) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your splits', style: AppText.title),
          const SizedBox(height: 4),
          const Text('Switching keeps all history and PRs.', style: AppText.caption),
          const SizedBox(height: AppSpace.md),
          for (final split in store.splits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: AppCard(
                borderColor: split.id == store.activeSplit.id ? AppColors.accentLight : null,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  store.setActiveSplit(split);
                  Navigator.pop(c);
                },
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(split.name, style: AppText.cardTitle),
                      const SizedBox(height: 2),
                      Text(store.daysOf(split.id).map((d) => d.name).join(' · '),
                          style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  if (split.id == store.activeSplit.id)
                    const Icon(Icons.check_circle, color: AppColors.accentLight)
                  else
                    const Icon(Icons.radio_button_off, color: AppColors.muted),
                ]),
              ),
            ),
          const SizedBox(height: AppSpace.xs),
          DashedButton('+ New split', onPressed: () async {
            Navigator.pop(c);
            await showNewSplitSheet(context, store);
          }),
        ]),
      ),
    ),
  );
}

/// Preset picker: Push Pull Legs, Upper / Lower, Full body, Bro split, Arnold, Custom.
Future<void> showNewSplitSheet(BuildContext context, AppStore store) async {
  const custom = 'Custom';
  final preset = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.lg),
          children: [
            const Text('New split', style: AppText.title),
            const SizedBox(height: 4),
            const Text('Start from a preset, then edit anything.', style: AppText.caption),
            const SizedBox(height: AppSpace.md),
            for (final name in [...splitPresets.keys, custom])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: () => Navigator.pop(c, name),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: AppText.cardTitle),
                        const SizedBox(height: 2),
                        Text(name == custom ? 'Start empty and add your own days' : presetSummary(name),
                            style: AppText.caption),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ]),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  if (preset == null || !context.mounted) return;
  String? name;
  if (preset == custom) {
    name = await askText(context, title: 'Name your split', hint: 'Upper Lower, PHUL, My split…');
    if (name == null || name.trim().isEmpty) return;
  }
  store.createSplit(preset, name: name);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to ${store.activeSplit.name}')),
    );
  }
}

/// Small text prompt used for naming splits and days.
Future<String?> askText(BuildContext context, {required String title, String? initial, String? hint}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(c, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, controller.text), child: const Text('Save')),
      ],
    ),
  );
}
