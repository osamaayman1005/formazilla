import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/store_scope.dart';

/// Home: pick a day and rota (pre-selected from history, never forced) and start.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// null = follow the suggestion.
  String? _dayId;
  String? _rotaId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final suggested = store.suggestedDay;
    final days = store.days;
    final dayId = days.any((d) => d.id == _dayId) ? _dayId! : suggested.id;
    final rotas = store.rotasOf(dayId);
    final rota = rotas.where((r) => r.id == _rotaId).firstOrNull ?? store.suggestedRota(dayId);
    final active = store.activeSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xl),
      children: [
        Text(formatDayDate(DateTime.now()), style: AppText.caption),
        const SizedBox(height: 2),
        const Text('Ready to train?', style: AppText.title),
        const SizedBox(height: AppSpace.xl),
        if (active != null)
          _ResumeCard(store: store, session: active)
        else ...[
          const SectionLabel('Day'),
          _DaySwitcher(
            days: days,
            selectedId: dayId,
            suggestedId: suggested.id,
            lastDone: store.lastDoneAt,
            onSelect: (id) => setState(() {
              _dayId = id;
              _rotaId = null;
            }),
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionLabel('Rota'),
          _RotaPicker(
            rotas: rotas,
            selected: rota,
            suggested: store.suggestedRota(dayId),
            onSelect: (r) => setState(() => _rotaId = r.id),
          ),
          const SizedBox(height: AppSpace.lg),
          if (rota != null) _StartCard(store: store, rota: rota),
          const SizedBox(height: AppSpace.sm),
          Text(
            dayId == suggested.id
                ? 'Suggested from your last workout. Tap any day or rota to switch.'
                : 'You picked ${store.dayById(dayId)?.name}. ${suggested.name} is still suggested.',
            style: AppText.small,
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        _RecentRecords(store: store),
      ],
    );
  }
}

class _DaySwitcher extends StatelessWidget {
  const _DaySwitcher({
    required this.days,
    required this.selectedId,
    required this.suggestedId,
    required this.lastDone,
    required this.onSelect,
  });

  final List<Day> days;
  final String selectedId;
  final String suggestedId;
  final DateTime? Function(String dayId) lastDone;
  final ValueChanged<String> onSelect;

  String _subtitle(Day d) {
    if (d.id == suggestedId) return 'Suggested';
    final last = lastDone(d.id);
    if (last == null) return 'Not yet';
    final ago = formatAgo(last, DateTime.now());
    return ago == 'Yesterday' || ago == 'Today' ? '$ago ✓' : ago;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < days.length; i++) ...[
        if (i > 0) const SizedBox(width: AppSpace.sm),
        Expanded(child: _dayButton(days[i])),
      ],
    ]);
  }

  Widget _dayButton(Day d) {
    final selected = d.id == selectedId;
    final suggested = d.id == suggestedId;
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d.name,
            style: AppText.cardTitle.copyWith(fontSize: 18, color: selected ? AppColors.onAccent : AppColors.text)),
        const SizedBox(height: 2),
        Text(_subtitle(d),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.small.copyWith(
              color: selected || suggested ? AppColors.accentLight : AppColors.muted,
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
    Widget box = Material(
      color: selected ? AppColors.accent : AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => onSelect(d.id),
        child: content,
      ),
    );
    if (suggested && !selected) {
      box = DashedBorder(radius: AppRadius.card, color: AppColors.accentLight, child: box);
    }
    return Semantics(selected: selected, label: '${d.name}, ${_subtitle(d)}', child: box);
  }
}

class _RotaPicker extends StatelessWidget {
  const _RotaPicker({required this.rotas, required this.selected, required this.suggested, required this.onSelect});

  final List<Rota> rotas;
  final Rota? selected;
  final Rota? suggested;
  final ValueChanged<Rota> onSelect;

  @override
  Widget build(BuildContext context) {
    if (rotas.length <= 1) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Pill('One rota · used every time', fill: AppColors.card, fontSize: 13),
      );
    }
    final index = rotas.indexWhere((r) => r.id == selected?.id);
    return Row(children: [
      Segmented(
        options: [for (final r in rotas) r.name.isEmpty ? '•' : r.name],
        selected: index < 0 ? 0 : index,
        onChanged: (i) => onSelect(rotas[i]),
      ),
      const SizedBox(width: AppSpace.md),
      if (suggested != null)
        Expanded(child: Text('${suggested!.name} is next', style: AppText.small, textAlign: TextAlign.right)),
    ]);
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.store, required this.rota});

  final AppStore store;
  final Rota rota;

  @override
  Widget build(BuildContext context) {
    final label = store.rotaLabel(rota.dayId, rota.id);
    final preview = rota.exercises.take(4).join(', ');
    final more = rota.exercises.length > 4 ? ' +${rota.exercises.length - 4}' : '';
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.display),
        const SizedBox(height: 4),
        Text(rota.exercises.isEmpty ? 'No exercises yet — add them as you go' : '$preview$more',
            style: AppText.caption),
        const SizedBox(height: AppSpace.lg),
        PrimaryButton('Start $label', onPressed: () {
          final s = store.startSession(rota);
          openSession(context, s);
        }),
      ]),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.store, required this.session});

  final AppStore store;
  final Session session;

  @override
  Widget build(BuildContext context) {
    final label = store.rotaLabel(session.dayId, session.rotaId);
    final mins = DateTime.now().difference(session.startedAt).inMinutes;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('In progress · $mins min', style: AppText.caption.copyWith(color: AppColors.accentLight)),
        const SizedBox(height: 4),
        Text(label, style: AppText.display.copyWith(color: AppColors.onAccent)),
        Text('${session.setCount} sets logged', style: AppText.body.copyWith(color: AppColors.onAccent)),
        const SizedBox(height: AppSpace.lg),
        PrimaryButton('Resume $label', inverted: true, onPressed: () => openSession(context, session)),
        const SizedBox(height: AppSpace.xs),
        Center(
          child: TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Discard this workout?'),
                  content: const Text('Logged sets in it will be deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
                  ],
                ),
              );
              if (ok == true) store.discardSession(session);
            },
            child: const Text('Discard', style: TextStyle(color: AppColors.accentLight)),
          ),
        ),
      ]),
    );
  }
}

class _RecentRecords extends StatelessWidget {
  const _RecentRecords({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final records = store.recentRecords();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recent PRs', style: AppText.section),
      const SizedBox(height: AppSpace.sm),
      if (records.isEmpty)
        const AppCard(child: Text('Beat a previous best and it shows up here.', style: AppText.caption))
      else
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            for (final r in records)
              ListTile(
                dense: true,
                title: Text(r.exercise, style: AppText.body),
                onTap: () => openExercise(context, r.exercise),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('+${formatWeight(r.delta)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accentLight)),
                  const SizedBox(width: AppSpace.sm),
                  Text(formatWeight(r.weight), style: AppText.body.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
    ]);
  }
}
