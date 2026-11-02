import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'motion.dart';

/// The Formazilla mascot "saying" a line in a speech bubble.
/// The head pops in, then the bubble slides up.
class MascotSays extends StatelessWidget {
  const MascotSays({super.key, required this.message, this.caption});

  final String message;

  /// Small line above the message, e.g. the date.
  final String? caption;

  /// Height of the mascot next to the bubble.
  static const _height = 84.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Formazilla says: $message',
      excludeSemantics: true,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: Motion.of(context, Motion.base),
          curve: Motion.pop,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Image.asset('assets/mascot.png', height: _height),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: EnterFromBelow(
            delay: const Duration(milliseconds: 150),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomPaint(size: const Size(10, 14), painter: _TailPainter(AppColors.card)),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 18, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    if (caption != null) Text(caption!, style: AppText.small),
                    Text(message, style: AppText.title.copyWith(fontSize: 22)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Small triangle pointing from the bubble to the mascot.
class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.75, 0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
