import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/store_scope.dart';

/// Days and their rotas. Days cycle Push → Pull → Legs; rotas alternate A → B.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xl),
      children: [
        const Text('Templates', style: AppText.title),
        const SizedBox(height: 2),
        const Text('Days cycle in order. Rotas alternate A → B. Long-press a rota for more.', style: AppText.caption),
        const SizedBox(height: AppSpace.md),
        for (final day in store.days) ...[
          Row(children: [
            Expanded(child: Text(day.name, style: AppText.section)),
            TextButton.icon(
              onPressed: () {
                final r = store.addRota(day.id);
                openRota(context, r);
              },
              icon: const Icon(Icons.add, size: 18, color: AppColors.accentLight),
              label: const Text('Add rota', style: TextStyle(color: AppColors.accentLight)),
            ),
          ]),
          for (final rota in store.rotasOf(day.id))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _RotaCard(store: store, rota: rota),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

class _RotaCard extends StatelessWidget {
  const _RotaCard({required this.store, required this.rota});

  final AppStore store;
  final Rota rota;

  @override
  Widget build(BuildContext context) {
    final preview = rota.exercises.take(3).join(', ');
    final more = rota.exercises.length > 3 ? ' +${rota.exercises.length - 3}' : '';
    return GestureDetector(
      onLongPress: () => _actions(context),
      child: AppCard(
        onTap: () => openRota(context, rota),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(store.rotaLabel(rota.dayId, rota.id), style: AppText.cardTitle)),
            if (rota.isStarter) const Pill('Starter', outline: AppColors.line, fontSize: 11),
          ]),
          const SizedBox(height: 4),
          Text(rota.exercises.isEmpty ? 'Empty — tap to add exercises' : '$preview$more', style: AppText.caption),
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
        final name = await _askName(context, rota.name);
        if (name != null) store.renameRota(rota, name);
      case 'duplicate':
        store.duplicateRota(rota);
      case 'delete':
        if (!store.deleteRota(rota) && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A day needs at least one rota')),
          );
        }
    }
  }

  Future<String?> _askName(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rota name'),
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
