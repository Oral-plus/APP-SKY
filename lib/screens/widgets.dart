import 'package:flutter/widgets.dart';

class SafeFadeTransition extends AnimatedWidget {
  final Widget child;

  const SafeFadeTransition({
    super.key,
    required Animation<double> opacity,
    required this.child,
  }) : super(listenable: opacity);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    final safeOpacity = animation.value.clamp(0.0, 1.0);

    return Opacity(
      opacity: safeOpacity,
      child: child,
    );
  }
}
