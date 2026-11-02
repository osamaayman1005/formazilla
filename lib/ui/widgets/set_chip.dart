import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'common.dart';
import 'kaiju.dart';
import 'motion.dart';

/// done   = logged set
/// ghost  = last time's value, tap to log it
/// record = logged set that beats the all-time PR
/// add    = "+" to add a set
enum ChipKind { done, ghost, record, add }

/// One set. Animates between kinds (a ghost "fills in" when logged), pops in
/// when [popIn] is set, and glows + thumps when it becomes a record.
class SetChip extends StatefulWidget {
  const SetChip({
    super.key,
    required this.kind,
    this.weight,
    this.dropSet = false,
    this.index,
    this.popIn = false,
    this.onTap,
    this.onLongPress,
  });

  final ChipKind kind;
  final double? weight;
  final bool dropSet;
  final int? index;

  /// True only for a set the user just logged.
  final bool popIn;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<SetChip> createState() => _SetChipState();
}

class _SetChipState extends State<SetChip> with TickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: Motion.base, value: widget.popIn ? 0 : 1);
  late final AnimationController _glow = AnimationController(vsync: this, duration: Motion.glow);
  late final CurvedAnimation _popCurve = CurvedAnimation(parent: _pop, curve: Motion.pop);

  @override
  void initState() {
    super.initState();
    if (widget.popIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Motion.reduced(context)) {
          _pop.value = 1;
        } else {
          _pop.forward();
        }
        if (widget.kind == ChipKind.record) _celebrate();
      });
    }
  }

  @override
  void didUpdateWidget(SetChip old) {
    super.didUpdateWidget(old);
    if (old.kind != ChipKind.record && widget.kind == ChipKind.record) _celebrate();
  }

  void _celebrate() {
    HapticFeedback.heavyImpact();
    if (!Motion.reduced(context)) _glow.forward(from: 0);
  }

  @override
  void dispose() {
    _popCurve.dispose();
    _pop.dispose();
    _glow.dispose();
    super.dispose();
  }

  String get _label => widget.kind == ChipKind.add ? '+' : formatWeight(widget.weight ?? 0);

  String get _semantics {
    final n = (widget.index ?? 0) + 1;
    final ds = widget.dropSet ? ', drop set' : '';
    return switch (widget.kind) {
      ChipKind.add => 'Add set',
      ChipKind.ghost => 'Last time $_label. Tap to log',
      ChipKind.record => 'Set $n, $_label, new personal record$ds',
      ChipKind.done => 'Set $n, $_label$ds',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color textColor, Color outline) = switch (widget.kind) {
      ChipKind.done => (AppColors.chip, AppColors.text, Colors.transparent),
      ChipKind.record => (AppColors.accent, AppColors.onAccent, Colors.transparent),
      ChipKind.ghost => (Colors.transparent, AppColors.muted, Colors.transparent),
      ChipKind.add => (Colors.transparent, AppColors.accentLight, AppColors.line),
    };
    final fast = Motion.of(context, Motion.fast);
    final radius = BorderRadius.circular(AppRadius.chip);

    Widget body = AnimatedContainer(
      duration: fast,
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, borderRadius: radius, border: Border.all(color: outline, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedDefaultTextStyle(
            duration: fast,
            style: AppText.chip.copyWith(color: textColor),
            child: Text(_label),
          ),
          if (widget.dropSet)
            Padding(
              padding: const EdgeInsets.only(left: 3, bottom: 2),
              child: Text('ds', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
            ),
        ],
      ),
    );

    // Dashed outline fades out as a ghost becomes a logged set.
    body = TweenAnimationBuilder<double>(
      tween: Tween(end: widget.kind == ChipKind.ghost ? 1 : 0),
      duration: fast,
      builder: (_, v, child) => CustomPaint(
        foregroundPainter: v > 0 ? DashedPainter(AppRadius.chip, AppColors.line.withValues(alpha: v)) : null,
        child: child,
      ),
      child: body,
    );

    // PR glow: a ring that grows and fades.
    body = AnimatedBuilder(
      animation: _glow,
      builder: (_, child) {
        final t = _glow.value;
        final on = _glow.isAnimating;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: on
                ? [BoxShadow(color: AppColors.accentLight.withValues(alpha: 0.8 * (1 - t)), spreadRadius: 14 * t)]
                : const [],
          ),
          // Claw scratches draw across the chip, then fade.
          child: CustomPaint(
            foregroundPainter: on
                ? ClawPainter(
                    color: AppColors.onAccent.withValues(alpha: 0.9 * (1 - t)),
                    progress: (t * 2.5).clamp(0.0, 1.0),
                  )
                : null,
            child: child,
          ),
        );
      },
      child: body,
    );

    return Semantics(
      button: true,
      label: _semantics,
      excludeSemantics: true,
      child: ScaleTransition(
        scale: _popCurve,
        child: FadeTransition(
          opacity: _pop,
          child: Material(
            color: Colors.transparent,
            child: InkWell(borderRadius: radius, onTap: widget.onTap, onLongPress: widget.onLongPress, child: body),
          ),
        ),
      ),
    );
  }
}
