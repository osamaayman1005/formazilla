import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'common.dart';
import 'motion.dart';

/// done   = logged set: a white paper sticker
/// ghost  = last time's value printed in an empty slot, tap to log it
/// record = logged set that beats the all-time PR: a foil sticker
/// add    = dashed slot, opens a clean keypad
enum ChipKind { done, ghost, record, add }

/// Slot size in the album row.
const stickerWidth = 58.0;
const stickerHeight = 64.0;

/// One set, drawn as an album sticker. A newly logged sticker lands tilted and
/// settles flat ([popIn]); a record lands as foil with a stronger buzz.
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

class _SetChipState extends State<SetChip> with SingleTickerProviderStateMixin {
  late final AnimationController _land =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: widget.popIn ? 0 : 1);
  late final CurvedAnimation _curve = CurvedAnimation(parent: _land, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.popIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Motion.reduced(context)) {
          _land.value = 1;
        } else {
          _land.forward();
        }
        if (widget.kind == ChipKind.record) HapticFeedback.heavyImpact();
      });
    }
  }

  @override
  void didUpdateWidget(SetChip old) {
    super.didUpdateWidget(old);
    if (old.kind != ChipKind.record && widget.kind == ChipKind.record) HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _curve.dispose();
    _land.dispose();
    super.dispose();
  }

  String get _label => formatWeight(widget.weight ?? 0);

  String get _semantics {
    final n = (widget.index ?? 0) + 1;
    final ds = widget.dropSet ? ', drop set' : '';
    return switch (widget.kind) {
      ChipKind.add => 'Log a new weight',
      ChipKind.ghost => 'Log set $n at $_label, same as last time',
      ChipKind.record => 'Set $n, $_label, new personal record$ds. Edit',
      ChipKind.done => 'Set $n, $_label$ds. Edit',
    };
  }

  Widget _caption(Color color) {
    if (widget.dropSet) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.arrow_downward, size: 10, color: color),
        const SizedBox(width: 2),
        Text('drop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]);
    }
    final text = widget.kind == ChipKind.record ? 'PR' : 'set ${(widget.index ?? 0) + 1}';
    return Text(text,
        style: TextStyle(
            fontSize: 11, fontWeight: widget.kind == ChipKind.record ? FontWeight.w700 : FontWeight.w500, color: color));
  }

  Widget _number(Color color) {
    final long = _label.length > 3;
    return Text(_label, style: AppText.sticker.copyWith(color: color, fontSize: long ? 20 : 24));
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.sticker);
    final Widget face = switch (widget.kind) {
      ChipKind.done => Container(
          decoration: BoxDecoration(color: AppColors.paper, borderRadius: radius),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _number(AppColors.paperInk),
            const SizedBox(height: 4),
            _caption(AppColors.paperCaption),
          ]),
        ),
      ChipKind.record => FoilFace(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _number(AppColors.onAccent),
            const SizedBox(height: 4),
            _caption(AppColors.onBand),
          ]),
        ),
      ChipKind.ghost => Container(
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: AppColors.line, width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_label, style: AppText.sticker.copyWith(color: AppColors.muted, fontWeight: FontWeight.w700,
                fontSize: _label.length > 3 ? 20 : 24)),
            const SizedBox(height: 4),
            _caption(AppColors.muted),
          ]),
        ),
      ChipKind.add => const DashedBorder(
          radius: AppRadius.sticker,
          child: Center(child: Icon(Icons.add, size: 26, color: AppColors.accentLight)),
        ),
    };

    final tilted = widget.kind == ChipKind.record;
    return Semantics(
      button: true,
      label: _semantics,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (_, child) {
          final t = _curve.value;
          // Lands at −3° and settles flat; a foil stays slightly tilted.
          final angle = (tilted ? -3.0 : -3.0 * (1 - t)) * math.pi / 180;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.rotate(angle: angle, child: Transform.scale(scale: 0.9 + 0.1 * t, child: child)),
          );
        },
        child: SizedBox(
          width: stickerWidth,
          height: stickerHeight,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: face,
            ),
          ),
        ),
      ),
    );
  }
}

/// Navy foil: white border and one flat diagonal light-blue sheen band.
class FoilFace extends StatelessWidget {
  const FoilFace({super.key, required this.child, this.border = 3});

  final Widget child;
  final double border;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.sticker);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: radius,
        border: Border.all(color: AppColors.paper, width: border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(painter: const _SheenPainter(), child: child),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  const _SheenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.accentLight.withValues(alpha: 0.35);
    final w = size.width * 0.3;
    final x = size.width * 0.38;
    final skew = size.height * 0.58; // ~30° lean
    final path = Path()
      ..moveTo(x + skew / 2, 0)
      ..lineTo(x + skew / 2 + w, 0)
      ..lineTo(x - skew / 2 + w, size.height)
      ..lineTo(x - skew / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SheenPainter old) => false;
}

/// A small paper or foil sticker for summaries (finish page, history, progress).
class MiniSticker extends StatelessWidget {
  const MiniSticker({super.key, required this.weight, this.record = false, this.width = 38, this.height = 42});

  final double weight;
  final bool record;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final label = formatWeight(weight);
    final size = label.length > 3 ? height * 0.36 : height * 0.42;
    final text = Text(label, style: AppText.sticker.copyWith(fontSize: size, color: record ? AppColors.onAccent : AppColors.paperInk));
    return SizedBox(
      width: record ? math.max(width, height) : width,
      height: height,
      child: record
          ? FoilFace(border: 2, child: Center(child: text))
          : DecoratedBox(
              decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(5)),
              child: Center(child: text),
            ),
    );
  }
}
