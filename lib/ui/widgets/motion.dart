import 'package:flutter/widgets.dart';

/// Animation timings in one place. Every animation goes through [Motion.of],
/// so the phone's "Remove animations" setting turns them all off.
class Motion {
  Motion._();

  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
  static const glow = Duration(milliseconds: 900);

  /// Springy ease with a small overshoot, for things that "pop".
  static const Curve pop = Cubic(0.3, 1.6, 0.5, 1.0);

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// Fades and slides its child in once, after [delay]. For staggered lists.
class EnterFromBelow extends StatelessWidget {
  const EnterFromBelow({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = Motion.of(context, Motion.base + delay);
    if (total == Duration.zero) return child;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}
