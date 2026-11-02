import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'common.dart';

/// done   = logged set
/// ghost  = last time's value, tap to log it
/// record = logged set that beats the all-time PR
/// add    = "+" to add a set
enum ChipKind { done, ghost, record, add }

class SetChip extends StatelessWidget {
  const SetChip({
    super.key,
    required this.kind,
    this.weight,
    this.dropSet = false,
    this.index,
    this.onTap,
    this.onLongPress,
  });

  final ChipKind kind;
  final double? weight;
  final bool dropSet;
  final int? index;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  String get _label => kind == ChipKind.add ? '+' : formatWeight(weight ?? 0);

  String get _semantics => switch (kind) {
        ChipKind.add => 'Add set',
        ChipKind.ghost => 'Last time $_label. Tap to log',
        ChipKind.record => 'Set ${(index ?? 0) + 1}, $_label, new personal record${dropSet ? ', drop set' : ''}',
        ChipKind.done => 'Set ${(index ?? 0) + 1}, $_label${dropSet ? ', drop set' : ''}',
      };

  @override
  Widget build(BuildContext context) {
    final (Color? fill, Color textColor, bool outline) = switch (kind) {
      ChipKind.done => (AppColors.chip, AppColors.text, false),
      ChipKind.record => (AppColors.accent, AppColors.onAccent, false),
      ChipKind.ghost => (null, AppColors.muted, false),
      ChipKind.add => (null, AppColors.accentLight, true),
    };

    Widget body = Container(
      constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: outline ? Border.all(color: AppColors.line, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_label, style: AppText.chip.copyWith(color: textColor)),
          if (dropSet)
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 2),
              child: Text('ds', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
            ),
        ],
      ),
    );
    if (kind == ChipKind.ghost) body = DashedBorder(child: body);

    return Semantics(
      button: true,
      label: _semantics,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          onLongPress: onLongPress,
          child: body,
        ),
      ),
    );
  }
}
