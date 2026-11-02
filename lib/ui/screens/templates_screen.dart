import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/split_sheet.dart';
import '../widgets/store_scope.dart';

/// The active split: its days (in cycle order) and each day's rotations.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xl),
      children: [
        const Text('Templates', style: AppText.title),
        const SizedBox(height: AppSpace.md),
        _SplitHeader(store: store),
        const SizedBox(height: AppSpace.sm),
        const Text('Days run in order, then start over. Rotations alternate A → B. Long-press a rotation for more.',
            style: AppText.caption),
        const SizedBox(height: AppSpace.md),
        for (final day in store.days) ...[
          Row(children: [
            Expanded(child: Text(day.name, style: AppText.section)),
            TextButton.icon(
              onPressed: () {
                final r = store.addRotation(day.id);
                openRotation(context, r);
              },
              icon: const Icon(Icons.add, size: 18, color: AppColors.accentLight),
              label: const Text('Add rotation', style: TextStyle(color: AppColors.accentLight)),
            ),
          ]),
          for (final rotation in store.rotationsOf(day.id))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _RotationCard(store: store, rotation: rotation),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

/// Active split name with Switch and Edit days.
class _SplitHeader extends StatelessWidget {
  const _SplitHeader({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final split = store.activeSplit;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Split', style: AppText.small),
            Text(split.name, style: AppText.cardTitle.copyWith(fontSize: 18)),
            Text('${store.days.length} days', style: AppText.small),
          ]),
        ),
        TextButton(
          onPressed: () => showSplitSwitcher(context, store),
          child: const Text('Switch', style: TextStyle(color: AppColors.accentLight)),
        ),
        TextButton(
          onPressed: () => openSplitDays(context),
          child: const Text('Edit days', style: TextStyle(color: AppColors.accentLight)),
        ),
      ]),
    );
  }
}

class _RotationCard extends StatelessWidget {
  const _RotationCard({required this.store, required this.rotation});

  final AppStore store;
  final Rotation rotation;

  @override
  Widget build(BuildContext context) {
    final preview = rotation.exercises.take(3).join(', ');
    final more = rotation.exercises.length > 3 ? ' +${rotation.exercises.length - 3}' : '';
    return GestureDetector(
      onLongPress: () => _actions(context),
      child: AppCard(
        onTap: () => openRotation(context, rotation),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(store.rotationLabel(rotation.dayId, rotation.id), style: AppText.cardTitle)),
            if (rotation.isStarter) const Pill('Starter', outline: AppColors.line, fontSize: 11),
          ]),
          const SizedBox(height: 4),
          Text(rotation.exercises.isEmpty ? 'Empty — tap to add exercises' : '$preview$more', style: AppText.caption),
        ]),
      ),
    );
  }

  Future<void> _actions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Rename'), onTap: () => Navigator.pop(c, 'rename')),
          ListTile(leading: const Icon(Icons.copy_outlined), title: const Text('Duplicate'), onTap: () => Navigator.pop(c, 'duplicate')),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
            onTap: () => Navigator.pop(c, 'delete'),
          ),
        ]),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'rename':
        final name = await _askName(context, rotation.name);
        if (name != null) store.renameRotation(rotation, name);
      case 'duplicate':
        store.duplicateRotation(rotation);
      case 'delete':
        if (!store.deleteRotation(rotation) && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A day needs at least one rotation')),
          );
        }
    }
  }

  Future<String?> _askName(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rotation name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'A, B, Heavy, Volume…'),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }
}
