/// Small reusable building blocks that match the Figma design.
library;

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Rounded surface used for every card.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderColor, this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!, width: 1.5),
    );
    return Material(
      color: AppColors.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Small rounded label, e.g. "New PR 80", "Next", "Starter".
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.fill, this.color = AppColors.muted, this.outline, this.fontSize = 12});

  final String text;
  final Color? fill;
  final Color color;
  final Color? outline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: outline == null ? null : Border.all(color: outline!),
      ),
      child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

/// Full-width filled button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, required this.onPressed, this.inverted = false});

  final String label;
  final VoidCallback? onPressed;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: inverted ? AppColors.onAccent : AppColors.accent,
          foregroundColor: inverted ? AppColors.accent : AppColors.onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Full-width dashed outline button, e.g. "+ New rota".
class DashedButton extends StatelessWidget {
  const DashedButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      radius: AppRadius.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Center(
            child: Text(label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accentLight)),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded border around [child].
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, this.radius = AppRadius.chip, this.color = AppColors.line});

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: DashedPainter(radius, color), child: child);
}

/// Dashed rounded-rect outline. Used for ghost chips and dashed buttons.
class DashedPainter extends CustomPainter {
  DashedPainter(this.radius, this.color);

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75);
    final path = Path()..addRRect(rect);
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(DashedPainter old) => old.color != color || old.radius != radius;
}

/// Two-or-more option toggle, e.g. rota A | B.
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.selected, required this.onChanged, this.compact = false});

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            Semantics(
              button: true,
              selected: i == selected,
              label: 'Rota ${options[i]}',
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: BoxConstraints(minWidth: compact ? 40 : 48, minHeight: compact ? 32 : 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(options[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: i == selected ? AppColors.onAccent : AppColors.muted,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Muted uppercase-free section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 4, bottom: 8), child: Text(text, style: AppText.label));
}

/// Friendly placeholder for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(children: [
        Text(title, style: AppText.cardTitle, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(body, style: AppText.caption, textAlign: TextAlign.center),
      ]),
    );
  }
}
