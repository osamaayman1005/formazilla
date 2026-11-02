/// The two monster touches: claw scratches (PR moments) and a small spike
/// crest (marks the active tab, like the mascot's back). Used sparingly, so
/// they read as a signature.
library;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Three curved, tapered claw scratches. [progress] 0→1 reveals them,
/// bottom to top, one after another.
class ClawMark extends StatelessWidget {
  const ClawMark({super.key, this.size = 14, this.color = AppColors.accentLight, this.progress = 1});

  final double size;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 16 / 14, size), painter: ClawPainter(color: color, progress: progress));
}

class ClawPainter extends CustomPainter {
  ClawPainter({required this.color, this.progress = 1});

  final Color color;
  final double progress;

  /// Scratch shapes in a 16×14 box (same as the Figma design).
  static Path _slash(double x0, double y0, double cx, double cy, double x1, double y1, double cx2, double cy2,
          double x2, double y2) =>
      Path()
        ..moveTo(x0, y0)
        ..quadraticBezierTo(cx, cy, x1, y1)
        ..quadraticBezierTo(cx2, cy2, x2, y2)
        ..close();

  static final _slashes = [
    _slash(1.4, 13.2, 3.1, 7, 6.4, 0.8, 4.7, 7.3, 3.3, 13.2),
    _slash(6, 13.6, 7.8, 7.1, 11.2, 0.6, 9.5, 7.5, 7.9, 13.6),
    _slash(10.7, 13.2, 12.3, 8.1, 14.9, 3.4, 13.6, 8.6, 12.5, 13.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    canvas.save();
    canvas.scale(size.width / 16, size.height / 14);
    final paint = Paint()..color = color;
    for (var i = 0; i < _slashes.length; i++) {
      // Each scratch reveals during its own third of the progress.
      final local = ((progress * 3) - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 14 * (1 - local), 16, 14));
      canvas.drawPath(_slashes[i], paint);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ClawPainter old) => old.progress != progress || old.color != color;
}

/// A tiny crest of three spikes, shown above the active bottom-bar tab.
class SpikeCrest extends StatelessWidget {
  const SpikeCrest({super.key, this.color = AppColors.accentLight, this.width = 22});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(width, width * 9 / 22), painter: _CrestPainter(color));
}

class _CrestPainter extends CustomPainter {
  _CrestPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 22, size.height / 9);
    // Same shape as the Figma "Spike indicator": small, tall, small.
    final path = Path()
      ..moveTo(1, 9)
      ..quadraticBezierTo(4, 3.5, 5.5, 2)
      ..quadraticBezierTo(6.6, 5, 7.5, 9)
      ..close()
      ..moveTo(7.5, 9)
      ..quadraticBezierTo(10, 1.5, 11.5, 0)
      ..quadraticBezierTo(12.8, 4, 14, 9)
      ..close()
      ..moveTo(14, 9)
      ..quadraticBezierTo(16.4, 4, 17.8, 2.6)
      ..quadraticBezierTo(19, 5.5, 21, 9)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CrestPainter old) => old.color != color;
}
