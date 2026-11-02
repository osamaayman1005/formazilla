import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/store_scope.dart';

/// Past workouts, newest first, plus backup (copy / paste JSON).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final sessions = store.history;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xl),
      children: [
        Row(children: [
          const Expanded(child: Text('History', style: AppText.title)),
          PopupMenuButton<String>(
            tooltip: 'Backup',
            icon: const Icon(Icons.save_alt, color: AppColors.muted),
            color: AppColors.chip,
            onSelected: (v) => v == 'export' ? _export(context, store) : _import(context, store),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export backup (copy)')),
              PopupMenuItem(value: 'import', child: Text('Import backup (paste)')),
            ],
          ),
        ]),
        const SizedBox(height: AppSpace.md),
        if (sessions.isEmpty)
          const EmptyState(title: 'No workouts yet', body: 'Finished workouts show up here.')
        else
          for (final s in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: AppCard(
                onTap: () => openSessionDetail(context, s),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.rotationLabel(s.dayId, s.rotationId), style: AppText.cardTitle),
                      const SizedBox(height: 2),
                      Text(
                        '${formatDayDate(s.finishedAt!)} · ${formatDuration(s.finishedAt!.difference(s.startedAt))}',
                        style: AppText.caption,
                      ),
                    ]),
                  ),
                  Text('${s.setCount} sets', style: AppText.caption),
                ]),
              ),
            ),
      ],
    );
  }

  Future<void> _export(BuildContext context, AppStore store) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup copied. Paste it into a note or chat to keep it safe.')),
      );
    }
  }

  Future<void> _import(BuildContext context, AppStore store) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Import backup'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This replaces all current data.', style: AppText.caption),
          const SizedBox(height: AppSpace.sm),
          TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: 'Paste backup here')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, controller.text), child: const Text('Replace data')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    try {
      store.importJson(text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored')));
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That doesn’t look like a Formazilla backup')));
    }
  }
}
