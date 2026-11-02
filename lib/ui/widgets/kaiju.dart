/// The two monster touches: claw scratches (PR moments) and a spiked edge
/// (like the mascot's back). Used sparingly, so they read as a signature.
library;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Three claw slashes. [progress] 0→1 draws them on, left to right.
class ClawMark extends StatelessWidget {
  const ClawMark({super.key, this.size = 14, this.color = AppColors.accentLight, this.progress = 1});

  final double size;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 1.15, size), painter: ClawPainter(color: color, progress: progress));
}

class ClawPainter extends CustomPainter {
  ClawPainter({required this.color, this.progress = 1, this.strokeWidth});

  final Color color;
  final double progress;
  final double? strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width, h = size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth ?? (h * 0.14).clamp(1.5, 4.0)
      ..strokeCap = StrokeCap.round;
    // Bottom-left to top-right slashes; the last one is a little shorter.
    final slashes = [
      (Offset(w * 0.08, h * 0.95), Offset(w * 0.36, h * 0.08)),
      (Offset(w * 0.40, h * 0.95), Offset(w * 0.68, h * 0.08)),
      (Offset(w * 0.72, h * 0.95), Offset(w * 0.94, h * 0.28)),
    ];
    for (var i = 0; i < slashes.length; i++) {
      // Each slash draws during its own third of the progress.
      final local = ((progress * 3) - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final (a, b) = slashes[i];
      canvas.drawLine(a, Offset.lerp(a, b, local)!, paint);
    }
  }

  @override
  bool shouldRepaint(ClawPainter old) => old.progress != progress || old.color != color;
}

/// A strip of dorsal spikes along the top of a surface (e.g. the bottom bar).
class SpikeEdge extends StatelessWidget {
  const SpikeEdge({super.key, this.color = AppColors.card, this.height = 12});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SpikePainter(color)),
      );
}

class _SpikePainter extends CustomPainter {
  _SpikePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spike = 28.0;
    final count = (size.width / spike).ceil();
    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i < count; i++) {
      final x = i * spike;
      // Alternate tall and short spikes, like the mascot's back.
      final peak = i.isEven ? 0.0 : size.height * 0.45;
      path
        ..lineTo(x + spike * 0.5, peak)
        ..lineTo(x + spike, size.height);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SpikePainter old) => old.color != color;
}
