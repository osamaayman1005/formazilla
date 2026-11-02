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
  static const _height = 96.0;

  /// Width / height of assets/mascot.png.
  static const _aspect = 375 / 300;

  /// Where his open mouth is in the image, as fractions of width and height.
  /// The bubble's tail points exactly here.
  static const _mouth = Offset(0.66, 0.55);

  static const _tail = Size(30, 18);

  @override
  Widget build(BuildContext context) {
    final mouth = Offset(_height * _aspect * _mouth.dx, _height * _mouth.dy);
    return Semantics(
      label: 'Formazilla says: $message',
      excludeSemantics: true,
      child: SizedBox(
        height: _height,
        child: Stack(clipBehavior: Clip.none, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: Motion.of(context, Motion.base),
            curve: Motion.pop,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Image.asset('assets/mascot.png', height: _height),
          ),
          // Bubble: tail tip sits in his mouth, bubble centred on it vertically.
          Positioned(
            left: mouth.dx,
            right: 0,
            top: mouth.dy - _height / 2,
            height: _height,
            child: Align(
              alignment: Alignment.centerLeft,
              child: EnterFromBelow(
                delay: const Duration(milliseconds: 150),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CustomPaint(size: _tail, painter: _TailPainter(AppColors.card)),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 18, 12),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        if (caption != null) Text(caption!, style: AppText.small),
                        Text(message, style: AppText.title.copyWith(fontSize: 22)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Speech-bubble tail pointing left, into the mascot's mouth.
class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Tip on the left (in his mouth), wide base joining the bubble on the right.
    final path = Path()
      ..moveTo(size.width + 1, 0)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.35, 0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width + 1, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}
