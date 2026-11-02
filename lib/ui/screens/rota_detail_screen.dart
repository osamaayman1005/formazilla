import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/exercise_input.dart';
import '../widgets/store_scope.dart';

/// Edit one rota: reorder (drag), remove (swipe), add exercises, start it.
class RotaDetailScreen extends StatelessWidget {
  const RotaDetailScreen({super.key, required this.rotaId});

  final String rotaId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final rota = store.rotaById(rotaId);
    if (rota == null) {
      return const Scaffold(body: Center(child: Text('Rota deleted', style: AppText.caption)));
    }
    final label = store.rotaLabel(rota.dayId, rota.id);
    final inRota = rota.exercises.map(exerciseKey).toSet();
    final quickAdd = store.library.where((n) => !inRota.contains(exerciseKey(n))).take(6).toList();

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: rota.exercises.isEmpty
                ? const EmptyState(title: 'No exercises yet', body: 'Add exercises below. Drag to reorder, swipe to remove.')
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                    buildDefaultDragHandles: false,
                    itemCount: rota.exercises.length,
                    onReorder: (from, to) => store.reorderRotaExercise(rota, from, to),
                    itemBuilder: (context, i) {
                      final name = rota.exercises[i];
                      return Dismissible(
                        key: ValueKey('$i-$name'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline, color: AppColors.danger),
                        ),
                        onDismissed: (_) => store.removeRotaExercise(rota, i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            child: Row(children: [
                              SizedBox(
                                width: 28,
                                child: Text('${i + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentLight)),
                              ),
                              Expanded(child: Text(name, style: AppText.body)),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExerciseInput(search: store.searchLibrary, onSubmit: (n) => store.addRotaExercise(rota, n)),
              const SizedBox(height: AppSpace.sm),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final n in quickAdd)
                  ActionChip(
                    label: Text('+ $n'),
                    backgroundColor: AppColors.card,
                    side: BorderSide.none,
                    onPressed: () => store.addRotaExercise(rota, n),
                  ),
              ]),
              const SizedBox(height: AppSpace.md),
              PrimaryButton('Start $label', onPressed: () {
                final active = store.activeSession;
                if (active != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Finish your current workout first'),
                    action: SnackBarAction(label: 'Resume', onPressed: () => openSession(context, active)),
                  ));
                  return;
                }
                openSession(context, store.startSession(rota), replace: true);
              }),
            ]),
          ),
        ]),
      ),
    );
  }
}
