import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/set_chip.dart' show MiniSticker;
import '../widgets/store_scope.dart';

/// Every exercise you've logged, with its PR. Tap for the chart and history.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final q = exerciseKey(_query);
    final items = store.exerciseSummaries().where((e) => exerciseKey(e.name).contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xl),
      children: [
        const Text('Progress', style: AppText.title),
        const SizedBox(height: AppSpace.md),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: AppText.body,
          decoration: const InputDecoration(
            hintText: 'Search exercises',
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (items.isEmpty)
          const EmptyState(title: 'No progress yet', body: 'Finish a workout and your exercises show up here.')
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (final e in items)
                ListTile(
                  title: Text(e.name, style: AppText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Text(formatAgo(e.lastUsed, DateTime.now()), style: AppText.small),
                  trailing: Semantics(
                    label: 'Best ${formatWeight(e.record)}',
                    excludeSemantics: true,
                    child: MiniSticker(weight: e.record, width: 52, height: 54),
                  ),
                  onTap: () => openExercise(context, e.name),
                ),
            ]),
          ),
      ],
    );
  }
}
