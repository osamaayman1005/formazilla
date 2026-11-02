import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/workout_logic.dart' show RecordCardData;

/// Story-sized (9:16) image card for a personal record. Laid out at 360×640
/// logical pixels; captured at 3× it becomes a 1080×1920 PNG.
class PrShareCard extends StatelessWidget {
  const PrShareCard({super.key, required this.data, required this.date, this.subtitle, this.prsToday});

  static const size = Size(360, 640);

  final RecordCardData data;
  final DateTime date;
  final String? subtitle;
  final int? prsToday;

  @override
  Widget build(BuildContext context) {
    final maxBar = data.recentTops.reduce((a, b) => a > b ? a : b);
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/logo.png', width: 40, height: 40),
          ),
          const SizedBox(width: 10),
          const Text('FORMAZILLA',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2.7, color: AppColors.text)),
        ]),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: const Text('NEW PERSONAL RECORD',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: AppColors.onAccent)),
        ),
        const SizedBox(height: 14),
        Text(data.exercise,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text)),
        FittedBox(
          child: Text(formatWeight(data.record),
              style: const TextStyle(
                  fontSize: 112, fontWeight: FontWeight.w800, letterSpacing: -4, height: 1.1, color: AppColors.text)),
        ),
        if (data.gain > 0)
          Text('+${formatWeight(data.gain)} since ${formatShortDate(data.since)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.accentLight)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Column(children: [
            SizedBox(
              height: 90,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < data.recentTops.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        height: maxBar <= 0 ? 4 : 84 * (data.recentTops[i] / maxBar).clamp(0.05, 1.0),
                        decoration: BoxDecoration(
                          color: i == data.recentTops.length - 1 ? AppColors.accentLight : AppColors.chip,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${data.recentTops.length} sessions', style: AppText.small.copyWith(fontSize: 11)),
              Text('Top set per session', style: AppText.small.copyWith(fontSize: 11)),
            ]),
          ]),
        ),
        const Spacer(),
        Row(children: [
          Expanded(
            child: Text(
              subtitle == null ? formatDayDate(date) : '${formatDayDate(date)} · $subtitle',
              style: AppText.small.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          if (prsToday != null && prsToday! > 1)
            Text('$prsToday PRs today',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentLight)),
        ]),
      ]),
    );
  }
}
