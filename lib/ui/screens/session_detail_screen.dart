import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/store_scope.dart';

/// Read-only view of a finished workout, with delete.
class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final s = store.sessionById(sessionId);
    if (s == null) {
      return const Scaffold(body: Center(child: Text('Workout deleted', style: AppText.caption)));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(store.rotationLabel(s.dayId, s.rotationId)),
        actions: [
          IconButton(
            tooltip: 'Delete workout',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete this workout?'),
                  content: const Text('PRs are recalculated without it.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.of(context).pop();
                store.deleteSession(sessionId);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
        children: [
          Text(
            '${formatDayDate(s.startedAt)} · ${s.finishedAt == null ? 'in progress' : formatDuration(s.finishedAt!.difference(s.startedAt))} · ${s.setCount} sets',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpace.md),
          for (final e in s.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: AppCard(
                onTap: () => openExercise(context, e.name),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (e.cardio) ...[
                      const Icon(Icons.monitor_heart_outlined, color: AppColors.accentLight, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Expanded(child: Text(e.name, style: AppText.cardTitle)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    e.cardio
                        ? '${formatWeight(e.minutes ?? 0)} min'
                        : e.sets.map((x) => '${formatWeight(x.weight)}${x.dropSet ? 'ds' : ''}').join(' · '),
                    style: AppText.body,
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
