import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/split_sheet.dart';
import '../widgets/store_scope.dart';

/// Edit the active split: rename it, add / rename / reorder / remove days.
class SplitDaysScreen extends StatefulWidget {
  const SplitDaysScreen({super.key});

  @override
  State<SplitDaysScreen> createState() => _SplitDaysScreenState();
}

class _SplitDaysScreenState extends State<SplitDaysScreen> {
  final _newDay = TextEditingController();

  @override
  void dispose() {
    _newDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final split = store.activeSplit;
    final days = store.days;

    return Scaffold(
      appBar: AppBar(
        title: Text(split.name),
        actions: [
          IconButton(
            tooltip: 'Rename split',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final name = await askText(context, title: 'Rename split', initial: split.name);
              if (name != null) store.renameSplit(split, name);
            },
          ),
          if (store.splits.length > 1)
            IconButton(
              tooltip: 'Remove split',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text('Remove ${split.name}?'),
                    content: const Text('Your workouts and PRs stay in History and Progress.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
                    ],
                  ),
                );
                if (ok == true && store.archiveSplit(split) && context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.sm),
            child: Text('Days run in this order, then start over. Drag to reorder, tap to rename, swipe to remove.',
                style: AppText.caption),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              buildDefaultDragHandles: false,
              itemCount: days.length,
              onReorderItem: store.reorderDays,
              itemBuilder: (context, i) {
                final day = days[i];
                final rotations = store.rotationsOf(day.id).length;
                return Dismissible(
                  key: ValueKey(day.id),
                  direction: days.length > 1 ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                  onDismissed: (_) {
                    store.archiveDay(day);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${day.name} removed. Past workouts keep their name.')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      onTap: () async {
                        final name = await askText(context, title: 'Rename day', initial: day.name);
                        if (name != null) store.renameDay(day, name);
                      },
                      child: Row(children: [
                        SizedBox(
                          width: 28,
                          child: Text('${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentLight)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(day.name, style: AppText.body),
                              Text(rotations == 1 ? '1 rotation' : '$rotations rotations', style: AppText.small),
                            ]),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle, color: AppColors.muted),
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.lg),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _newDay,
                  textCapitalization: TextCapitalization.words,
                  style: AppText.body,
                  decoration: const InputDecoration(hintText: 'New day, e.g. Arms'),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _add,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add day'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _add() {
    StoreScope.read(context).addDay(_newDay.text);
    _newDay.clear();
  }
}
